#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import html
import http.server
import json
import math
import os
import re
import shutil
import signal
import socketserver
import subprocess
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path
from typing import Any


def inject_local_site_packages() -> None:
    skill_root = Path(__file__).resolve().parent.parent
    venv_lib = skill_root / ".venv" / "lib"
    if not venv_lib.exists():
        return
    for site_packages in sorted(venv_lib.glob("python*/site-packages")):
        site_path = str(site_packages)
        if site_path not in sys.path:
            sys.path.insert(0, site_path)


inject_local_site_packages()


USER_AGENT = "font-type-studio/0.1"
SESSION_FILENAME = "session.json"
FONT_EXTENSIONS = {".ttf", ".otf", ".woff", ".woff2"}
LIVE_RELOAD_PATH = "/__font_type_studio_events"
AXIS_UPDATE_PATH = "/__font_type_studio_axis"
SERVER_LOG_FILENAME = ".preview-server.log"
SERVER_PID_FILENAME = ".preview-server.pid"
GENERATED_DIRNAME = "generated"
SERVER_INTERNAL_FILENAMES = {SERVER_LOG_FILENAME, SERVER_PID_FILENAME}
GLYPH_SETS = {
    "Uppercase": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "Lowercase": "abcdefghijklmnopqrstuvwxyz",
    "Numbers": "0123456789",
    "Punctuation": "!@#$%^&*()_+-=[]{};:'\",.<>/?`~\\|",
}
WEIGHT_HINTS = [
    ("thin", 100),
    ("extralight", 200),
    ("ultralight", 200),
    ("light", 300),
    ("regular", 400),
    ("book", 400),
    ("medium", 500),
    ("semibold", 600),
    ("demibold", 600),
    ("bold", 700),
    ("extrabold", 800),
    ("ultrabold", 800),
    ("black", 900),
    ("heavy", 900),
]
NAME_NOUNS = [
    "Foundry",
    "Signal",
    "Studio",
    "Text",
    "Display",
    "Form",
    "Shift",
    "Frame",
    "Groove",
    "Draft",
    "Line",
    "Mode",
]
METRIC_DEFAULTS = {
    "width_scale": 1.0,
    "height_scale": 1.0,
    "tracking": 0.0,
    "baseline_shift": 0.0,
    "ascender_shift": 0.0,
    "descender_shift": 0.0,
}
GLYPH_EDIT_DEFAULTS = {
    "scale_x": 1.0,
    "scale_y": 1.0,
    "shift_x": 0.0,
    "shift_y": 0.0,
    "advance_delta": 0.0,
    "lsb_delta": 0.0,
}


def log(message: str) -> None:
    print(message, file=sys.stderr)


def title_case_slug(text: str) -> str:
    return " ".join(part.capitalize() for part in slugify(text).split("-"))


def slugify(text: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "-", text.strip().lower())
    cleaned = re.sub(r"-+", "-", cleaned).strip("-")
    return cleaned or "font-session"


