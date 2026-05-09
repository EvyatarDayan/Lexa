#!/usr/bin/env python3
"""
Second pass: fix entries where English translation still matches the Swedish headword
after MT (cognates, proper-noun MT failures, heteronyms).

Rules (conservative):
- Parse grammar_type tokens by '/'.
- Pure verb (has verb token, no substantiv): use Google(sv->en) on "att {lemma}" and strip a leading "to ".
- Substantiv (or mixed with verb): use "ett {lemma}" / "en {lemma}" patterns; strip common article/prefix
  and prefer the article form that yields a meaning distinct from the lemma when one side collapses to the lemma.
- Otherwise leave translation unchanged (true cognates / prepositions like "in").
"""

import json
import time
import random
from pathlib import Path
from typing import List, Optional

try:
    from deep_translator import GoogleTranslator
except ImportError as e:
    raise SystemExit(f"pip install deep-translator  ({e})")

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "vocabulary.json"

# Local imports from sibling script
from fix_vocab_translations import (  # type: ignore
    needs_translation_fix,
    fix_grammar_line,
    replace_swedish_in_english,
    norm,
)


def grammar_tokens(grammar_type: Optional[str]) -> List[str]:
    if not isinstance(grammar_type, str) or not grammar_type.strip():
        return []
    return [p.strip() for p in grammar_type.split("/") if p.strip()]


def has_substantiv(tokens: List[str]) -> bool:
    return any("substantiv" in t.lower() for t in tokens)


def has_non_adverb_verb(tokens: list[str]) -> bool:
    for t in tokens:
        tl = t.lower()
        if tl.startswith("adverb"):
            continue
        if tl.startswith("verb") or tl.startswith("hjälpverb"):
            return True
    return False


def strip_article_phrase(s: str) -> str:
    x = s.strip().lower()
    for p in ("for a ", "for an ", "the ", "a ", "an ", "one "):
        if x.startswith(p):
            x = x[len(p) :].strip()
            break
    return x.strip()


def translate_safe(translator: GoogleTranslator, text: str) -> str:
    for i in range(6):
        try:
            out = translator.translate(text)
            if isinstance(out, str) and out.strip():
                return out.strip()
        except Exception:
            time.sleep(min(8.0, (1.25**i) * (0.25 + random.random() * 0.25)))
    return text


def verb_gloss(translator: GoogleTranslator, lemma: str) -> str:
    raw = translate_safe(translator, f"att {lemma}")
    low = raw.lower().strip()
    if low.startswith("to "):
        raw = raw[3:].strip()
    return raw


def noun_gloss_from_articles(translator: GoogleTranslator, lemma: str) -> Optional[str]:
    ett_raw = translate_safe(translator, f"ett {lemma}").strip()
    en_raw = translate_safe(translator, f"en {lemma}").strip()
    ett_c = strip_article_phrase(ett_raw)
    en_c = strip_article_phrase(en_raw)
    L = lemma.lower()

    if ett_c == L and en_c != L:
        return en_c
    if en_c == L and ett_c != L:
        return ett_c
    if ett_c != L and en_c != L and ett_c == en_c:
        return ett_c
    if ett_c != L:
        return ett_c
    if en_c != L:
        return en_c
    return None


def match_title_case(gloss: str, original_word: str) -> str:
    if not gloss:
        return gloss
    if original_word.isupper() and len(original_word) <= 5 and original_word.isalpha():
        return gloss.upper()
    if original_word[:1].isupper():
        return gloss[0].upper() + gloss[1:] if len(gloss) > 1 else gloss.upper()
    return gloss


def smart_gloss(translator: GoogleTranslator, word: str, grammar_type: Optional[str]) -> Optional[str]:
    tokens = grammar_tokens(grammar_type)
    lemma = word.strip().lower()

    sub = has_substantiv(tokens)
    vrb = has_non_adverb_verb(tokens)

    if vrb and not sub:
        g = verb_gloss(translator, lemma)
        if not g or norm(g) == norm(word):
            return None
        return match_title_case(g, word)

    if sub:
        ng = noun_gloss_from_articles(translator, lemma)
        if ng and norm(ng) != norm(word):
            return match_title_case(ng, word)
        return None

    return None


def main() -> None:
    data = json.loads(VOCAB.read_text(encoding="utf-8"))
    translator = GoogleTranslator(source="sv", target="en")

    fixed = 0
    for e in data:
        w = e.get("word")
        t = e.get("translation") if isinstance(e.get("translation"), str) else ""
        if not isinstance(w, str) or not w.strip():
            continue
        if not needs_translation_fix(w, t):
            continue

        g = smart_gloss(translator, w, e.get("grammar_type") if isinstance(e.get("grammar_type"), str) else None)
        if not g:
            continue

        e["translation"] = g
        fixed += 1

        gb = e.get("grammar_breakdown")
        if isinstance(gb, list):
            e["grammar_breakdown"] = [
                fix_grammar_line(line, w, g) if isinstance(line, str) else line for line in gb
            ]
        rows = e.get("data")
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict) and isinstance(row.get("english"), str):
                    row["english"] = replace_swedish_in_english(row["english"], w, g)

        time.sleep(0.12 + random.random() * 0.12)

        if fixed % 50 == 0:
            print(f"fixed_so_far {fixed}", flush=True)

        if fixed % 100 == 0:
            VOCAB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"checkpoint wrote fixed={fixed}", flush=True)

    VOCAB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("pass2_fixed", fixed, "wrote", VOCAB)


if __name__ == "__main__":
    main()
