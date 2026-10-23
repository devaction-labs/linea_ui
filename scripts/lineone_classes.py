"""Prints the classes of a LineOne demo page, grouped by its <h2> sections.

  python3 scripts/lineone_classes.py elements-button [class-prefix]

Only the live demo is read: the <code> snippets and the page shell (sidebar, header) are skipped.
"""
import re
import sys

ROOT = "/home/alex/Documents/Singnetum/themeforest-CN8rjpHg-lineone-multipurpose-admin-and-webapp-ui-kit-based-on-tailwind-css/lineone-html-es6/src/html/"

page = sys.argv[1].removesuffix(".html")
prefix = sys.argv[2] if len(sys.argv) > 2 else ""
html = open(ROOT + page + ".html").read()
main = html[html.index("<main"):]
parts = re.split(r"<h2[^>]*>\s*([^<]+?)\s*</h2>", main)
for i in range(1, len(parts), 2):
    body = re.sub(r"<code.*?</code>", "", parts[i + 1], flags=re.S)
    found = [c for c in re.findall(r'class="([^"]*)"', body) if c.startswith(prefix)]
    print("##", parts[i])
    for c in dict.fromkeys(found):
        print("  ", " ".join(c.split()))