def normalize(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def fetch_text(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request) as response:
        return response.read().decode("utf-8")


def fetch_json(url: str) -> Any:
    text = fetch_text(url)
    if text.startswith(")]}'"):
        text = text[4:]
    return json.loads(text)


def download_file(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def google_fonts_index() -> dict[str, Any]:
    return fetch_json("https://fonts.google.com/metadata/fonts")


def google_font_metadata(family: str) -> dict[str, Any]:
    encoded = urllib.parse.quote(family, safe="")
    return fetch_json(f"https://fonts.google.com/metadata/fonts/{encoded}")


def score_family_match(query: str, family: dict[str, Any]) -> tuple[int, int]:
    query_norm = normalize(query)
    family_name = family.get("family", "")
    family_norm = normalize(family_name)
    score = 0
    if family_norm == query_norm:
        score += 10_000
    elif family_norm.startswith(query_norm):
        score += 7_500
    elif query_norm in family_norm:
        score += 5_000

    query_tokens = [token for token in re.split(r"\W+", query.lower()) if token]
    family_tokens = [token for token in re.split(r"\W+", family_name.lower()) if token]
    token_hits = sum(1 for token in query_tokens if token in family_tokens)
    score += token_hits * 500

    axes_bonus = len(family.get("axes", [])) * 20
    popularity = int(10_000 - family.get("popularity", 10_000))
    score += axes_bonus + popularity
    return score, len(family.get("axes", []))


def search_families(query: str, limit: int) -> list[dict[str, Any]]:
    data = google_fonts_index()
    families = data.get("familyMetadataList", [])
    ranked = sorted(
        families,
        key=lambda item: score_family_match(query, item),
        reverse=True,
    )
    return ranked[:limit]


def repo_slug_candidates(family: str) -> list[str]:
    raw = family.lower().strip()
    candidates = [
        slugify(family).replace("-", ""),
        slugify(family),
        re.sub(r"[^a-z0-9]", "", raw),
        raw.replace(" ", ""),
    ]
    unique: list[str] = []
    for candidate in candidates:
        if candidate and candidate not in unique:
            unique.append(candidate)
    return unique


def scrape_repo_tree(repo_path: str) -> list[dict[str, Any]]:
    tree_url = f"https://github.com/google/fonts/tree/main/{repo_path}"
    page = fetch_text(tree_url)
    pattern = re.compile(rf'/google/fonts/blob/main/{re.escape(repo_path)}/([^"?#]+)')
    names = dedupe_preserve([urllib.parse.unquote(match.group(1)) for match in pattern.finditer(page)])
    items = []
    for name in names:
        encoded_name = urllib.parse.quote(name, safe="[](),._-")
        items.append(
            {
                "name": name,
                "download_url": f"https://raw.githubusercontent.com/google/fonts/main/{repo_path}/{encoded_name}",
            }
        )
    return items


def resolve_repo_assets(metadata: dict[str, Any]) -> dict[str, Any]:
    license_bucket = metadata.get("license", "ofl").lower()
    family = metadata["family"]
    last_error = ""
    for slug in repo_slug_candidates(family):
        repo_path = f"{license_bucket}/{slug}"
        url = f"https://api.github.com/repos/google/fonts/contents/{repo_path}"
        try:
            contents = fetch_json(url)
        except urllib.error.HTTPError as error:
            last_error = f"{url}: {error.code}"
            try:
                contents = scrape_repo_tree(repo_path)
            except Exception as scrape_error:
                last_error = f"{last_error}; fallback failed: {scrape_error}"
                continue
        if not isinstance(contents, list):
            continue

        font_files = [
            item
            for item in contents
            if isinstance(item, dict)
            and Path(item.get("name", "")).suffix.lower() in FONT_EXTENSIONS
        ]
        license_files = [
            item
            for item in contents
            if isinstance(item, dict)
            and item.get("name", "").lower() in {"ofl.txt", "ufl.txt", "apache.txt", "license.txt"}
        ]
        other_docs = [
            item
            for item in contents
            if isinstance(item, dict)
            and item.get("name", "").lower() in {"description.en_us.html", "metadata.pb"}
        ]
        if font_files:
            return {
                "license_bucket": license_bucket,
                "repo_slug": slug,
                "repo_path": repo_path,
                "font_files": font_files,
                "license_files": license_files,
                "other_docs": other_docs,
            }

    raise RuntimeError(f"Could not resolve downloadable files for {family}. Last lookup: {last_error}")


def primary_font_file(source_fonts: list[dict[str, Any]]) -> dict[str, Any]:
    def score(item: dict[str, Any]) -> tuple[int, str]:
        name = item["filename"].lower()
        return (
            1 if "[" in name and "]" in name else 0,
            name,
        )

    return sorted(source_fonts, key=score, reverse=True)[0]


def parse_filename_style(name: str) -> dict[str, Any]:
    lower = name.lower()
    style = "italic" if "italic" in lower or lower.endswith("i.ttf") or lower.endswith("i.otf") else "normal"
    weight = 400
    for token, value in WEIGHT_HINTS:
        if token in lower:
            weight = value
            break
    return {"font_style": style, "font_weight": weight}


def default_metrics_state() -> dict[str, float]:
    return dict(METRIC_DEFAULTS)


def default_glyph_edit(target: str) -> dict[str, Any]:
    edit: dict[str, Any] = {"target": target}
    edit.update(GLYPH_EDIT_DEFAULTS)
    return edit


def normalize_session(session: dict[str, Any]) -> dict[str, Any]:
    metrics = session.setdefault("metrics", default_metrics_state())
    for key, value in METRIC_DEFAULTS.items():
        metrics.setdefault(key, value)

    glyph_edits = session.setdefault("glyph_edits", [])
    normalized_edits = []
    for item in glyph_edits:
        if not isinstance(item, dict) or "target" not in item:
            continue
        edit = default_glyph_edit(str(item["target"]))
        for key in GLYPH_EDIT_DEFAULTS:
            if key in item:
                edit[key] = float(item[key])
        normalized_edits.append(edit)
    session["glyph_edits"] = normalized_edits

    source_fonts = session.get("source_fonts", [])
    session.setdefault("active_fonts", [dict(item) for item in source_fonts])
    return session


def active_font_items(session: dict[str, Any]) -> list[dict[str, Any]]:
    active = session.get("active_fonts") or session.get("source_fonts") or []
    return [dict(item) for item in active]


def has_binary_edits(session: dict[str, Any]) -> bool:
    metrics = normalize_session(session).get("metrics", {})
    metric_changes = any(abs(float(metrics[key]) - float(default)) > 1e-9 for key, default in METRIC_DEFAULTS.items())
    return metric_changes or bool(session.get("glyph_edits"))


def build_session(metadata: dict[str, Any], assets: dict[str, Any], workspace: Path) -> dict[str, Any]:
    source_fonts: list[dict[str, Any]] = []
    for item in assets["font_files"]:
        style_info = parse_filename_style(item["name"])
        source_fonts.append(
            {
                "filename": item["name"],
                "path": f"source/{item['name']}",
                "download_url": item["download_url"],
                "font_style": style_info["font_style"],
                "font_weight": style_info["font_weight"],
            }
        )

    axes = []
    for axis in metadata.get("axes", []):
        axes.append(
            {
                "tag": axis["tag"],
                "min": axis["min"],
                "max": axis["max"],
                "default": axis["defaultValue"],
                "current": axis["defaultValue"],
            }
        )

    session = {
        "version": 1,
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "workspace": str(workspace.resolve()),
        "source_family": metadata["family"],
        "export_family": f"{metadata['family']} Studio",
        "category": metadata.get("category", "Unknown"),
        "license": metadata.get("license", "unknown"),
        "designers": metadata.get("designers", []),
        "repo_path": assets["repo_path"],
        "source_fonts": source_fonts,
        "axes": axes,
        "sample_text": "Sphinx of black quartz, judge my vow.",
        "descriptors": [
            metadata.get("category", "type").lower(),
            "variable" if axes else "static",
        ],
        "notes": [
            "Workspace initialized from a real online font family.",
        ],
        "available_weights": sorted(metadata.get("fonts", {}).keys()),
        "name_suggestions": [],
        "warnings": [],
        "metrics": default_metrics_state(),
        "glyph_edits": [],
        "active_fonts": [dict(item) for item in source_fonts],
    }
    return normalize_session(session)


def render_axis_controls(axes: list[dict[str, Any]]) -> str:
    if not axes:
        return '<div class="empty-state">No variable axes detected. This session is using the downloaded source files as-is.</div>'

    blocks = []
    for axis in axes:
        tag = html.escape(axis["tag"])
        blocks.append(
            textwrap.dedent(
                f"""
                <label class="axis-control">
                  <span class="axis-head">
                    <strong>{tag}</strong>
                    <output id="value-{tag}">{axis['current']}</output>
                  </span>
                  <input data-axis-range="{tag}" type="range" min="{axis['min']}" max="{axis['max']}" step="any" value="{axis['current']}">
                  <div class="axis-number-row">
                    <input data-axis-number="{tag}" class="axis-number" type="number" step="any" inputmode="decimal" value="{axis['current']}" aria-label="{tag} value">
                  </div>
                  <span class="axis-meta">{axis['min']} to {axis['max']} (default {axis['default']})</span>
                </label>
                """
            ).strip()
        )
    return "\n".join(blocks)


def render_glyph_grid() -> str:
    sections = []
    for label, glyphs in GLYPH_SETS.items():
        cells = "".join(f'<span class="glyph">{html.escape(char)}</span>' for char in glyphs)
        sections.append(
            textwrap.dedent(
                f"""
                <section class="glyph-section">
                  <h3>{html.escape(label)}</h3>
                  <div class="glyph-grid">{cells}</div>
                </section>
                """
            ).strip()
        )
    return "\n".join(sections)


def render_preview_html(
    session: dict[str, Any],
    workspace: Path,
    target: Path,
    font_root: str | None = None,
    font_items: list[dict[str, Any]] | None = None,
) -> None:
    source_fonts = font_items or active_font_items(session)
    primary_font = primary_font_file(source_fonts)
    axes = session.get("axes", [])
    metrics = session.get("metrics", default_metrics_state())
    glyph_edits = session.get("glyph_edits", [])
    font_faces = []
    for item in source_fonts:
        format_map = {
            ".ttf": "truetype",
            ".otf": "opentype",
            ".woff": "woff",
            ".woff2": "woff2",
        }
        suffix = Path(item["filename"]).suffix.lower()
        fmt = format_map.get(suffix, "truetype")
        if font_root is None:
            font_url = os.path.relpath(workspace / item["path"], target.parent).replace(os.sep, "/")
        else:
            font_url = f"{font_root}/{item['filename']}"
        font_faces.append(
            textwrap.dedent(
                f"""
                @font-face {{
                  font-family: 'FTSPreview';
                  src: url('{font_url}') format('{fmt}');
                  font-style: {item['font_style']};
                  font-weight: {item['font_weight']};
                }}
                """
            ).strip()
        )

    session_payload = json.dumps(session, indent=2)
    variation_settings = (
        ", ".join(f'"{axis["tag"]}" {axis["current"]}' for axis in axes) if axes else "normal"
    )
    preview_html = textwrap.dedent(
        f"""
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>{html.escape(session['export_family'])} Workbench</title>
          <style>
            {os.linesep.join(font_faces)}

            :root {{
              --bg: #f5efe4;
              --ink: #181411;
              --panel: rgba(255, 255, 255, 0.78);
              --line: rgba(24, 20, 17, 0.12);
              --accent: #9e5a2d;
              --variation-settings: {variation_settings};
            }}

            * {{ box-sizing: border-box; }}
            body {{
              margin: 0;
              font-family: Georgia, serif;
              color: var(--ink);
              background:
                radial-gradient(circle at top left, rgba(158, 90, 45, 0.18), transparent 32%),
                linear-gradient(160deg, #f8f4ec 0%, #efe4d5 56%, #e4d3c4 100%);
              min-height: 100vh;
            }}
            main {{
              width: min(1720px, calc(100vw - 8px));
              margin: 0 auto;
              padding: 32px 0 64px;
              display: grid;
              gap: 18px;
            }}
            .panel {{
              background: var(--panel);
              backdrop-filter: blur(18px);
              border: 1px solid var(--line);
              border-radius: 24px;
              box-shadow: 0 20px 60px rgba(24, 20, 17, 0.08);
              overflow: hidden;
            }}
            .hero {{ padding: 28px; display: grid; gap: 18px; }}
            .eyebrow {{
              display: inline-flex;
              width: fit-content;
              gap: 8px;
              align-items: center;
              padding: 8px 12px;
              border-radius: 999px;
              border: 1px solid var(--line);
              letter-spacing: 0.08em;
              text-transform: uppercase;
              font: 600 11px/1.1 Arial, sans-serif;
            }}
            h1, h2, h3, .specimen, .glyph, .preset-sample {{
              font-family: 'FTSPreview', Georgia, serif;
              font-variation-settings: var(--variation-settings);
            }}
            h1 {{ margin: 0; font-size: clamp(3.2rem, 9vw, 8rem); line-height: 0.95; letter-spacing: -0.05em; }}
            .meta {{ display: flex; flex-wrap: wrap; gap: 10px; font: 500 14px/1.4 Arial, sans-serif; color: rgba(24, 20, 17, 0.76); }}
            .meta span {{ padding: 8px 12px; border-radius: 999px; background: rgba(255,255,255,0.58); border: 1px solid var(--line); }}
            .meta span.live {{ border-color: rgba(158, 90, 45, 0.24); background: rgba(158, 90, 45, 0.12); }}
            .grid {{ display: grid; gap: 18px; grid-template-columns: minmax(240px, 270px) minmax(0, 1fr); }}
            .controls, .specimens, .glyphs, .notes {{ padding: 22px; }}
            .controls {{ display: grid; gap: 16px; align-content: start; }}
            .axis-control {{ display: grid; gap: 8px; }}
            .axis-head {{ display: flex; justify-content: space-between; align-items: center; font: 600 14px/1.2 Arial, sans-serif; }}
            .axis-meta, .small {{ color: rgba(24, 20, 17, 0.68); font: 500 12px/1.35 Arial, sans-serif; }}
            input[type="range"] {{ width: 100%; accent-color: var(--accent); }}
            .axis-number-row {{ display: grid; justify-content: start; }}
            .axis-number {{ width: 110px; border-radius: 12px; border: 1px solid var(--line); padding: 8px 10px; font: 600 13px/1.2 Arial, sans-serif; background: rgba(255,255,255,0.74); color: var(--ink); }}
            textarea {{ width: 100%; min-height: 110px; resize: vertical; border-radius: 18px; border: 1px solid var(--line); padding: 14px 16px; font: 500 15px/1.45 Arial, sans-serif; background: rgba(255,255,255,0.7); }}
            .empty-state {{ padding: 14px 16px; border-radius: 18px; background: rgba(255,255,255,0.58); border: 1px dashed var(--line); font: 500 13px/1.45 Arial, sans-serif; }}
            .specimens {{ display: grid; gap: 18px; min-width: 0; }}
            .specimen-scroll {{ display: grid; gap: 18px; min-width: 0; width: 100%; padding-bottom: 6px; }}
            .specimen {{ font-size: clamp(2.4rem, 6.5vw, 6.8rem); line-height: 0.95; margin: 0; max-width: 100%; white-space: pre-wrap; overflow-wrap: anywhere; word-break: break-word; }}
            .body-sample {{ font-family: 'FTSPreview', Georgia, serif; font-variation-settings: var(--variation-settings); font-size: clamp(1.1rem, 2vw, 1.6rem); line-height: 1.35; max-width: 100%; white-space: pre-wrap; overflow-wrap: anywhere; word-break: break-word; }}
            .preset-grid {{ display: grid; gap: 12px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); min-width: 0; }}
            .preset-card {{ padding: 16px; border-radius: 18px; border: 1px solid var(--line); background: rgba(255,255,255,0.52); min-width: 0; overflow: hidden; }}
            .preset-label {{ display: block; margin-bottom: 6px; font: 600 12px/1.2 Arial, sans-serif; text-transform: uppercase; letter-spacing: 0.08em; color: rgba(24, 20, 17, 0.68); }}
            .preset-sample {{ font-size: 2rem; line-height: 1; white-space: nowrap; overflow: hidden; text-overflow: clip; }}
            .sizes {{ padding: 22px; display: grid; gap: 12px; }}
            .size-row {{ display: grid; grid-template-columns: 72px minmax(0, 1fr); gap: 14px; align-items: baseline; padding: 12px 0; border-top: 1px solid var(--line); }}
            .size-row:first-of-type {{ border-top: none; }}
            .size-label {{ font: 600 12px/1.2 Arial, sans-serif; letter-spacing: 0.08em; text-transform: uppercase; color: rgba(24, 20, 17, 0.58); }}
            .size-sample {{ font-family: 'FTSPreview', Georgia, serif; font-variation-settings: var(--variation-settings); line-height: 0.98; }}
            .prompt-list {{ display: grid; gap: 8px; margin: 0; padding-left: 18px; font: 500 14px/1.45 Arial, sans-serif; }}
            .glyphs {{ display: grid; gap: 18px; }}
            .glyph-section h3 {{ margin: 0 0 10px; font-size: 1.2rem; }}
            .glyph-grid {{ display: grid; gap: 8px; grid-template-columns: repeat(auto-fill, minmax(50px, 1fr)); }}
            .glyph {{ display: grid; place-items: center; min-height: 56px; border-radius: 16px; border: 1px solid var(--line); background: rgba(255,255,255,0.56); font-size: 1.8rem; }}
            code {{ font-family: Menlo, monospace; font-size: 12px; }}
            .notes ul {{ margin: 0; padding-left: 18px; display: grid; gap: 8px; font: 500 14px/1.5 Arial, sans-serif; }}
            @media (max-width: 860px) {{
              .grid {{ grid-template-columns: 1fr; }}
              main {{ width: min(100vw - 12px, 1720px); padding-top: 20px; }}
              .hero, .controls, .specimens, .glyphs, .notes {{ padding: 18px; }}
            }}
          </style>
        </head>
        <body>
          <main>
            <section class="panel hero">
              <span class="eyebrow">Font Type Studio</span>
              <div>
                <h1>{html.escape(session['export_family'])}</h1>
                <div class="meta">
                  <span>Source: {html.escape(session['source_family'])}</span>
                  <span>Category: {html.escape(session['category'])}</span>
                  <span>License: {html.escape(session['license']).upper()}</span>
                  <span>Primary file: {html.escape(primary_font['filename'])}</span>
                  <span>{'Edited binary preview' if has_binary_edits(session) else 'Source preview'}</span>
                  <span class="live" id="live-status">Static file mode</span>
                </div>
              </div>
              <div class="small">Live preview file: <code>{html.escape(str(target))}</code></div>
            </section>

            <section class="grid">
              <aside class="panel controls">
                <div>
                  <h2>Controls</h2>
                  <p class="small">Move sliders here for instant feedback in the browser. Conversational changes update the same defaults when the workspace is regenerated. {"With binary edits active, release the slider to rebuild the preview weight." if has_binary_edits(session) else ""}</p>
                </div>
                {render_axis_controls(axes)}
                <label>
                  <span class="axis-head"><strong>Sample text</strong></span>
                  <textarea id="sample-input">{html.escape(session['sample_text'])}</textarea>
                </label>
                <div class="small">Current settings: <code id="settings-output">{html.escape(variation_settings)}</code></div>
              </aside>

              <div class="panel specimens">
                <div>
                  <h2>Specimen</h2>
                  <p class="small">All major preview areas use the same live variation settings.</p>
                </div>
                <div class="specimen-scroll">
                  <p class="specimen" id="specimen-headline">{html.escape(session['sample_text'])}</p>
                  <p class="body-sample" id="specimen-body">{html.escape(session['sample_text'])}</p>
                  <div>
                    <h3>Session descriptors</h3>
                    <div class="meta">{''.join(f'<span>{html.escape(item)}</span>' for item in session.get('descriptors', []))}</div>
                  </div>
                  <div>
                    <h3>Quick presets</h3>
                    <div class="preset-grid" id="preset-grid"></div>
                  </div>
                </div>
              </div>
            </section>

            <section class="panel glyphs">
              <div>
                <h2>Glyph Atlas</h2>
                <p class="small">Uppercase, lowercase, numbers, and punctuation in one place.</p>
              </div>
              {render_glyph_grid()}
            </section>

            <section class="panel sizes">
              <div>
                <h2>Size Ramp</h2>
                <p class="small">A quick read on how the current setting behaves across display, headline, and text sizes.</p>
              </div>
              <div class="size-row">
                <span class="size-label">96 px</span>
                <div class="size-sample" style="font-size: 96px;">Ag</div>
              </div>
              <div class="size-row">
                <span class="size-label">64 px</span>
                <div class="size-sample" style="font-size: 64px;">{html.escape(session['sample_text'])}</div>
              </div>
              <div class="size-row">
                <span class="size-label">32 px</span>
                <div class="size-sample" style="font-size: 32px;">Hamburgefontsiv</div>
              </div>
              <div class="size-row">
                <span class="size-label">18 px</span>
                <div class="size-sample" style="font-size: 18px;">The quick brown fox jumps over the lazy dog.</div>
              </div>
              <div class="size-row">
                <span class="size-label">14 px</span>
                <div class="size-sample" style="font-size: 14px; line-height: 1.35;">0123456789 &middot; Alignment check: H O n o p q b d</div>
              </div>
            </section>

            <section class="panel notes">
              <div>
                <h2>Metric Edits</h2>
                <p class="small">These edits affect height, width, spacing, and baseline alignment in the generated preview font.</p>
              </div>
              <div class="meta">
                <span>Width scale: {metrics['width_scale']}</span>
                <span>Height scale: {metrics['height_scale']}</span>
                <span>Tracking: {metrics['tracking']}</span>
                <span>Baseline shift: {metrics['baseline_shift']}</span>
                <span>Ascender shift: {metrics['ascender_shift']}</span>
                <span>Descender shift: {metrics['descender_shift']}</span>
              </div>
            </section>

            <section class="panel notes">
              <div>
                <h2>Glyph Edits</h2>
                <p class="small">Targeted outline edits are applied directly to matching glyphs in the generated preview font.</p>
              </div>
              <ul>
                {''.join(f"<li>{html.escape(edit['target'])}: scale_x={edit['scale_x']}, scale_y={edit['scale_y']}, shift_x={edit['shift_x']}, shift_y={edit['shift_y']}, advance_delta={edit['advance_delta']}, lsb_delta={edit['lsb_delta']}</li>" for edit in glyph_edits) or '<li>No glyph-specific edits yet.</li>'}
              </ul>
            </section>

            <section class="panel notes">
              <div>
                <h2>What You Can Ask</h2>
                <p class="small">The conversation edits the session and this page updates automatically when the server is running.</p>
              </div>
              <ul class="prompt-list">
                <li>Make it heavier or lighter</li>
                <li>Show a different sample phrase or brand word</li>
                <li>Make it feel sharper, softer, more playful, or more technical</li>
                <li>Make it wider, shorter, or better aligned with metric edits</li>
                <li>Edit a specific glyph like A, S, or y with outline transforms</li>
                <li>Prepare an export package and suggest new family names</li>
              </ul>
            </section>

            <section class="panel notes">
              <div>
                <h2>Session Notes</h2>
                <p class="small">Stored in <code>{html.escape(str(workspace / SESSION_FILENAME))}</code>.</p>
              </div>
              <ul>
                {''.join(f'<li>{html.escape(note)}</li>' for note in session.get('notes', []))}
              </ul>
            </section>
          </main>

          <script>
            const session = {session_payload};
            const binaryEditsActive = {str(has_binary_edits(session)).lower()};
            const root = document.documentElement;
            const sampleInput = document.getElementById('sample-input');
            const headline = document.getElementById('specimen-headline');
            const body = document.getElementById('specimen-body');
            const settingsOutput = document.getElementById('settings-output');
            const presetGrid = document.getElementById('preset-grid');
            const liveStatus = document.getElementById('live-status');
            let axisUpdateController = null;
            const sampleDraftKey = `font-type-studio-sample:${{window.location.pathname}}`;

            function formatAxisValue(value) {{
              return Number(value).toFixed(2).replace(/\\.00$/, '');
            }}

            function clampAxisValue(axis, value) {{
              return Math.min(Math.max(Number(value), Number(axis.min)), Number(axis.max));
            }}

            function currentAxisMap() {{
              return Object.fromEntries((session.axes || []).map((axis) => [axis.tag, Number(axis.current)]));
            }}

            function applySettings() {{
              const settings = (session.axes || []).length
                ? session.axes.map((axis) => `"${{axis.tag}}" ${{Number(axis.current)}}`).join(', ')
                : 'normal';
              if (!binaryEditsActive) root.style.setProperty('--variation-settings', settings);
              settingsOutput.textContent = settings;
              headline.textContent = sampleInput.value;
              body.textContent = sampleInput.value;
              (session.axes || []).forEach((axis) => {{
                const target = document.getElementById(`value-${{axis.tag}}`);
                if (target) target.textContent = formatAxisValue(axis.current);
                const rangeInput = document.querySelector(`[data-axis-range="${{axis.tag}}"]`);
                const numberInput = document.querySelector(`[data-axis-number="${{axis.tag}}"]`);
                if (rangeInput) rangeInput.value = Number(axis.current);
                if (numberInput && !(numberInput.dataset.editing === 'true' && document.activeElement === numberInput)) {{
                  numberInput.value = formatAxisValue(axis.current);
                }}
              }});
            }}

            function updateAxisValue(tag, nextValue) {{
              const axis = (session.axes || []).find((item) => item.tag === tag);
              if (!axis) return false;
              const numericValue = Number(nextValue);
              if (!Number.isFinite(numericValue)) return false;
              axis.current = clampAxisValue(axis, numericValue);
              applySettings();
              buildPresets();
              return true;
            }}

            function commitAxisNumberInput(input) {{
              const axis = (session.axes || []).find((item) => item.tag === input.dataset.axisNumber);
              if (!axis) return;
              input.dataset.editing = 'false';
              const numericValue = Number(input.value);
              if (!Number.isFinite(numericValue)) {{
                input.value = formatAxisValue(axis.current);
                return;
              }}
              axis.current = clampAxisValue(axis, numericValue);
              applySettings();
              buildPresets();
              if (binaryEditsActive) persistAxisSettings();
            }}

            function buildPresets() {{
              presetGrid.innerHTML = '';
              const axes = session.axes || [];
              if (!axes.length) {{
                presetGrid.innerHTML = '<div class="preset-card"><span class="preset-label">Static Source</span><div class="preset-sample">Aa</div><div class="small">No variable axes available.</div></div>';
                return;
              }}

              const presets = [
                ['Minimum', 'min'],
                ['Default', 'default'],
                ['Current', 'current'],
                ['Maximum', 'max'],
              ];

              presets.forEach(([label, key]) => {{
                const settings = axes.map((axis) => `"${{axis.tag}}" ${{Number(axis[key])}}`).join(', ');
                const card = document.createElement('article');
                card.className = 'preset-card';
                const labelEl = document.createElement('span');
                labelEl.className = 'preset-label';
                labelEl.textContent = label;

                const sampleEl = document.createElement('div');
                sampleEl.className = 'preset-sample';
                sampleEl.textContent = 'Aa';
                sampleEl.style.fontVariationSettings = settings;

                const metaEl = document.createElement('div');
                metaEl.className = 'small';
                const codeEl = document.createElement('code');
                codeEl.textContent = settings;
                metaEl.appendChild(codeEl);

                card.appendChild(labelEl);
                card.appendChild(sampleEl);
                card.appendChild(metaEl);
                presetGrid.appendChild(card);
              }});
            }}

            function setLiveStatus(message) {{
              if (liveStatus) liveStatus.textContent = message;
            }}

            function saveSampleDraft() {{
              try {{
                window.sessionStorage.setItem(sampleDraftKey, sampleInput.value);
              }} catch (_error) {{
              }}
            }}

            function restoreSampleDraft() {{
              try {{
                const draft = window.sessionStorage.getItem(sampleDraftKey);
                if (draft !== null) sampleInput.value = draft;
              }} catch (_error) {{
              }}
            }}

            function connectLiveReload() {{
              if (!window.location.protocol.startsWith('http')) {{
                setLiveStatus('Open via preview server for auto-refresh');
                return;
              }}
              if (typeof EventSource === 'undefined') {{
                setLiveStatus('Live reload unsupported in this browser');
                return;
              }}

              const stream = new EventSource('{LIVE_RELOAD_PATH}');
              stream.addEventListener('open', () => setLiveStatus('Live reload connected'));
              stream.addEventListener('reload', () => {{
                setLiveStatus('Change detected, reloading...');
                window.location.reload();
              }});
              stream.onerror = () => setLiveStatus('Live reload disconnected');
            }}

            async function persistAxisSettings() {{
              if (!binaryEditsActive || !window.location.protocol.startsWith('http')) return;
              const primaryAxis = (session.axes || [])[0];
              if (!primaryAxis) return;
              if (axisUpdateController) axisUpdateController.abort();
              axisUpdateController = new AbortController();
              setLiveStatus(`Updating ${'{'}primaryAxis.tag{'}'}...`);
              saveSampleDraft();
              try {{
                const response = await fetch(`{AXIS_UPDATE_PATH}`, {{
                  method: 'POST',
                  headers: {{ 'Content-Type': 'application/json' }},
                  body: JSON.stringify({{
                    tag: primaryAxis.tag,
                    value: primaryAxis.current,
                    sample_text: sampleInput.value,
                  }}),
                  signal: axisUpdateController.signal,
                }});
                if (!response.ok) throw new Error(`HTTP ${'{'}response.status{'}'}`);
                setLiveStatus(`Regenerated ${'{'}primaryAxis.tag{'}'} preview`);
              }} catch (error) {{
                if (error.name === 'AbortError') return;
                setLiveStatus(`Axis update failed: ${'{'}error.message{'}'}`);
              }}
            }}

            document.querySelectorAll('[data-axis-range]').forEach((input) => {{
              input.addEventListener('input', () => {{
                if (!updateAxisValue(input.dataset.axisRange, input.value)) return;
                if (binaryEditsActive) setLiveStatus('Release slider to rebuild weight');
              }});
              input.addEventListener('change', () => {{
                if (binaryEditsActive) persistAxisSettings();
              }});
            }});

            document.querySelectorAll('[data-axis-number]').forEach((input) => {{
              input.addEventListener('focus', () => {{
                input.dataset.editing = 'true';
              }});
              input.addEventListener('input', () => {{
                if (binaryEditsActive) setLiveStatus('Press enter or blur to rebuild weight');
              }});
              input.addEventListener('keydown', (event) => {{
                if (event.key === 'Enter') {{
                  commitAxisNumberInput(input);
                  input.blur();
                }}
                if (event.key === 'Escape') {{
                  input.dataset.editing = 'false';
                  const axis = (session.axes || []).find((item) => item.tag === input.dataset.axisNumber);
                  if (axis) input.value = formatAxisValue(axis.current);
                  input.blur();
                }}
              }});
              input.addEventListener('blur', () => {{
                commitAxisNumberInput(input);
              }});
            }});

            sampleInput.addEventListener('input', () => {{
              saveSampleDraft();
              applySettings();
            }});

            restoreSampleDraft();
            applySettings();
            buildPresets();
            connectLiveReload();
          </script>
        </body>
        </html>
        """
    ).strip() + "\n"
    target.write_text(preview_html, encoding="utf-8")


def write_session(workspace: Path, session: dict[str, Any]) -> None:
    (workspace / SESSION_FILENAME).write_text(json.dumps(session, indent=2) + "\n", encoding="utf-8")


def load_session(workspace: Path) -> dict[str, Any]:
    session_path = workspace / SESSION_FILENAME
    if not session_path.exists():
        raise FileNotFoundError(f"Missing session file at {session_path}")
    return normalize_session(json.loads(session_path.read_text(encoding="utf-8")))


def regenerate_preview(workspace: Path, session: dict[str, Any]) -> Path:
    preview_dir = workspace / "preview"
    ensure_dir(preview_dir)
    target = preview_dir / "index.html"
    render_preview_html(session, workspace, target)
    return target


def persist_workspace_session(workspace: Path, session: dict[str, Any]) -> None:
    rebuild_active_fonts(workspace, session)
    write_session(workspace, session)
    regenerate_preview(workspace, session)


def update_workspace_axis(workspace: Path, tag: str, value: float, sample_text: str | None = None) -> dict[str, Any]:
    session = load_session(workspace)
    update_axes(session, {tag: value})
    if sample_text is not None:
        session["sample_text"] = sample_text
    persist_workspace_session(workspace, session)
    return session


def refresh_preview_with_latest_script(workspace: Path) -> None:
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "update",
        "--workspace",
        str(workspace),
    ]
    completed = subprocess.run(command, capture_output=True, text=True)
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip() or "Unknown preview refresh error"
        raise RuntimeError(message)


def workspace_mtime_token(workspace: Path) -> int:
    latest = 0
    for path in workspace.rglob("*"):
        if path.name in SERVER_INTERNAL_FILENAMES:
            continue
        try:
            latest = max(latest, path.stat().st_mtime_ns)
        except FileNotFoundError:
            continue
    return latest


class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

    def handle_error(self, request: Any, client_address: Any) -> None:
        _, error, _ = sys.exc_info()
        if isinstance(error, (BrokenPipeError, ConnectionResetError)):
            return
        super().handle_error(request, client_address)


def make_preview_handler(workspace: Path) -> type[http.server.SimpleHTTPRequestHandler]:
    class PreviewHandler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args: Any, **kwargs: Any) -> None:
            super().__init__(*args, directory=str(workspace), **kwargs)

        def end_headers(self) -> None:
            self.send_header("Cache-Control", "no-store")
            super().end_headers()

        def log_message(self, format: str, *args: Any) -> None:
            return

        def do_GET(self) -> None:
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path in {"", "/"}:
                self.send_response(302)
                self.send_header("Location", "/preview/index.html")
                self.end_headers()
                return
            if parsed.path == LIVE_RELOAD_PATH:
                self.handle_live_reload()
                return
            if parsed.path == "/preview/index.html":
                try:
                    refresh_preview_with_latest_script(workspace)
                except Exception as error:
                    body = f"Preview refresh failed: {error}".encode("utf-8")
                    self.send_response(500)
                    self.send_header("Content-Type", "text/plain; charset=utf-8")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)
                    return
            super().do_GET()

        def do_POST(self) -> None:
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path == AXIS_UPDATE_PATH:
                self.handle_axis_update(parsed)
                return
            self.send_error(404, "Not found")

        def handle_axis_update(self, parsed: urllib.parse.ParseResult) -> None:
            payload: dict[str, Any] = {}
            length = int(self.headers.get("Content-Length", "0") or "0")
            content_type = self.headers.get("Content-Type", "")
            if length > 0 and "application/json" in content_type:
                try:
                    payload = json.loads(self.rfile.read(length).decode("utf-8"))
                except Exception:
                    payload = {}
            else:
                query = urllib.parse.parse_qs(parsed.query)
                payload = {
                    "tag": (query.get("tag") or [""])[0],
                    "value": (query.get("value") or [""])[0],
                    "sample_text": (query.get("sample_text") or [None])[0],
                }

            tag = str(payload.get("tag", "")).strip()
            raw_value = str(payload.get("value", "")).strip()
            sample_text = payload.get("sample_text")
            if not tag or not raw_value:
                self.send_error(400, "Missing tag or value")
                return
            try:
                session = update_workspace_axis(
                    workspace,
                    tag,
                    float(raw_value),
                    str(sample_text) if sample_text is not None else None,
                )
            except Exception as error:
                body = json.dumps({"error": str(error)}).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return

            current_value = next((axis["current"] for axis in session.get("axes", []) if axis["tag"] == tag), None)
            body = json.dumps({"ok": True, "tag": tag, "current": current_value}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def handle_live_reload(self) -> None:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Connection", "keep-alive")
            self.end_headers()

            last_token = workspace_mtime_token(workspace)
            last_ping = time.time()
            try:
                self.wfile.write(f"event: ready\ndata: {last_token}\n\n".encode("utf-8"))
                self.wfile.flush()
                while True:
                    time.sleep(1)
                    current_token = workspace_mtime_token(workspace)
                    if current_token != last_token:
                        last_token = current_token
                        self.wfile.write(f"event: reload\ndata: {current_token}\n\n".encode("utf-8"))
                        self.wfile.flush()
                        last_ping = time.time()
                        continue
                    if time.time() - last_ping >= 15:
                        self.wfile.write(b": keep-alive\n\n")
                        self.wfile.flush()
                        last_ping = time.time()
            except (BrokenPipeError, ConnectionResetError):
                return

    return PreviewHandler


def preview_server_pid_path(workspace: Path) -> Path:
    return workspace / "preview" / SERVER_PID_FILENAME


def preview_server_log_path(workspace: Path) -> Path:
    return workspace / "preview" / SERVER_LOG_FILENAME


def preview_server_url(host: str, port: int) -> str:
    url_host = "127.0.0.1" if host in {"0.0.0.0", "::"} else host
    return f"http://{url_host}:{port}/preview/index.html"


def read_preview_server_pid(workspace: Path) -> int | None:
    pid_path = preview_server_pid_path(workspace)
    if not pid_path.exists():
        return None
    try:
        return int(pid_path.read_text(encoding="utf-8").strip())
    except ValueError:
        return None


def process_is_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def spawn_preview_server(workspace: Path, host: str, port: int, open_browser: bool) -> tuple[int, str, Path]:
    existing_pid = read_preview_server_pid(workspace)
    if existing_pid and process_is_running(existing_pid):
        return existing_pid, preview_server_url(host, port), preview_server_log_path(workspace)

    ensure_dir(workspace / "preview")
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "serve",
        "--workspace",
        str(workspace),
        "--host",
        host,
        "--port",
        str(port),
    ]
    if open_browser:
        command.append("--open")

    log_path = preview_server_log_path(workspace)
    with log_path.open("ab") as handle:
        process = subprocess.Popen(
            command,
            stdout=handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )

    time.sleep(1)
    if process.poll() is not None:
        log_tail = log_path.read_text(encoding="utf-8", errors="ignore")[-1200:] if log_path.exists() else ""
        raise RuntimeError(f"Preview server failed to start. {log_tail.strip()}")

    preview_server_pid_path(workspace).write_text(f"{process.pid}\n", encoding="utf-8")
    return process.pid, preview_server_url(host, port), log_path


