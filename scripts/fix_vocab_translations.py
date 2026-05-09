#!/usr/bin/env python3
"""
Fix vocabulary.json entries where translation equals the Swedish headword (or is empty).

Uses Swedish -> English lookups (deep_translator / Google MT), merges with an on-disk cache
 `.translation_fix_cache.json` so interrupted runs resume quickly.

Updates `translation`, optionally fixes `grammar_breakdown` RHS and example `english` strings
when the Swedish headword leaked into English text.
"""

import json
import re
import sys
import time
import random
from pathlib import Path
from typing import Optional

try:
    from deep_translator import GoogleTranslator
except ImportError as e:
    raise SystemExit(f"pip install deep-translator  ({e})")

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "vocabulary.json"
BACKUP = ROOT / "vocabulary_backup_before_translation_unify.json"
CACHE = ROOT / ".translation_fix_cache.json"


def norm(s: str) -> str:
    return " ".join((s or "").strip().lower().split())


def needs_translation_fix(word: str, translation: str) -> bool:
    if not isinstance(word, str) or not word.strip():
        return False
    if not isinstance(translation, str) or not translation.strip():
        return True
    return norm(word) == norm(translation)


def primary_gloss(translation: str) -> str:
    t = (translation or "").strip()
    if not t:
        return t
    if "/" in t:
        t = t.split("/")[0].strip()
    return t


def replace_swedish_in_english(text: str, sw_word: str, en_gloss: str) -> str:
    if not isinstance(text, str) or not text:
        return text
    gloss = primary_gloss(en_gloss)
    if not gloss:
        return text
    return re.sub(re.escape(sw_word), gloss, text, flags=re.IGNORECASE)


def fix_grammar_line(line: str, sw_word: str, en_translation: str) -> str:
    if not isinstance(line, str) or ":" not in line:
        return line
    left, right = line.split(":", 1)
    new_right = replace_swedish_in_english(right.strip(), sw_word, en_translation)
    return f"{left}:{new_right}"


def load_cache() -> dict[str, str]:
    if not CACHE.exists():
        return {}
    try:
        raw = json.loads(CACHE.read_text(encoding="utf-8"))
    except Exception:
        return {}
    out: dict[str, str] = {}
    for k, v in raw.items():
        if isinstance(k, str) and isinstance(v, str) and v.strip():
            out[k] = v.strip()
    return out


def save_cache(cache: dict[str, str]) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, sort_keys=True, indent=0) + "\n", encoding="utf-8")


def translate_with_translator(translator: GoogleTranslator, word: str) -> str:
    last_err: Optional[Exception] = None
    for i in range(16):
        try:
            t = translator.translate(word)
            if isinstance(t, str) and t.strip():
                return t.strip()
        except Exception as e:
            last_err = e
            # Back off on rate limits / transient errors
            delay = min(90.0, (1.4**i) * (0.25 + random.random() * 0.25))
            time.sleep(delay)
    if last_err is not None:
        print(f"WARN: translate failed for {word!r}: {last_err}", file=sys.stderr)
    return word


def translate_batch_safe(translator: GoogleTranslator, words: list[str]) -> dict[str, str]:
    """
    Try one batch call; on any failure, fall back to per-word translation.
    """
    if not words:
        return {}
    try:
        out = translator.translate_batch(words)
        if isinstance(out, list) and len(out) == len(words):
            return {w: (t or "").strip() or w for w, t in zip(words, out)}
    except Exception:
        pass

    m: dict[str, str] = {}
    for w in words:
        m[w] = translate_with_translator(translator, w)
        time.sleep(0.12 + random.random() * 0.12)
    return m


def main() -> None:
    if not VOCAB.exists():
        raise SystemExit(f"Missing {VOCAB}")

    if not BACKUP.exists():
        BACKUP.write_text(VOCAB.read_text(encoding="utf-8"), encoding="utf-8")
        print("Wrote backup:", BACKUP)

    print("Loading vocabulary.json (large)…", flush=True)
    data = json.loads(VOCAB.read_text(encoding="utf-8"))

    to_translate: list[str] = []
    for e in data:
        w = e.get("word")
        t = e.get("translation")
        if isinstance(w, str) and needs_translation_fix(w, t if isinstance(t, str) else ""):
            to_translate.append(w.strip())

    seen: set[str] = set()
    unique: list[str] = []
    for w in to_translate:
        if w not in seen:
            seen.add(w)
            unique.append(w)

    print("entries_total", len(data), flush=True)
    print("unique_words_to_translate", len(unique), flush=True)

    cache = load_cache()
    missing = [w for w in unique if w not in cache]
    print("cache_hits", len(unique) - len(missing), "missing", len(missing), flush=True)

    translator = GoogleTranslator(source="sv", target="en")

    batch_size = 8
    for start in range(0, len(missing), batch_size):
        chunk = missing[start : start + batch_size]
        got = translate_batch_safe(translator, chunk)
        cache.update(got)
        save_cache(cache)

        done = min(start + batch_size, len(missing))
        if done % 200 == 0 or done == len(missing):
            print(f"translated_missing {done}/{len(missing)}", flush=True)

        # Gentle pacing between batches to reduce 429s
        time.sleep(0.18 + random.random() * 0.18)

    fixed_entries = 0
    for e in data:
        w = e.get("word")
        if not isinstance(w, str) or not w.strip():
            continue
        t = e.get("translation") if isinstance(e.get("translation"), str) else ""
        if not needs_translation_fix(w, t):
            continue

        nw = cache.get(w.strip(), w.strip())
        if not nw.strip():
            nw = w.strip()
        e["translation"] = nw
        fixed_entries += 1

        gb = e.get("grammar_breakdown")
        if isinstance(gb, list):
            e["grammar_breakdown"] = [
                fix_grammar_line(line, w, nw) if isinstance(line, str) else line for line in gb
            ]

        rows = e.get("data")
        if isinstance(rows, list):
            for row in rows:
                if not isinstance(row, dict):
                    continue
                eng = row.get("english")
                if isinstance(eng, str):
                    row["english"] = replace_swedish_in_english(eng, w, nw)

    print("Writing vocabulary.json…", flush=True)
    VOCAB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("fixed_entries", fixed_entries)
    print("wrote", VOCAB)


if __name__ == "__main__":
    main()
