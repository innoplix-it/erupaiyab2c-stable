#!/usr/bin/env python3
"""Convert the Phase-1 audit Markdown to styled HTML for PDF printing.
Read-only w.r.t. app source; writes only inside audit-report/."""
import html
import re
import sys

SRC, DST = sys.argv[1], sys.argv[2]
lines = open(SRC, encoding="utf-8").read().splitlines()

def inline(s: str) -> str:
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", s)
    return s

out, i, n = [], 0, len(lines)
while i < n:
    line = lines[i]
    if line.startswith("```"):
        buf = []
        i += 1
        while i < n and not lines[i].startswith("```"):
            buf.append(html.escape(lines[i], quote=False))
            i += 1
        i += 1
        out.append("<pre>" + "\n".join(buf) + "</pre>")
        continue
    m = re.match(r"^(#{1,4})\s+(.*)", line)
    if m:
        lvl = len(m.group(1))
        out.append(f"<h{lvl}>{inline(m.group(2))}</h{lvl}>")
        i += 1
        continue
    if re.match(r"^---\s*$", line):
        out.append("<hr>")
        i += 1
        continue
    if line.startswith("|"):
        rows = []
        while i < n and lines[i].startswith("|"):
            rows.append(lines[i])
            i += 1
        def cells(r):
            return [c.strip() for c in r.strip().strip("|").split("|")]
        tbl = ["<table>"]
        tbl.append("<tr>" + "".join(f"<th>{inline(c)}</th>" for c in cells(rows[0])) + "</tr>")
        for r in rows[2:] if len(rows) > 1 and re.match(r"^\|[\s:|-]+\|$", rows[1]) else rows[1:]:
            tbl.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in cells(r)) + "</tr>")
        tbl.append("</table>")
        out.append("\n".join(tbl))
        continue
    m = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)", line)
    if m:
        indent, bullet, text = m.groups()
        tag = "ol" if bullet[0].isdigit() else "ul"
        out.append(f"<{tag} class=\"{'nested' if indent else ''}\"><li>{inline(text)}</li></{tag}>")
        i += 1
        continue
    if line.strip():
        out.append(f"<p>{inline(line)}</p>")
    i += 1

body = "\n".join(out)
css = """
body{font-family:-apple-system,'Helvetica Neue',Arial,sans-serif;font-size:11px;
line-height:1.5;color:#18181b;margin:0;}
h1{font-size:20px;border-bottom:3px solid #F37021;padding-bottom:6px;}
h2{font-size:15px;margin-top:22px;border-bottom:1px solid #e4e4e7;padding-bottom:3px;}
h3{font-size:13px;margin-top:16px;}
table{border-collapse:collapse;width:100%;margin:8px 0;font-size:10px;}
th,td{border:1px solid #d4d4d8;padding:4px 6px;text-align:left;vertical-align:top;}
th{background:#fafafa;}
code{background:#f4f4f5;padding:1px 3px;border-radius:3px;font-size:10px;}
pre{background:#f4f4f5;border:1px solid #e4e4e7;border-radius:6px;padding:8px;
font-size:9.5px;white-space:pre-wrap;word-break:break-word;}
ul,ol{margin:4px 0 4px 18px;padding:0;list-style:none;}
li{margin:2px 0;}
ul li::before{content:"- ";}
ol{counter-reset:item;}
ol li::before{content:counter(item) ". ";counter-increment:item;}
.nested{margin-left:16px;}
hr{border:none;border-top:1px solid #e4e4e7;margin:14px 0;}
@page{size:A4;margin:14mm 12mm;}
"""
open(DST, "w", encoding="utf-8").write(
    f"<!DOCTYPE html><html><head><meta charset='utf-8'><style>{css}</style></head>"
    f"<body>{body}</body></html>"
)
print("html written:", DST)