def stop_preview_server(workspace: Path) -> bool:
    pid = read_preview_server_pid(workspace)
    pid_path = preview_server_pid_path(workspace)
    if pid is None:
        return False
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    if pid_path.exists():
        pid_path.unlink()
    return True


def append_warning(session: dict[str, Any], message: str) -> None:
    warnings = session.setdefault("warnings", [])
    if message not in warnings:
        warnings.append(message)


def parse_metric_assignments(metric_pairs: list[str]) -> dict[str, float]:
    updates: dict[str, float] = {}
    for raw in metric_pairs:
        if "=" not in raw:
            raise ValueError(f"Invalid metric assignment: {raw}")
        key, value = raw.split("=", 1)
        metric_name = key.strip()
        if metric_name not in METRIC_DEFAULTS:
            raise ValueError(f"Unsupported metric field: {metric_name}")
        updates[metric_name] = float(value.strip())
    return updates


def apply_metric_updates(session: dict[str, Any], metric_updates: dict[str, float]) -> None:
    metrics = session.setdefault("metrics", default_metrics_state())
    for key, value in metric_updates.items():
        metrics[key] = value


def parse_glyph_edit(raw: str) -> dict[str, Any]:
    if ":" not in raw:
        raise ValueError(f"Invalid glyph edit: {raw}")
    target, assignments = raw.split(":", 1)
    edit = default_glyph_edit(target.strip())
    for assignment in [item.strip() for item in assignments.split(",") if item.strip()]:
        if "=" not in assignment:
            raise ValueError(f"Invalid glyph edit assignment: {assignment}")
        key, value = assignment.split("=", 1)
        field = key.strip()
        if field not in GLYPH_EDIT_DEFAULTS:
            raise ValueError(f"Unsupported glyph edit field: {field}")
        edit[field] = float(value.strip())
    return edit


