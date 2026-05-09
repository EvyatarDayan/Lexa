#!/usr/bin/env python3
"""
Regenerate example sentences for vocabulary entries using POS-aware Swedish frames
and Google Translate (sv -> en) for natural English.

Usage:
  python3 scripts/regenerate_vocab_examples.py [--start 0] [--count 1000] [--dry-run]

Only modifies `data` (and optionally skips entries). Back up vocabulary.json first.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import time
from pathlib import Path
from typing import List, Optional, Set

try:
    from deep_translator import GoogleTranslator
except ImportError:
    print("pip install deep-translator", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "vocabulary.json"

# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------


def lw(word: str) -> str:
    if not word:
        return word
    return word[0].lower() + word[1:]


def cap1(word: str) -> str:
    if not word:
        return word
    return word[0].upper() + word[1:].lower()


ATTR_ONLY_ADJECTIVES: Set[str] = {
    "bakre",
    "främre",
    "övre",
    "nedre",
    "yttre",
    "inre",
    "västra",
    "östra",
    "norra",
    "södra",
    "mellersta",
}


def special_sw_sentences(word: str, grammar_type: str) -> Optional[List[str]]:
    """Hand-crafted Swedish examples for lemmas that break generic adjective/number frames."""
    g = (grammar_type or "").lower()
    x = lw(word)

    if x == "ett" and "artikel" in g:
        return [
            "Det finns ett problem vi måste prata om.",
            "Hon har ett barn som går i skolan.",
            "Kan du ge mig ett ögonblick till?",
        ]
    if x == "en" and "artikel" in g:
        return [
            "Det var en lång och jobbig dag.",
            "Hon bor i en liten lägenhet vid parken.",
            "Jag behöver en paus innan vi fortsätter.",
        ]
    if x == "andra" and "adjektiv" in g:
        return [
            "Hon bryr sig mycket om andra människor.",
            "Det här är min andra resa till Stockholm.",
            "Flera andra förslag diskuterades på mötet.",
        ]
    if x in ATTR_ONLY_ADJECTIVES and "adjektiv" in g:
        return [
            f"I den {x} delen av huset var det svalt och tyst.",
            f"Vi möttes vid den {x} ingången till byggnaden.",
            f"Publiken på den {x} raden kunde knappt se scenen.",
        ]
    return None


def classify_pos(grammar_type: str) -> str:
    g = (grammar_type or "").lower()
    if "egennamn" in g:
        return "name"
    if "fras" in g:
        return "phrase"
    if "interjektion" in g:
        return "interj"
    if "modalpartikel" in g:
        return "adv"
    if "ordningstal" in g:
        if "adjektiv" in g:
            return "adj"
        return "ordinal"
    if "räkneord" in g:
        return "number"
    if g.strip() == "ord":
        return "pron"
    if "pronomen" in g:
        return "pron"
    if "konjunktion" in g and "preposition" not in g and "adverb" not in g:
        return "conj"
    if "preposition" in g or (g.startswith("adverb") and "preposition" in g):
        return "prep"
    if "adverb" in g:
        return "adv"
    if "verb" in g:
        return "verb"
    if "adjektiv" in g:
        return "adj"
    if "substantiv" in g:
        return "noun"
    return "noun"


def frame_vars(word: str, grammar_type: str) -> dict:
    return {
        "w": word,
        "lw": lw(word),
        "cap": cap1(word),
    }


# Swedish frames: must use {lw}, {cap}, or {w} (phrase / name) as appropriate.
FRAMES: dict[str, List[str]] = {
    "verb": [
        "Jag försöker att {lw} varje dag utan att stressa.",
        "Det är svårt att {lw} när man är trött och hungrig.",
        "Hon har lärt sig att {lw} ganska bra nu.",
    ],
    "noun": [
        "Vi pratade om {lw} i nästan en hel timme.",
        "{cap} spelar en större roll än många tror.",
        "Hon hade aldrig hört talas om {lw} förut.",
    ],
    "name": [
        "{w} ligger nära många andra intressanta platser.",
        "Många turister besöker {w} varje år.",
        "Hon flyttade till {w} för tio år sedan.",
    ],
    "adj": [
        "Rummet kändes plötsligt väldigt {lw}.",
        "Det var en {lw} upplevelse som hon minns länge.",
        "Huset ser {lw} ut nu när det är renoverat.",
    ],
    "adv": [
        "Hon sprang {lw} mot målet.",
        "De arbetade {lw} hela eftermiddagen.",
        "Barnen lekte {lw} i trädgården.",
    ],
    "prep": [
        "Frågan handlar {lw} budgeten för nästa år.",
        "Hon lade märke {lw} små skillnader i texten.",
        "Vi reste dit {lw} tåg och sedan med buss.",
    ],
    "pron": [
        "{cap} kom lite senare än väntat.",
        "Jag såg {lw} på stan igår.",
        "Berätta mer om {lw}, tycker jag.",
    ],
    "number": [
        "Hon är {lw} år gammal i år.",
        "Det kostade {lw} kronor styck.",
        "Gruppen bestod av {lw} personer som alla kände varandra.",
    ],
    "ordinal": [
        "Det här är min {lw} resa till Sverige.",
        "Han kom på {lw} plats i den lokala tävlingen.",
        "Vi ses den {lw} maj, om allt går som planerat.",
    ],
    "conj": [
        "Jag ville följa med, {lw} jag var för sjuk.",
        "Det regnade, {lw} vi gick ändå ut.",
        "Hon var trött, {lw} hon log ändå.",
    ],
    "phrase": [
        "Hon sa {w} innan hon avslutade samtalet.",
        "{w} — det uttrycket använder man ofta i vardagen.",
        "Jag skrev ner {w} så jag inte skulle glömma.",
    ],
    "interj": [
        "{cap}! utbrast hon när hon såg resultatet.",
        "— {cap}, vad händer? frågade han oroligt.",
        "{cap}, jag hade nästan glömt det.",
    ],
}


def pick_frames(category: str, entry_id: int) -> List[str]:
    pool = FRAMES.get(category) or FRAMES["noun"]
    rng = random.Random(entry_id * 10007 + 42)
    idxs = list(range(len(pool)))
    rng.shuffle(idxs)
    return [pool[i] for i in idxs[:3]]


def build_sw_sentences(word: str, grammar_type: str, entry_id: int) -> List[str]:
    spec = special_sw_sentences(word, grammar_type)
    if spec:
        return spec

    cat = classify_pos(grammar_type)
    if cat == "pron":
        v = frame_vars(word, grammar_type)
        object_forms = frozenset({"mig", "dig", "oss", "er", "honom", "henne", "dem"})
        if lw(word) in object_forms:
            pool = [
                "Hon skickade ett sms till {lw} i morse.",
                "Kan du se {lw} där borta vid ingången?",
                "Vi väntade på {lw} i nästan en halvtimme.",
            ]
        else:
            pool = [
                "{cap} kom lite för sent till mötet.",
                "{cap} har jobbat här sedan i våras.",
                "Varför skrattade {lw} plötsligt så högt?",
            ]
        rng = random.Random(entry_id * 10007 + 42)
        idxs = list(range(len(pool)))
        rng.shuffle(idxs)
        return [pool[i].format(**v) for i in idxs[:3]]

    if cat == "name":
        v = frame_vars(word, grammar_type)
        # Names keep dictionary spelling
        v["w"] = word
        return [f.format(**v) for f in pick_frames("name", entry_id)]
    if cat == "phrase":
        v = {"w": word, "lw": word, "cap": word[0].upper() + word[1:] if word else word}
        return [f.format(**v) for f in pick_frames("phrase", entry_id)]
    v = frame_vars(word, grammar_type)
    return [f.format(**v) for f in pick_frames(cat, entry_id)]


def translate_safe(translator: GoogleTranslator, text: str, retries: int = 5) -> str:
    for i in range(retries):
        try:
            out = translator.translate(text)
            if isinstance(out, str) and out.strip():
                return out.strip()
        except Exception:
            time.sleep(0.6 * (i + 1))
    return text


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--count", type=int, default=1000)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    data = json.loads(VOCAB.read_text(encoding="utf-8"))
    end = min(args.start + args.count, len(data))
    slice_entries = data[args.start : end]

    translator = GoogleTranslator(source="sv", target="en")
    updated = 0

    for offset, entry in enumerate(slice_entries):
        idx = args.start + offset
        eid = entry.get("id", idx)
        word = entry.get("word") or ""
        gt = entry.get("grammar_type") or ""
        if not word.strip():
            continue

        sents = build_sw_sentences(word, gt, int(eid) if isinstance(eid, int) else idx)
        new_data = []
        for sv in sents:
            en = translate_safe(translator, sv)
            new_data.append({"swedish": sv, "english": en})
            time.sleep(0.08 + random.random() * 0.06)

        entry["data"] = new_data
        updated += 1

        if updated % 50 == 0:
            print(f"progress {updated}/{len(slice_entries)} (index {idx})", flush=True)

    if args.dry_run:
        print("dry-run: not writing", updated, "entries")
        return

    VOCAB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("wrote", VOCAB, "regenerated examples for", updated, "entries", f"indices [{args.start}, {end})")


if __name__ == "__main__":
    main()
