#!/usr/bin/env python3
"""Конвертация SPECIFICATION.md -> PDF через markdown + weasyprint."""
import markdown
from weasyprint import HTML
import sys, re

SRC = "/home/xakus/Documents/projects/amotes/docs/SPECIFICATION.md"
OUT = "/home/xakus/Documents/projects/amotes/docs/SPECIFICATION.pdf"

with open(SRC, encoding="utf-8") as f:
    text = f.read()

# Убираем якорные ссылки в оглавлении на markdown-якоря (weasyprint их не строит),
# оставляем как обычный текст пунктов — proще читать. Заголовки остаются.
html_body = markdown.markdown(
    text,
    extensions=["tables", "fenced_code", "toc", "sane_lists"],
)

FONTS = "/home/xakus/Documents/projects/amotes/assets/fonts"

font_face = f"""
@font-face {{ font-family:"AmotesSans"; font-weight:400; font-style:normal;
  src:url("file://{FONTS}/NotoSans-Regular.ttf"); }}
@font-face {{ font-family:"AmotesSans"; font-weight:400; font-style:italic;
  src:url("file://{FONTS}/NotoSans-Italic.ttf"); }}
@font-face {{ font-family:"AmotesSans"; font-weight:600; font-style:normal;
  src:url("file://{FONTS}/NotoSans-SemiBold.ttf"); }}
@font-face {{ font-family:"AmotesSans"; font-weight:700; font-style:normal;
  src:url("file://{FONTS}/NotoSans-Bold.ttf"); }}
"""

css = font_face + """
@page {
  size: A4;
  margin: 2cm 1.8cm;
  @bottom-center {
    content: "AMOTES — Спецификация · стр. " counter(page) " из " counter(pages);
    font-size: 8pt; color: #888;
  }
}
body {
  font-family: "AmotesSans", "DejaVu Sans", sans-serif;
  font-size: 10pt; line-height: 1.5; color: #1A1A2E;
}
h1 { color: #0D47A1; font-size: 22pt; border-bottom: 3px solid #1565C0;
     padding-bottom: 6px; margin-top: 0.6em; }
h2 { color: #1565C0; font-size: 15pt; border-bottom: 1px solid #D6E4FF;
     padding-bottom: 3px; margin-top: 1.2em; page-break-after: avoid; }
h3 { color: #1976D2; font-size: 12pt; margin-top: 1em; page-break-after: avoid; }
h4 { color: #0091EA; font-size: 10.5pt; margin-top: 0.8em; page-break-after: avoid; }
a { color: #1565C0; text-decoration: none; }
code { font-family: "DejaVu Sans Mono", monospace; font-size: 8.5pt;
       background: #F4F6F9; padding: 1px 4px; border-radius: 3px; color: #0D47A1; }
pre { background: #0D1117; color: #E6EDF3; padding: 10px 12px; border-radius: 6px;
      font-size: 8pt; line-height: 1.35; overflow-x: auto; page-break-inside: avoid; }
pre code { background: none; color: #E6EDF3; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; font-size: 8.5pt;
        page-break-inside: avoid; }
th { background: #1565C0; color: #fff; text-align: left; padding: 5px 7px;
     font-weight: 600; }
td { border: 1px solid #E5E7EB; padding: 4px 7px; vertical-align: top; }
tr:nth-child(even) td { background: #F4F6F9; }
blockquote { border-left: 4px solid #00B0FF; background: #E8F4FD; margin: 10px 0;
             padding: 8px 14px; color: #0D47A1; border-radius: 0 6px 6px 0; }
hr { border: none; border-top: 1px solid #E5E7EB; margin: 16px 0; }
ul, ol { margin: 6px 0 6px 0; padding-left: 22px; }
li { margin: 2px 0; }
strong { color: #0D47A1; }
"""

html_doc = f"""<!DOCTYPE html><html lang="ru"><head><meta charset="utf-8">
<style>{css}</style></head><body>{html_body}</body></html>"""

HTML(string=html_doc).write_pdf(OUT)
print("PDF создан:", OUT)