def upsert_glyph_edit(session: dict[str, Any], glyph_edit: dict[str, Any]) -> None:
    edits = session.setdefault("glyph_edits", [])
    target = glyph_edit["target"]
    for index, current in enumerate(edits):
        if current.get("target") == target:
            edits[index] = glyph_edit
            return
    edits.append(glyph_edit)


def resolve_glyph_name(font: Any, target: str) -> str | None:
    glyph_order = set(font.getGlyphOrder())
    cleaned = target.strip()
    if not cleaned:
        return None
    if cleaned.startswith("/"):
        glyph_name = cleaned[1:]
        return glyph_name if glyph_name in glyph_order else None
    if cleaned.upper().startswith("U+"):
        glyph_name = (font.getBestCmap() or {}).get(int(cleaned[2:], 16))
        return glyph_name if glyph_name in glyph_order else None
    if len(cleaned) == 1:
        glyph_name = (font.getBestCmap() or {}).get(ord(cleaned))
        return glyph_name if glyph_name in glyph_order else None
    return cleaned if cleaned in glyph_order else None


def build_edit_map(font: Any, session: dict[str, Any]) -> dict[str, dict[str, Any]]:
    edit_map: dict[str, dict[str, Any]] = {}
    for edit in session.get("glyph_edits", []):
        glyph_name = resolve_glyph_name(font, str(edit.get("target", "")))
        if glyph_name is None:
            append_warning(session, f"Glyph edit target could not be resolved: {edit.get('target')}")
            continue
        edit_map[glyph_name] = edit
    return edit_map


