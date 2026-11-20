#!/usr/bin/env python3
"""Builds GymTracker/Resources/Localizable.xcstrings from the Flutter .arb files.

Keys stay the same as the Flutter app. ICU placeholders become positional
%n$@ arguments in the order they appear in the English string. ICU plurals
become one string per combination: the all-other form keeps the original key,
and any form that uses a singular branch is stored as key#one.other…

Strings only the Swift app needs live in swift_only_strings.json.
"""
import itertools
import json
import pathlib
import re

here = pathlib.Path(__file__).resolve().parent
swift = here.parent
arb_dir = swift.parent / "flutter" / "lib" / "l10n"
out = swift / "GymTracker" / "Resources" / "Localizable.xcstrings"
placeholder = re.compile(r"\{(\w+)\}")
plural_start = re.compile(r"\{(\w+),\s*plural,")


def matching_brace(text, open_at):
    depth = 0
    for i in range(open_at, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError(f"unbalanced braces in {text!r}")


def parse_cases(body):
    cases = {}
    i = 0
    while i < len(body):
        while i < len(body) and body[i].isspace():
            i += 1
        if i >= len(body):
            break
        brace = body.find("{", i)
        selector = body[i:brace].strip()
        end = matching_brace(body, brace)
        cases[selector] = body[brace + 1:end]
        i = end + 1
    return cases


def find_plurals(text):
    found = []
    i = 0
    while True:
        match = plural_start.search(text, i)
        if not match:
            break
        end = matching_brace(text, match.start()) + 1
        body = text[match.end():end - 1]
        found.append((match.start(), end, match.group(1), parse_cases(body)))
        i = end
    return found


def add_name(names, name):
    if name not in names:
        names.append(name)


def collect_names(text):
    names = []
    plurals = find_plurals(text)
    index = 0
    i = 0
    while i < len(text):
        if index < len(plurals) and i == plurals[index][0]:
            add_name(names, plurals[index][2])
            i = plurals[index][1]
            index += 1
            continue
        match = placeholder.match(text, i)
        if match:
            add_name(names, match.group(1))
            i = match.end()
            continue
        i += 1
    return names


def singular_selector(cases):
    if "=1" in cases:
        return "=1"
    if "one" in cases:
        return "one"
    return None


def apply_form(text, choices, names):
    plurals = find_plurals(text)
    parts = []
    cursor = 0
    for start, end, name, cases in plurals:
        parts.append(text[cursor:start])
        selector = choices.get(name, "other")
        parts.append(cases.get(selector) or cases.get("other") or cases.get("=1") or "")
        cursor = end
    parts.append(text[cursor:])
    merged = "".join(parts).replace("%", "%%")

    def sub(match):
        return f"%{names.index(match.group(1)) + 1}$@"

    return placeholder.sub(sub, merged)


def forms(en):
    plurals = find_plurals(en)
    names = collect_names(en)
    if not plurals:
        return {None: apply_form(en, {}, names)}
    axes = []
    for _, _, name, cases in plurals:
        singular = singular_selector(cases)
        axes.append([(name, "other")] if singular is None else [(name, singular), (name, "other")])
    out = {}
    for combo in itertools.product(*axes):
        choices = dict(combo)
        tags = ["one" if selector in ("=1", "one") else "other" for _, selector in combo]
        key = None if all(tag == "other" for tag in tags) else "#".join(["", *tags])[1:]
        # key None means the base string. Otherwise "one" or "one.other".
        suffix = None if all(tag == "other" for tag in tags) else ".".join(tags)
        out[suffix] = apply_form(en, choices, names)
    return out


langs = {
    "en": json.loads((arb_dir / "app_en.arb").read_text()),
    "es": json.loads((arb_dir / "app_es.arb").read_text()),
}
extra = json.loads((here / "swift_only_strings.json").read_text())
strings = {}

for key, en in langs["en"].items():
    if key.startswith("@") or not isinstance(en, str):
        continue
    en_forms = forms(en)
    es = langs["es"].get(key, en)
    es_forms = forms(es) if isinstance(es, str) else {}
    for suffix, value in en_forms.items():
        catalog_key = key if suffix is None else f"{key}#{suffix}"
        entry = {"extractionState": "manual", "localizations": {}}
        entry["localizations"]["en"] = {"stringUnit": {"state": "translated", "value": value}}
        entry["localizations"]["es"] = {
            "stringUnit": {"state": "translated", "value": es_forms.get(suffix, value)}
        }
        strings[catalog_key] = entry

for key, values in extra.items():
    strings[key] = {
        "extractionState": "manual",
        "localizations": {
            lang: {"stringUnit": {"state": "translated", "value": text}} for lang, text in values.items()
        },
    }

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(
    json.dumps({"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"},
               ensure_ascii=False, indent=2) + "\n"
)
print(f"wrote {len(strings)} strings")
