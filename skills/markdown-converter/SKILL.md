---
name: markdown-converter
description: Convert documents and files to Markdown with Microsoft's markitdown CLI. Use when converting PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx, .xls), HTML, CSV, JSON, XML, images (EXIF/OCR), audio (transcription), ZIP archives, YouTube URLs, or EPubs to Markdown for LLM processing or text analysis. markitdown must be installed first: if `markitdown` is not on PATH, ask the user before installing it (never install or run it through uvx/pipx on your own).
---

# Markdown Converter

Convert files to Markdown with [`markitdown`](https://github.com/microsoft/markitdown) (Microsoft). Origin and local changes: see `SOURCE.md`.

## Before first use: check, then ask

1. Run `command -v markitdown`. If it exists, use it and skip the rest of this section.
2. If it does not exist, **stop and ask the user** before installing anything. Do not run `uvx markitdown`, `pipx run markitdown`, or `pip install` yourself: each downloads and installs packages.
3. When asking, say what would be installed and how. Use the install method in the machine notes (`~/.agents/rules/99-machine.md`); they differ per machine. Typical forms (Python 3.10 to 3.14 required):
   ```bash
   uv tool install 'markitdown[pdf,docx,pptx,xlsx]'    # isolated, preferred when uv exists
   pipx install 'markitdown[pdf,docx,pptx,xlsx]'
   ```
   Pick extras for the formats actually needed rather than `[all]`:

   | Extra | Adds |
   |-------|------|
   | `pdf`, `docx`, `pptx`, `xlsx`, `xls` | those Office/PDF formats |
   | `outlook` | Outlook messages |
   | `audio-transcription` | WAV/MP3 transcription |
   | `youtube-transcription` | YouTube transcripts |
   | `az-doc-intel`, `az-content-understanding` | Azure backends |
   | `all` | everything |

4. After the user agrees and it is installed, confirm with `markitdown --version`.

## Usage

```bash
markitdown input.pdf                  # to stdout
markitdown input.pdf -o output.md     # to a file
cat input.pdf | markitdown -x .pdf    # stdin needs a type hint
```

For large documents, write to a file with `-o` and read only the parts you need instead of printing everything into the conversation.

## Options

```text
-o, --output FILE        output file (default: stdout)
-x, --extension EXT      file extension hint (for stdin)
-m, --mime-type TYPE     MIME type hint
-c, --charset CS         charset hint, e.g. UTF-8
-d, --use-docintel       Azure Document Intelligence instead of offline conversion
-e, --endpoint URL       Document Intelligence endpoint (or env MARKITDOWN_DOCINTEL_ENDPOINT)
--use-cu                 Azure Content Understanding (needs --cu-endpoint / MARKITDOWN_CU_ENDPOINT)
--cu-analyzer ID         analyzer ID (default: chosen by file type)
--cu-file-types LIST     comma-separated types to route to Content Understanding, e.g. pdf,jpeg,mp4
-p, --use-plugins        enable third-party plugins
--list-plugins           list installed plugins
--keep-data-uris         keep base64 data URIs in the output (default: truncated)
-v, --version
```

## Supported formats

PDF, Word, PowerPoint, Excel, HTML, CSV, JSON, XML, images (EXIF + OCR), audio (EXIF + transcription), ZIP (iterates contents), YouTube URLs, EPub. Output keeps headings, tables, lists, and links.

## Notes

- markitdown reads files and URLs with the privileges of the current process. Only convert files and URLs the user gave you or that the task clearly needs, and be careful with untrusted input.
- For scanned or complex PDFs with poor extraction, `-d` with an Azure Document Intelligence endpoint gives better results; it needs the user's endpoint and credentials, so ask.
- Plugins are off by default; enable them only when the user asks.