def glyph_bounds(glyph_set: Any, glyph_name: str) -> tuple[float, float, float, float]:
    from fontTools.pens.boundsPen import BoundsPen  # type: ignore

    pen = BoundsPen(glyph_set)
    glyph_set[glyph_name].draw(pen)
    if pen.bounds is None:
        return (0.0, 0.0, 0.0, 0.0)
    x_min, y_min, x_max, y_max = pen.bounds
    return (float(x_min), float(y_min), float(x_max), float(y_max))


def instantiate_axes(font: Any, session: dict[str, Any]) -> None:
    if "fvar" not in font:
        return
    from fontTools.varLib.instancer import instantiateVariableFont  # type: ignore

    available = {axis.axisTag for axis in font["fvar"].axes}
    location = {
        axis["tag"]: float(axis["current"])
        for axis in session.get("axes", [])
        if axis["tag"] in available
    }
    if location:
        instantiateVariableFont(font, location, inplace=True)


def apply_font_metrics(font: Any, metrics: dict[str, float]) -> None:
    height_scale = float(metrics["height_scale"])
    baseline_shift = float(metrics["baseline_shift"])
    ascender_shift = float(metrics["ascender_shift"])
    descender_shift = float(metrics["descender_shift"])

    if "hhea" in font:
        font["hhea"].ascent = int(round(font["hhea"].ascent * height_scale + baseline_shift + ascender_shift))
        font["hhea"].descent = int(round(font["hhea"].descent * height_scale + baseline_shift + descender_shift))
    if "OS/2" in font:
        os2 = font["OS/2"]
        os2.sTypoAscender = int(round(os2.sTypoAscender * height_scale + baseline_shift + ascender_shift))
        os2.sTypoDescender = int(round(os2.sTypoDescender * height_scale + baseline_shift + descender_shift))
        os2.usWinAscent = int(round(abs(os2.usWinAscent * height_scale + baseline_shift + ascender_shift)))
        os2.usWinDescent = int(round(abs(os2.usWinDescent * height_scale - baseline_shift - descender_shift)))
        if hasattr(os2, "sxHeight"):
            os2.sxHeight = int(round(os2.sxHeight * height_scale))
        if hasattr(os2, "sCapHeight"):
            os2.sCapHeight = int(round(os2.sCapHeight * height_scale))


