#!/usr/bin/env python3
"""Writes the Keenicons of a Metronic checkout as one SVG per icon, for assets/css/keenicons.cjs.

    python3 scripts/keenicons.py <metronic>/src/vendors/keenicons [assets/keenicons]

The icons come with Metronic and are covered by its license, so the output folder is not committed.
"""
import html
import os
import re
import sys

src = sys.argv[1]
dest = sys.argv[2] if len(sys.argv) > 2 else "assets/keenicons"

for style in ("filled", "outline", "solid"):
    font = open(f"{src}/{style}/fonts/keenicons-{style}.svg").read()
    by_char = {}
    for match in re.finditer(r"<glyph\b([^>]*?)/>", font, re.S):
        attrs = match.group(1)
        char = re.search(r'unicode="([^"]+)"', attrs)
        path = re.search(r'\sd="([^"]+)"', attrs)
        if char and path:
            by_char[html.unescape(char.group(1))] = path.group(1)
    css = open(f"{src}/{style}/style.css").read()
    os.makedirs(f"{dest}/{style}", exist_ok=True)
    pattern = r"\.ki-([a-z0-9-]+)\.ki-" + style + r':before\s*\{\s*content:\s*"\\([0-9a-f]+)"'
    count = 0
    for match in re.finditer(pattern, css):
        char = chr(int(match.group(2), 16))
        if char in by_char:
            svg = (
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 1024 1024">'
                f'<g transform="scale(1,-1)"><path d="{by_char[char]}"/></g></svg>'
            )
            open(f"{dest}/{style}/{match.group(1)}.svg", "w").write(svg)
            count += 1
    print(style, count)
