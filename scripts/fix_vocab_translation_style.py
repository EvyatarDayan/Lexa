#!/usr/bin/env python3
"""
Pass 3: English display style for entries where translation still matches the Swedish headword
(true cognates). Does not call external APIs.

- Default: use lowercase English gloss (dictionary-style subtitle under the Swedish headword).
- Exceptions: months, some places, religions, demonyms, ideology names, acronyms, a few given names.
- Skips: Egennamn, garbled phrases like 'Bproper name'.
"""

import json
import re
from pathlib import Path
from typing import List, Optional, Set

from fix_vocab_translations import (  # type: ignore
    norm,
    fix_grammar_line,
    replace_swedish_in_english,
)

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "vocabulary.json"

# English styling for short tokens that are usually written in all caps
ACRONYMS = {
    "aids": "AIDS",
    "hiv": "HIV",
    "cd": "CD",
    "dvd": "DVD",
    "pc": "PC",
    "sms": "SMS",
}

# Title-case in English (months, places, religions, common demonyms, etc.)
PROPER_STYLE: Set[str] = {
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "november",
    "december",
    "england",
    "islam",
    "islamist",
    "arab",
    "muslim",
    "kurd",
    "turk",
    "indian",
    "taliban",
    "nobel",
    "marxism",
    "marxist",
    "nazism",
    "olympiad",
    "latin",
}

# Scandinavian given names spelled the same in English — keep traditional casing
NAMES_NO_CHANGE: Set[str] = {"per", "inge"}

BROKEN_SUBSTR = ("proper name", "bproper")


def grammar_tokens(grammar_type: Optional[str]) -> List[str]:
    if not isinstance(grammar_type, str) or not grammar_type.strip():
        return []
    return [p.strip() for p in grammar_type.split("/") if p.strip()]


def should_skip_entry(word: str, grammar_type: Optional[str]) -> bool:
    n = norm(word)
    if not n:
        return True
    for s in BROKEN_SUBSTR:
        if s in n:
            return True
    tokens = grammar_tokens(grammar_type)
    for t in tokens:
        if "egennamn" in t.lower():
            return True
    return False


def style_gloss(word: str, translation: str, grammar_type: Optional[str]) -> Optional[str]:
    if not isinstance(word, str) or not isinstance(translation, str):
        return None
    if norm(word) != norm(translation):
        return None
    if should_skip_entry(word, grammar_type):
        return None

    n = norm(word)

    if n in ACRONYMS:
        return ACRONYMS[n]

    if n in NAMES_NO_CHANGE:
        return None

    if n in PROPER_STYLE:
        return n.capitalize()

    # Default: lowercase English cognate
    return n


def main() -> None:
    data = json.loads(VOCAB.read_text(encoding="utf-8"))
    updated = 0

    for e in data:
        w = e.get("word")
        t = e.get("translation")
        if not isinstance(w, str) or not isinstance(t, str):
            continue

        g = style_gloss(w, t, e.get("grammar_type") if isinstance(e.get("grammar_type"), str) else None)
        if not g or g == t:
            continue

        e["translation"] = g
        updated += 1

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

    # Multi-word glosses from pass 2: use dictionary-style lowercase
    phrase_lowers = {
        ("tag", "while"): ("while", r"\bWhile\b"),
        ("hamna", "end up"): ("end up", r"\bEnd up\b"),
    }

    def scrub_old_title_case(text: str, lower_gloss: str, title_pattern: str) -> str:
        text = re.sub(title_pattern, lower_gloss, text)
        return text

    for e in data:
        w = e.get("word")
        t = e.get("translation")
        if not isinstance(w, str) or not isinstance(t, str):
            continue
        hit = phrase_lowers.get((norm(w), norm(t)))
        if not hit:
            continue
        g, title_pat = hit
        if t != g:
            e["translation"] = g
            updated += 1
        gb = e.get("grammar_breakdown")
        if isinstance(gb, list):
            new_gb = []
            for line in gb:
                if isinstance(line, str) and ":" in line:
                    a, b = line.split(":", 1)
                    b = scrub_old_title_case(b.strip(), g, title_pat)
                    line = fix_grammar_line(f"{a}:{b}", w, g)
                elif isinstance(line, str):
                    line = scrub_old_title_case(line, g, title_pat)
                new_gb.append(line)
            e["grammar_breakdown"] = new_gb
        rows = e.get("data")
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict) and isinstance(row.get("english"), str):
                    eng = scrub_old_title_case(row["english"], g, title_pat)
                    row["english"] = replace_swedish_in_english(eng, w, g)

    # Dictionary-style: English gloss for "film" is usually lowercase "movie"
    for e in data:
        w = e.get("word")
        t = e.get("translation")
        if not isinstance(w, str) or not isinstance(t, str):
            continue
        if norm(w) != "film" or norm(t) != "movie":
            continue
        g = "movie"
        if t != g:
            e["translation"] = g
            updated += 1
        gb = e.get("grammar_breakdown")
        if isinstance(gb, list):
            new_gb = []
            for line in gb:
                if isinstance(line, str) and ":" in line:
                    a, b = line.split(":", 1)
                    b = re.sub(r"\bMovie\b", "movie", b)
                    line = a + ":" + b
                new_gb.append(line)
            e["grammar_breakdown"] = new_gb
        rows = e.get("data")
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict) and isinstance(row.get("english"), str):
                    eng = replace_swedish_in_english(row["english"], w, g)
                    row["english"] = re.sub(r"\bMovie\b", "movie", eng)

    VOCAB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("style_updated_entries", updated, "wrote", VOCAB)


if __name__ == "__main__":
    main()