def transform_font_binary(source_path: Path, destination: Path, session: dict[str, Any]) -> None:
    from fontTools.misc.transform import Transform  # type: ignore
    from fontTools.pens.transformPen import TransformPen  # type: ignore
    from fontTools.pens.ttGlyphPen import TTGlyphPen  # type: ignore
    from fontTools.ttLib import TTFont  # type: ignore

    font = TTFont(str(source_path))
    instantiate_axes(font, session)

    if "glyf" not in font or "hmtx" not in font:
        raise RuntimeError("Outline editing currently supports TrueType glyf fonts only")

    metrics = session.get("metrics", default_metrics_state())
    width_scale = float(metrics["width_scale"])
    height_scale = float(metrics["height_scale"])
    tracking = float(metrics["tracking"])
    baseline_shift = float(metrics["baseline_shift"])
    edit_map = build_edit_map(font, session)
    glyph_set = font.getGlyphSet()
    glyph_order = list(font.getGlyphOrder())
    hmtx = font["hmtx"].metrics
    global_transform = Transform().translate(0, baseline_shift).scale(width_scale, height_scale)

    for glyph_name in glyph_order:
        edit = edit_map.get(glyph_name)
        transform = global_transform
        if edit is not None:
            x_min, y_min, x_max, y_max = glyph_bounds(glyph_set, glyph_name)
            center_x = (x_min + x_max) / 2.0
            center_y = (y_min + y_max) / 2.0
            transform = (
                transform.translate(float(edit["shift_x"]), float(edit["shift_y"]))
                .translate(center_x, center_y)
                .scale(float(edit["scale_x"]), float(edit["scale_y"]))
                .translate(-center_x, -center_y)
            )

        pen = TTGlyphPen(glyph_set)
        glyph_set[glyph_name].draw(TransformPen(pen, transform))
        font["glyf"][glyph_name] = pen.glyph()

        advance_width, left_side_bearing = hmtx[glyph_name]
        new_advance = int(round(advance_width * width_scale + tracking))
        new_lsb = int(round(left_side_bearing * width_scale))
        if edit is not None:
            new_advance += int(round(float(edit["advance_delta"])))
            new_lsb += int(round(float(edit["shift_x"]) + float(edit["lsb_delta"])))
        hmtx[glyph_name] = (new_advance, new_lsb)

    apply_font_metrics(font, metrics)

    if "hhea" in font:
        font["hhea"].advanceWidthMax = max(advance for advance, _ in hmtx.values())
    font.save(str(destination))


def rebuild_active_fonts(workspace: Path, session: dict[str, Any]) -> None:
    session = normalize_session(session)
    generated_dir = workspace / GENERATED_DIRNAME
    ensure_dir(generated_dir)

    if not has_binary_edits(session):
        session["active_fonts"] = [dict(item) for item in session.get("source_fonts", [])]
        return

    active_fonts: list[dict[str, Any]] = []
    for item in session.get("source_fonts", []):
        source_path = workspace / item["path"]
        suffix = source_path.suffix.lower()
        if suffix not in {".ttf", ".otf"}:
            append_warning(session, f"Binary edits skipped for unsupported font format: {item['filename']}")
            active_fonts.append(dict(item))
            continue

        generated_name = f"edited-{slugify(Path(item['filename']).stem)}{suffix}"
        generated_path = generated_dir / generated_name
        transform_font_binary(source_path, generated_path, session)

        active_item = dict(item)
        active_item["filename"] = generated_name
        active_item["path"] = f"{GENERATED_DIRNAME}/{generated_name}"
        active_item["generated"] = True
        active_fonts.append(active_item)

    session["active_fonts"] = active_fonts


def summarize_family(family: dict[str, Any], rank: int) -> str:
    axes = ", ".join(axis["tag"] for axis in family.get("axes", [])) or "static"
    return f"{rank}. {family['family']} | {family.get('category', 'Unknown')} | axes: {axes}"


def cmd_search(args: argparse.Namespace) -> int:
    results = search_families(args.query, args.limit)
    for index, family in enumerate(results, start=1):
        print(summarize_family(family, index))
    return 0


def choose_best_family(query: str) -> dict[str, Any]:
    results = search_families(query, 5)
    if not results:
        raise RuntimeError(f"No matching family found for {query!r}")
    best = results[0]
    if normalize(best["family"]) != normalize(query):
        log(f"Using closest match: {best['family']}")
    return best


def cmd_init(args: argparse.Namespace) -> int:
    family = choose_best_family(args.query)
    metadata = google_font_metadata(family["family"])
    assets = resolve_repo_assets(metadata)

    workspace = Path(args.workspace).expanduser().resolve() if args.workspace else Path.cwd() / slugify(metadata["family"])
    if workspace.exists() and any(workspace.iterdir()):
        raise RuntimeError(f"Workspace already exists and is not empty: {workspace}")

    source_dir = workspace / "source"
    export_dir = workspace / "export"
    ensure_dir(source_dir)
    ensure_dir(export_dir)

    for item in assets["font_files"]:
        download_file(item["download_url"], source_dir / item["name"])

    for item in assets["license_files"]:
        download_file(item["download_url"], source_dir / item["name"])

    session = build_session(metadata, assets, workspace)
    write_session(workspace, session)
    preview_path = regenerate_preview(workspace, session)

    print(f"Initialized workspace: {workspace}")
    print(f"Preview HTML: {preview_path}")
    print(f"Session file: {workspace / SESSION_FILENAME}")
    if args.serve:
        pid, url, log_path = spawn_preview_server(workspace, args.host, args.port, args.open)
        print(f"Preview server PID: {pid}")
        print(f"Preview URL: {url}")
        print(f"Preview log: {log_path}")
    return 0


def parse_axis_assignments(axis_pairs: list[str]) -> dict[str, float]:
    updates: dict[str, float] = {}
    for raw in axis_pairs:
        if "=" not in raw:
            raise ValueError(f"Invalid axis assignment: {raw}")
        tag, value = raw.split("=", 1)
        updates[tag.strip()] = float(value.strip())
    return updates


def update_axes(session: dict[str, Any], axis_updates: dict[str, float]) -> None:
    axes = {axis["tag"]: axis for axis in session.get("axes", [])}
    for tag, value in axis_updates.items():
        if tag not in axes:
            session.setdefault("warnings", []).append(f"Requested axis {tag} is not available in this family.")
            continue
        axis = axes[tag]
        clamped = min(max(value, axis["min"]), axis["max"])
        axis["current"] = clamped


def dedupe_preserve(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        key = item.strip().lower()
        if not key or key in seen:
            continue
        seen.add(key)
        output.append(item.strip())
    return output


def suggest_names(session: dict[str, Any], count: int) -> list[str]:
    base = session.get("export_family") or session.get("source_family") or "Font"
    family_root = title_case_slug(base)
    source_root = title_case_slug(session.get("source_family", "Font"))
    descriptors = [title_case_slug(item) for item in session.get("descriptors", [])]
    notes = " ".join(session.get("notes", [])).lower()
    tone_words = []
    for keyword in ["editorial", "playful", "friendly", "technical", "mono", "warm", "sharp", "soft", "dramatic", "casual"]:
        if keyword in notes:
            tone_words.append(keyword.capitalize())
    parts = dedupe_preserve(descriptors + tone_words)
    candidates = [
        family_root,
        f"{source_root} Studio",
    ]
    for word in parts:
        candidates.append(f"{word} {source_root}")
        candidates.append(f"{source_root} {word}")
    for noun in NAME_NOUNS:
        candidates.append(f"{source_root} {noun}")
    return dedupe_preserve(candidates)[:count]


def cmd_update(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace).expanduser().resolve()
    session = load_session(workspace)

    if args.reset_binary_edits:
        session["metrics"] = default_metrics_state()
        session["glyph_edits"] = []
    if args.axis:
        update_axes(session, parse_axis_assignments(args.axis))
    if args.metric:
        apply_metric_updates(session, parse_metric_assignments(args.metric))
    if args.glyph_edit:
        for raw in args.glyph_edit:
            upsert_glyph_edit(session, parse_glyph_edit(raw))
    if args.sample_text:
        session["sample_text"] = args.sample_text
    if args.descriptor:
        session["descriptors"] = dedupe_preserve(session.get("descriptors", []) + args.descriptor)
    if args.note:
        session["notes"] = session.get("notes", []) + args.note
    if args.export_family:
        session["export_family"] = args.export_family

    rebuild_active_fonts(workspace, session)
    session["name_suggestions"] = suggest_names(session, 8)
    write_session(workspace, session)
    preview_path = regenerate_preview(workspace, session)

    print(f"Updated session: {workspace}")
    print(f"Preview HTML: {preview_path}")
    return 0


def css_format_for(path: Path) -> str:
    return {
        ".ttf": "truetype",
        ".otf": "opentype",
        ".woff": "woff",
        ".woff2": "woff2",
    }.get(path.suffix.lower(), "truetype")


def postscript_name(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "", text)[:60] or "FontStudio"


def maybe_rename_font_binary(source: Path, destination: Path, family_name: str) -> tuple[bool, str]:
    try:
        from fontTools.ttLib import TTFont  # type: ignore
    except Exception:
        shutil.copy2(source, destination)
        return False, "fontTools not installed; copied source binary without internal rename"

    font = TTFont(str(source))
    name_table = font["name"]
    ps_name = postscript_name(family_name)
    replacements = {
        1: family_name,
        4: family_name,
        6: ps_name,
        16: family_name,
    }

    for record in name_table.names:
        value = replacements.get(record.nameID)
        if value is None:
            continue
        record.string = value.encode(record.getEncoding(), errors="ignore")

    font.save(str(destination))
    return True, "renamed internal font family metadata"


def export_font_binaries(workspace: Path, export_family: str, session: dict[str, Any]) -> tuple[list[dict[str, Any]], list[str]]:
    desktop_dir = workspace / "export" / "desktop"
    web_font_dir = workspace / "export" / "web" / "fonts"
    ensure_dir(desktop_dir)
    ensure_dir(web_font_dir)

    exported: list[dict[str, Any]] = []
    notices: list[str] = []
    export_slug = slugify(export_family)

    export_sources = active_font_items(session)
    for item in export_sources:
        source = workspace / item["path"]
        style_label = Path(item["filename"]).stem
        desktop_name = f"{export_slug}-{slugify(style_label)}{source.suffix.lower()}"
        desktop_path = desktop_dir / desktop_name
        renamed, message = maybe_rename_font_binary(source, desktop_path, export_family)
        notices.append(f"{desktop_name}: {message}")

        web_name = desktop_name
        web_path = web_font_dir / web_name
        shutil.copy2(desktop_path, web_path)
        exported.append(
            {
                "filename": web_name,
                "font_style": item["font_style"],
                "font_weight": item["font_weight"],
                "renamed_internals": renamed,
            }
        )

    return exported, notices


def write_web_stylesheet(
    workspace: Path,
    export_family: str,
    exported_fonts: list[dict[str, Any]],
    session: dict[str, Any],
) -> Path:
    stylesheet = workspace / "export" / "web" / "stylesheet.css"
    axis_lookup = {axis["tag"]: axis for axis in session.get("axes", [])}
    variable_export = len(exported_fonts) == 1 and not has_binary_edits(session)
    rules = []
    for item in exported_fonts:
        path = Path(item["filename"])
        font_weight: str | int = item["font_weight"]
        font_style = item["font_style"]
        if variable_export and "wght" in axis_lookup:
            axis = axis_lookup["wght"]
            font_weight = f"{axis['min']} {axis['max']}"
        if variable_export and "slnt" in axis_lookup:
            axis = axis_lookup["slnt"]
            font_style = f"oblique {axis['min']}deg {axis['max']}deg"
        rules.append(
            textwrap.dedent(
                f"""
                @font-face {{
                  font-family: '{export_family}';
                  src: url('./fonts/{path.name}') format('{css_format_for(path)}');
                  font-style: {font_style};
                  font-weight: {font_weight};
                }}
                """
            ).strip()
        )

    rules.append(
        textwrap.dedent(
            f"""
            .font-type-studio-sample {{
              font-family: '{export_family}', serif;
            }}
            """
        ).strip()
    )
    stylesheet.write_text("\n\n".join(rules) + "\n", encoding="utf-8")
    return stylesheet


def copy_source_license(workspace: Path) -> list[str]:
    source_dir = workspace / "source"
    export_dir = workspace / "export"
    copied = []
    for item in source_dir.iterdir():
        if item.name.lower() in {"ofl.txt", "ufl.txt", "apache.txt", "license.txt"}:
            destination = export_dir / item.name
            shutil.copy2(item, destination)
            copied.append(item.name)
    return copied


def write_manifest(workspace: Path, session: dict[str, Any], export_family: str, notices: list[str], license_files: list[str]) -> Path:
    manifest = {
        "export_family": export_family,
        "source_family": session.get("source_family"),
        "category": session.get("category"),
        "license": session.get("license"),
        "repo_path": session.get("repo_path"),
        "designers": session.get("designers", []),
        "sample_text": session.get("sample_text"),
        "axes": session.get("axes", []),
        "metrics": session.get("metrics", default_metrics_state()),
        "glyph_edits": session.get("glyph_edits", []),
        "descriptors": session.get("descriptors", []),
        "notes": session.get("notes", []),
        "name_suggestions": suggest_names(session, 8),
        "license_files": license_files,
        "export_notices": notices,
        "exported_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    path = workspace / "export" / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return path


def cmd_suggest(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace).expanduser().resolve()
    session = load_session(workspace)
    for suggestion in suggest_names(session, args.count):
        print(f"- {suggestion}")
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace).expanduser().resolve()
    session = load_session(workspace)
    export_family = args.export_family or session.get("export_family") or session.get("source_family")
    if not isinstance(export_family, str) or not export_family.strip():
        raise RuntimeError("Could not determine an export family name")
    session["export_family"] = export_family
    rebuild_active_fonts(workspace, session)
    session["name_suggestions"] = suggest_names(session, 8)
    write_session(workspace, session)

    exported_fonts, notices = export_font_binaries(workspace, export_family, session)
    stylesheet = write_web_stylesheet(workspace, export_family, exported_fonts, session)
    license_files = copy_source_license(workspace)

    specimen = workspace / "export" / "specimen.html"
    render_preview_html(session, workspace, specimen, "./web/fonts", exported_fonts)
    manifest = write_manifest(workspace, session, export_family, notices, license_files)

    print(f"Exported specimen: {specimen}")
    print(f"Exported stylesheet: {stylesheet}")
    print(f"Exported desktop fonts: {workspace / 'export' / 'desktop'}")
    print(f"Exported manifest: {manifest}")
    return 0


def cmd_serve(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace).expanduser().resolve()
    session = load_session(workspace)
    regenerate_preview(workspace, session)

    host = args.host
    port = args.port
    url = preview_server_url(host, port)
    handler = make_preview_handler(workspace)
    preview_server_pid_path(workspace).write_text(f"{os.getpid()}\n", encoding="utf-8")

    with ThreadingHTTPServer((host, port), handler) as server:
        print(f"Serving workspace: {workspace}")
        print(f"Preview URL: {url}")
        print("Live reload watches the workspace and refreshes the browser when files change.")
        if args.open:
            webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("Preview server stopped.")
        finally:
            pid_path = preview_server_pid_path(workspace)
            if pid_path.exists():
                pid_path.unlink()
    return 0


def cmd_stop(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace).expanduser().resolve()
    stopped = stop_preview_server(workspace)
    if stopped:
        print(f"Stopped preview server for {workspace}")
    else:
        print(f"No preview server was recorded for {workspace}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Font Type Studio helper script")
    subparsers = parser.add_subparsers(dest="command", required=True)

    search_parser = subparsers.add_parser("search", help="Search Google Fonts families")
    search_parser.add_argument("--query", required=True)
    search_parser.add_argument("--limit", type=int, default=5)
    search_parser.set_defaults(func=cmd_search)

    init_parser = subparsers.add_parser("init", help="Create a local font workspace")
    init_parser.add_argument("--query", required=True)
    init_parser.add_argument("--workspace")
    init_parser.add_argument("--serve", action="store_true")
    init_parser.add_argument("--host", default="127.0.0.1")
    init_parser.add_argument("--port", type=int, default=4173)
    init_parser.add_argument("--open", action="store_true")
    init_parser.set_defaults(func=cmd_init)

    update_parser = subparsers.add_parser("update", help="Update the session and regenerate preview")
    update_parser.add_argument("--workspace", required=True)
    update_parser.add_argument("--axis", action="append", default=[])
    update_parser.add_argument("--metric", action="append", default=[])
    update_parser.add_argument("--glyph-edit", action="append", default=[])
    update_parser.add_argument("--reset-binary-edits", action="store_true")
    update_parser.add_argument("--sample-text")
    update_parser.add_argument("--descriptor", action="append", default=[])
    update_parser.add_argument("--note", action="append", default=[])
    update_parser.add_argument("--export-family")
    update_parser.set_defaults(func=cmd_update)

    suggest_parser = subparsers.add_parser("suggest", help="Suggest export names from the session")
    suggest_parser.add_argument("--workspace", required=True)
    suggest_parser.add_argument("--count", type=int, default=5)
    suggest_parser.set_defaults(func=cmd_suggest)

    export_parser = subparsers.add_parser("export", help="Export desktop and web packages")
    export_parser.add_argument("--workspace", required=True)
    export_parser.add_argument("--export-family")
    export_parser.set_defaults(func=cmd_export)

    serve_parser = subparsers.add_parser("serve", help="Serve the live preview workspace locally")
    serve_parser.add_argument("--workspace", required=True)
    serve_parser.add_argument("--host", default="127.0.0.1")
    serve_parser.add_argument("--port", type=int, default=4173)
    serve_parser.add_argument("--open", action="store_true")
    serve_parser.set_defaults(func=cmd_serve)

    stop_parser = subparsers.add_parser("stop", help="Stop the local preview server")
    stop_parser.add_argument("--workspace", required=True)
    stop_parser.set_defaults(func=cmd_stop)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except Exception as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
