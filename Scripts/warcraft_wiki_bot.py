import os
import re
import time
import random
import html
from collections import Counter
from typing import Dict, List, Optional, Tuple

import requests

# ==========================================
# 1. CONFIGURATION & POLITE BOT SETTINGS
# ==========================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

MISSING_LOG = "missing_waypoints.log"
OUTPUT_FILE = "scraped_waypoints.txt"
REVIEW_FILE = "wiki_review_needed.txt"

CACHE_DIR = "wiki_cache"
USE_CACHE = True

WIKI_API = "https://warcraft.wiki.gg/api.php"

HEADERS = {
    "User-Agent": "Odysseus-Addon-Data-Compiler/1.3 (Faction vendor waypoint research bot; contact: ithaka68@gmail.com)",
    "Accept": "application/json,text/html,application/xhtml+xml",
}

REQUEST_TIMEOUT = 20
BASE_DELAY = 3.5
JITTER_MIN = 1.0
JITTER_MAX = 2.5
BATCH_BREAK_EVERY = 8
BATCH_BREAK_MIN = 20.0
BATCH_BREAK_MAX = 35.0

MIN_CONFIDENCE_TO_WRITE = 55

# ANSI colors
C_CYAN = '\033[96m'
C_YELLOW = '\033[93m'
C_GREEN = '\033[92m'
C_RED = '\033[91m'
C_PURPLE = '\033[95m'
C_BLUE = '\033[94m'
C_GRAY = '\033[90m'
C_RESET = '\033[0m'

SESSION = requests.Session()
SESSION.headers.update(HEADERS)

# ==========================================
# 2. TERMINAL / LOG HELPERS
# ==========================================
def log(tag: str, message: str, color: str = C_CYAN) -> None:
    print(f"{color}[{tag}] {message}{C_RESET}")

def sleep_with_jitter(index: int) -> None:
    if index > 0 and index % BATCH_BREAK_EVERY == 0:
        pause = random.uniform(BATCH_BREAK_MIN, BATCH_BREAK_MAX)
        log("BOT", f"Taking a polite batch break for {pause:.1f}s...", C_PURPLE)
        time.sleep(pause)
    else:
        pause = BASE_DELAY + random.uniform(JITTER_MIN, JITTER_MAX)
        log("BOT", f"Sleeping for {pause:.1f}s...", C_GRAY)
        time.sleep(pause)

def sleep_between_requests() -> None:
    pause = 1.5 + random.uniform(0.8, 2.0)
    log("BOT", f"Per-request sleep for {pause:.1f}s...", C_GRAY)
    time.sleep(pause)

def fetch_page_html(title: str) -> Optional[str]:
    cached = load_cached_text(title, "html.txt")
    if cached is not None:
        return cached

    data = api_get({
        "action": "parse",
        "page": title,
        "prop": "text",
    })
    if not data:
        return None

    html_text = data.get("parse", {}).get("text", "")
    if html_text is not None:
        save_cached_text(title, "html.txt", html_text)
    return html_text

def ensure_cache_dir() -> None:
    os.makedirs(CACHE_DIR, exist_ok=True)

def safe_cache_name(title: str, suffix: str) -> str:
    safe = re.sub(r'[^A-Za-z0-9._-]+', '_', title).strip('_')
    return os.path.join(CACHE_DIR, f"{safe}.{suffix}")

def load_cached_text(title: str, suffix: str) -> Optional[str]:
    if not USE_CACHE:
        return None
    path = safe_cache_name(title, suffix)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    return None

def save_cached_text(title: str, suffix: str, content: str) -> None:
    ensure_cache_dir()
    path = safe_cache_name(title, suffix)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content or "")

def normalize_zone_name(name: str) -> str:
    name = html.unescape(name or "").strip()
    name = name.replace("’", "'").replace("–", "-")
    name = re.sub(r"\s+", " ", name)
    return name.lower()

def load_map_lookup() -> Dict[str, int]:
    lookup: Dict[str, int] = {}

    if not os.path.exists(MAP_CSV):
        log("WARN", f"Map CSV not found: {MAP_CSV}", C_YELLOW)
        return lookup

    try:
        import csv

        with open(MAP_CSV, "r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, delimiter=';')

            for row in reader:
                map_id_raw = (
                    row.get("ID")
                    or row.get("Id")
                    or row.get("MapID")
                    or row.get("MapId")
                )
                name_raw = (
                    row.get("MapName_lang")
                    or row.get("Name_lang")
                    or row.get("Name")
                    or row.get("name")
                )

                try:
                    map_id = int(float(str(map_id_raw).strip()))
                except Exception:
                    continue

                if not name_raw:
                    continue

                key = normalize_zone_name(name_raw)
                if key and key not in lookup:
                    lookup[key] = map_id

        log("INFO", f"Loaded {len(lookup)} map names from {MAP_CSV}", C_CYAN)
        return lookup

    except Exception as exc:
        log("WARN", f"Failed to load map lookup: {exc}", C_YELLOW)
        return {}

# ==========================================
# 3. INPUT
# ==========================================
def read_missing_factions() -> List[Dict[str, str]]:
    factions: List[Dict[str, str]] = []

    if not os.path.exists(MISSING_LOG):
        log("ERROR", f"Could not find {MISSING_LOG}! Run scraper.py first.", C_RED)
        return factions

    with open(MISSING_LOG, "r", encoding="utf-8") as f:
        for line in f:
            if "," not in line:
                continue
            faction_id, faction_name = line.strip().split(",", 1)
            faction_id = faction_id.strip()
            faction_name = faction_name.strip()
            if faction_id and faction_name:
                factions.append({"id": faction_id, "name": faction_name})

    return factions

# ==========================================
# 4. NORMALIZATION / FORMATTING
# ==========================================
def normalize_name(name: str) -> str:
    name = html.unescape(name or "")
    name = re.sub(r"\s*\(Paragon\)\s*$", "", name, flags=re.IGNORECASE)
    name = name.replace("’", "'").replace("–", "-").strip()
    return name

def slugify_for_compare(text: str) -> str:
    text = normalize_name(text).lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()

def strip_leading_article(text: str) -> str:
    return re.sub(r"^(the|a|an)\s+", "", text.strip(), flags=re.IGNORECASE)

def escape_output_string(value: str) -> str:
    value = (value or "").replace("\\", "\\\\").replace('"', '\\"').strip()
    return value

def safe_float_str(value: float) -> str:
    return f"{value:.2f}".rstrip("0").rstrip(".")

def format_waypoint_line(faction_id: str, map_id: int, x: float, y: float, npc_name: str) -> str:
    """
    EXACT output shape expected by scraper.py:

    2590: {"mapID": 2339, "x": 39.1, "y": 24.2, "npcName": "Auditor Balwurz"},
    """
    return (
        f'{int(faction_id)}: {{"mapID": {int(map_id)}, "x": {safe_float_str(x)}, '
        f'"y": {safe_float_str(y)}, "npcName": "{escape_output_string(npc_name)}"}},'
    )

# ==========================================
# 5. MEDIAWIKI API
# ==========================================
def api_get(params: Dict[str, str], max_retries: int = 5) -> Optional[dict]:
    merged = {
        "format": "json",
        "formatversion": "2",
        "maxlag": "5",
    }
    merged.update(params)

    for attempt in range(1, max_retries + 1):
        try:
            sleep_between_requests()
            response = SESSION.get(WIKI_API, params=merged, timeout=REQUEST_TIMEOUT)

            if response.status_code == 429:
                retry_after = response.headers.get("Retry-After")
                if retry_after:
                    try:
                        wait_s = max(10, int(retry_after))
                    except ValueError:
                        wait_s = 30
                else:
                    wait_s = min(120, 15 * attempt)

                log("BACKOFF", f"429 Too Many Requests. Waiting {wait_s}s before retry {attempt}/{max_retries}...", C_YELLOW)
                time.sleep(wait_s)
                continue

            response.raise_for_status()
            data = response.json()

            error = data.get("error")
            if error and error.get("code") == "maxlag":
                wait_s = min(60, 8 * attempt)
                log("BACKOFF", f"Server reports maxlag. Waiting {wait_s}s before retry {attempt}/{max_retries}...", C_YELLOW)
                time.sleep(wait_s)
                continue

            return data

        except Exception as exc:
            wait_s = min(30, 4 * attempt)
            log("ERROR", f"API request failed (attempt {attempt}/{max_retries}): {exc}", C_RED)
            if attempt < max_retries:
                log("BACKOFF", f"Retrying in {wait_s}s...", C_YELLOW)
                time.sleep(wait_s)

    return None

def search_wiki_pages(query: str, limit: int = 5) -> List[Dict[str, str]]:
    data = api_get({
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srlimit": str(limit),
    })
    if not data:
        return []

    results = []
    for item in data.get("query", {}).get("search", []):
        results.append({
            "title": item.get("title", ""),
            "snippet": html.unescape(item.get("snippet", "")),
        })
    return results

def fetch_page_wikitext(title: str) -> Optional[str]:
    cached = load_cached_text(title, "wikitext.txt")
    if cached is not None:
        return cached

    data = api_get({
        "action": "query",
        "prop": "revisions",
        "titles": title,
        "rvslots": "main",
        "rvprop": "content",
    })
    if not data:
        return None

    pages = data.get("query", {}).get("pages", [])
    if not pages:
        return None

    page = pages[0]
    revisions = page.get("revisions", [])
    if not revisions:
        return None

    content = revisions[0].get("slots", {}).get("main", {}).get("content")
    if content is not None:
        save_cached_text(title, "wikitext.txt", content)
    return content

# ==========================================
# 6. EXTRACTION
# ==========================================
MAP_CSV = r"d:\Wow.export.data\Map.csv"
ZONE_NAME_TO_MAP_ID: Dict[str, int] = {}

ZONE_NAME_OVERRIDES: Dict[str, int] = {
    "thunder totem": 750,
    "thunder totem, highmountain": 750,
    "highmountain": 650,
    "dazar'alor": 1163,
    "port of zandalar, dazar'alor": 1163,
}

_COORD_PATTERNS = [
    ("xyzone", re.compile(
        r"\{\{\s*Coord[s]?\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\|\s*([^|}\n]+)",
        re.IGNORECASE,
    )),

    # {{Coords|45.9|65.9|map=2437}}
    ("xymap", re.compile(
        r"\{\{\s*Coord[s]?\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\|\s*map\s*=\s*([0-9]+)",
        re.IGNORECASE,
    )),

    # {{Coords|map=2437|45.9|65.9}}
    ("mapxy", re.compile(
        r"\{\{\s*Coord[s]?\s*\|\s*map\s*=\s*([0-9]+)\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\|\s*([0-9]{1,3}(?:\.[0-9]+)?)",
        re.IGNORECASE,
    )),

    # {{Coords|map=2437|x=45.9|y=65.9}}
    ("mapkeyxy", re.compile(
        r"\{\{\s*Coord[s]?\s*\|.*?\bmap\s*=\s*([0-9]+).*?\bx\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?).*?\by\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)",
        re.IGNORECASE | re.DOTALL,
    )),

    # {{Location|map=2437|x=45.9|y=65.9}}
    ("location_mapkeyxy", re.compile(
        r"\{\{\s*Location\s*\|.*?\bmap\s*=\s*([0-9]+).*?\bx\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?).*?\by\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)",
        re.IGNORECASE | re.DOTALL,
    )),

    # | x = 45.9 ... | y = 65.9 ... | map = 2437
    ("infobox_xymap", re.compile(
        r"\|\s*x\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*.*?\|\s*y\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*.*?\|\s*map\s*=\s*([0-9]+)",
        re.IGNORECASE | re.DOTALL,
    )),

    # | map = 2437 ... | x = 45.9 ... | y = 65.9
    ("infobox_mapxy", re.compile(
        r"\|\s*map\s*=\s*([0-9]+)\s*.*?\|\s*x\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*.*?\|\s*y\s*=\s*([0-9]{1,3}(?:\.[0-9]+)?)",
        re.IGNORECASE | re.DOTALL,
    )),
]

def extract_zone_bracket_coords(wikitext: str) -> List[Tuple[str, float, float]]:
    found: List[Tuple[str, float, float]] = []
    if not wikitext:
        return found

    pattern = re.compile(
        r"([A-Z][A-Za-z'` .-]+(?:,\s*[A-Z][A-Za-z'` .-]+)?)\s*\[\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*,\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\]"
    )

    seen = set()
    for zone_text, x_str, y_str in pattern.findall(wikitext):
        try:
            x = float(x_str)
            y = float(y_str)
            if not (0.0 <= x <= 100.0 and 0.0 <= y <= 100.0):
                continue

            zone_text = zone_text.strip()
            key = (zone_text.lower(), x, y)
            if key not in seen:
                found.append((zone_text, x, y))
                seen.add(key)
        except (ValueError, TypeError):
            continue

    return found

def extract_quartermaster_names_from_html(html_text: str) -> List[str]:
    names: List[str] = []
    if not html_text:
        return names

    seen = set()

    # Look for infobox rows like:
    # <th>Quartermaster</th><td> ... <a href="/wiki/Ransa_Greyfeather" title="Ransa Greyfeather">
    row_pattern = re.compile(
        r"<th[^>]*>\s*(Quartermaster[s]?|Vendor[s]?|Rewards?\s+vendor[s]?)\s*</th>\s*<td[^>]*>(.*?)</td>",
        re.IGNORECASE | re.DOTALL,
    )

    for _, cell_html in row_pattern.findall(html_text):
        # Prefer anchor title attributes
        for title in re.findall(r'<a[^>]+title="([^"]+)"', cell_html, re.IGNORECASE):
            clean = html.unescape(title).strip()
            key = slugify_for_compare(clean)
            if key and key not in seen:
                names.append(clean)
                seen.add(key)

        # Fallback: href="/wiki/..."
        for href in re.findall(r'href="/wiki/([^"#?]+)"', cell_html, re.IGNORECASE):
            clean = html.unescape(href).replace("_", " ").strip()
            key = slugify_for_compare(clean)
            if key and key not in seen:
                names.append(clean)
                seen.add(key)

    return names[:6]

def extract_coords_from_html(html_text: str) -> List[Tuple[int, float, float]]:
    found: List[Tuple[int, float, float]] = []
    if not html_text:
        return found

    seen = set()

    decoded_html = html.unescape(html_text)

    # data-coords can appear in raw or entity-decoded HTML
    data_coords_pattern = re.compile(
        r'data-coords\s*=\s*"[^"]*?/way\s+([0-9]{1,3}(?:\.[0-9]+)?)\s+([0-9]{1,3}(?:\.[0-9]+)?)"',
        re.IGNORECASE,
    )

    for match in data_coords_pattern.finditer(decoded_html):
        try:
            x = float(match.group(1))
            y = float(match.group(2))
            if not (0.0 <= x <= 100.0 and 0.0 <= y <= 100.0):
                continue

            start = max(0, match.start() - 500)
            context = decoded_html[start:match.start()]

            zone_candidates: List[str] = []

            # Nearby linked page titles are usually the best hints
            for title in re.findall(r'title="([^"]+)"', context, re.IGNORECASE):
                clean = html.unescape(title).strip()
                if clean:
                    zone_candidates.append(clean)

            # Also try a stripped plain-text version
            context_plain = re.sub(r"<[^>]+>", " ", context)
            context_plain = html.unescape(context_plain)
            context_plain = re.sub(r"\s+", " ", context_plain).strip()

            for zone_text in re.findall(
                r'([A-Z][A-Za-z\'` .-]+(?:,\s*[A-Z][A-Za-z\'` .-]+)?)\s*$',
                context_plain
            ):
                zone_candidates.append(zone_text.strip())

            map_id = None
            for zone_text in reversed(zone_candidates):
                map_id = (
                    ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text))
                    or ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text.split(",")[-1].strip()))
                )
                if map_id:
                    break

            if map_id:
                key = (map_id, x, y)
                if key not in seen:
                    found.append((map_id, x, y))
                    seen.add(key)

        except (ValueError, TypeError):
            continue

    # Fallback: plain text forms like "Thunder Totem, Highmountain [38.8, 45.4]"
    plain = re.sub(r"<[^>]+>", " ", decoded_html)
    plain = html.unescape(plain)
    plain = re.sub(r"\s+", " ", plain)

    text_pattern = re.compile(
        r'([A-Z][A-Za-z\'` .-]+(?:,\s*[A-Z][A-Za-z\'` .-]+)?)\s*\[\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*,\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*\]'
    )

    for zone_text, x_str, y_str in text_pattern.findall(plain):
        try:
            x = float(x_str)
            y = float(y_str)
            if not (0.0 <= x <= 100.0 and 0.0 <= y <= 100.0):
                continue

            zone_text = zone_text.strip()
            map_id = (
                ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text))
                or ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text.split(",")[-1].strip()))
            )

            if map_id:
                key = (map_id, x, y)
                if key not in seen:
                    found.append((map_id, x, y))
                    seen.add(key)

        except (ValueError, TypeError):
            continue

    return found

def extract_coords_from_wikitext(wikitext: str) -> List[Tuple[int, float, float]]:
    found: List[Tuple[int, float, float]] = []
    if not wikitext:
        return found

    for pattern_type, pattern in _COORD_PATTERNS:
        for match in pattern.findall(wikitext):
            try:
                if pattern_type == "xymap":
                    x = float(match[0])
                    y = float(match[1])
                    map_id = int(match[2])

                elif pattern_type == "xyzone":
                    x = float(match[0])
                    y = float(match[1])
                    zone_text = html.unescape(match[2]).strip()

                    map_id = (
                        ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text))
                        or ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text.split(",")[-1].strip()))
                    )

                    if not map_id:
                        continue

                elif pattern_type == "mapxy":
                    map_id = int(match[0])
                    x = float(match[1])
                    y = float(match[2])

                elif pattern_type in ("mapkeyxy", "location_mapkeyxy", "infobox_mapxy"):
                    map_id = int(match[0])
                    x = float(match[1])
                    y = float(match[2])

                elif pattern_type == "infobox_xymap":
                    x = float(match[0])
                    y = float(match[1])
                    map_id = int(match[2])

                else:
                    continue

                if 0.0 <= x <= 100.0 and 0.0 <= y <= 100.0 and map_id > 0:
                    found.append((map_id, x, y))

            except (ValueError, TypeError):
                continue

    deduped: List[Tuple[int, float, float]] = []
    seen = set()
    for item in found:
        if item not in seen:
            deduped.append(item)
            seen.add(item)

    # Fallback: parse plain text location forms like "Thunder Totem, Highmountain[38.8, 45.4]"
    for zone_text, x, y in extract_zone_bracket_coords(wikitext):
        map_id = (
            ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text))
            or ZONE_NAME_TO_MAP_ID.get(normalize_zone_name(zone_text.split(",")[-1].strip()))
        )
        if map_id and (map_id, x, y) not in seen:
            deduped.append((map_id, x, y))
            seen.add((map_id, x, y))

    return deduped

def extract_vendorish_names_from_wikitext(wikitext: str) -> List[str]:
    names: List[str] = []
    if not wikitext:
        return names

    patterns = [
        re.compile(r"\|\s*name\s*=\s*([^\n|]+)", re.IGNORECASE),
        re.compile(r"\[\[([^\[\]\n]+)\]\]"),
    ]

    for pattern in patterns:
        for m in pattern.findall(wikitext):
            candidate = html.unescape(m).strip()
            candidate = re.sub(r"\s*\|.*$", "", candidate)
            candidate = re.sub(r"\s*\(.*?\)\s*$", "", candidate).strip()

            if 2 <= len(candidate) <= 80:
                lowered = candidate.lower()
                if any(word in lowered for word in ("quartermaster", "provisioner", "vendor", "emissary", "steward")):
                    names.append(candidate)

    deduped = []
    seen = set()
    for name in names:
        key = slugify_for_compare(name)
        if key and key not in seen:
            deduped.append(name)
            seen.add(key)

    return deduped[:12]

def extract_quartermaster_names_from_wikitext(wikitext: str) -> List[str]:
    names: List[str] = []
    if not wikitext:
        return names

    field_patterns = [
        re.compile(r"\|\s*quartermaster[s]?\s*=\s*(.+)", re.IGNORECASE),
        re.compile(r"\|\s*vendor[s]?\s*=\s*(.+)", re.IGNORECASE),
        re.compile(r"\|\s*rewards?\s+vendor[s]?\s*=\s*(.+)", re.IGNORECASE),
    ]

    seen = set()

    for pattern in field_patterns:
        for match in pattern.findall(wikitext):
            field_value = match.strip()
            field_value = field_value.split("\n", 1)[0].strip()

            # 1) Parse {{NPC||Name|...}} and similar
            for npc_match in re.findall(r"\{\{\s*NPC\s*\|([^}]*)\}\}", field_value, re.IGNORECASE):
                parts = [p.strip() for p in npc_match.split("|")]
                # The NPC name is usually the first non-empty part after optional faction field(s)
                for part in parts:
                    if not part:
                        continue
                    if "=" in part:
                        continue
                    lowered = part.lower()
                    if lowered in {"alliance", "horde", "neutral", "independent", "friendly", "hostile"}:
                        continue
                    key = slugify_for_compare(part)
                    if key and key not in seen:
                        names.append(part)
                        seen.add(key)
                    break

            # 2) Prefer explicit wiki links
            for raw in re.findall(r"\[\[([^\[\]\n]+)\]\]", field_value):
                title = raw.split("|", 1)[0].strip()
                if not title:
                    continue

                lowered = title.lower()
                if ":" in title:
                    namespace = lowered.split(":", 1)[0]
                    if namespace in {
                        "file", "image", "category", "template", "help",
                        "user", "mediawiki", "module", "special"
                    }:
                        continue

                key = slugify_for_compare(title)
                if key and key not in seen:
                    names.append(title)
                    seen.add(key)

            # 3) Fallback: strip templates and try proper-name text
            plain = re.sub(r"\{\{.*?\}\}", " ", field_value)
            plain = re.sub(r"\[\[([^\]|]+)\|([^\]]+)\]\]", r"\1", plain)
            plain = re.sub(r"\[\[([^\]]+)\]\]", r"\1", plain)
            plain = re.sub(r"<.*?>", " ", plain)
            plain = re.sub(r"\s+", " ", plain).strip()

            for candidate in re.findall(r"[A-Z][A-Za-z'`.-]+(?:\s+[A-Z][A-Za-z'`.-]+){0,4}", plain):
                key = slugify_for_compare(candidate)
                if key and key not in seen:
                    names.append(candidate)
                    seen.add(key)

    return names[:6]

def extract_likely_npc_links_from_wikitext(wikitext: str, faction_name: str) -> List[str]:
    if not wikitext:
        return []

    faction_key = slugify_for_compare(faction_name)
    links: List[Tuple[int, str]] = []
    seen = set()

    # Basic wiki links: [[Title]] or [[Title|Label]]
    for raw in re.findall(r"\[\[([^\[\]\n]+)\]\]", wikitext):
        title = raw.split("|", 1)[0].strip()

        if not title:
            continue

        # Skip non-article namespaces / obvious junk
        lowered = title.lower()
        if ":" in title:
            namespace = lowered.split(":", 1)[0]
            if namespace in {
                "file", "image", "category", "template", "help",
                "user", "mediawiki", "module", "special"
            }:
                continue

        key = slugify_for_compare(title)
        if not key or key in seen:
            continue
        seen.add(key)

        score = 0

        npc_words = (
            "quartermaster", "vendor", "provisioner", "steward",
            "emissary", "trader", "supplier"
        )
        generic_bad = ("reputation", "renown", "faction")

        if any(word in lowered for word in npc_words):
            score += 40

        # Prefer links that also mention the faction somewhere nearby by name
        if faction_key and faction_key in key:
            score += 20

        # Mild penalty for generic pages
        if any(word in lowered for word in generic_bad):
            score -= 10

        # Small boost for normal article-looking titles
        if 2 <= len(title) <= 80:
            score += 5

        # Mild boost for likely person/NPC article titles like "Marin Bladewing"
        if re.match(r"^[A-Z][A-Za-z'`.-]+(?:\s+[A-Z][A-Za-z'`.-]+){0,3}$", title):
            score += 10

        if score > 0:
            links.append((score, title))

    links.sort(key=lambda x: x[0], reverse=True)
    return [title for _, title in links[:4]]

def page_url(title: str) -> str:
    return f"https://warcraft.wiki.gg/wiki/{title.replace(' ', '_')}"

# ==========================================
# 7. SCORING
# ==========================================
def classify_page_title(title: str) -> str:
    lowered = title.lower()

    npc_words = (
        "quartermaster",
        "vendor",
        "provisioner",
        "steward",
        "emissary",
        "trader",
        "supplier",
    )

    generic_words = (
        "reputation",
        "renown",
        "faction",
        "the war within reputations",
        "dragonflight reputations",
    )

    if any(word in lowered for word in npc_words):
        return "npc"

    if any(word in lowered for word in generic_words):
        return "generic"

    return "neutral"

def score_candidate(
    faction_name: str,
    page_title: str,
    snippet: str,
    wikitext: str,
    coords: List[Tuple[int, float, float]],
    vendor_names: List[str],
) -> Tuple[int, List[str]]:
    score = 0
    reasons: List[str] = []

    faction_key = slugify_for_compare(faction_name)
    faction_key_no_article = slugify_for_compare(strip_leading_article(faction_name))
    title_key = slugify_for_compare(page_title)
    snippet_key = slugify_for_compare(snippet)
    wiki_key = slugify_for_compare(wikitext[:4000])

    page_class = classify_page_title(page_title)

    if (
        (faction_key and faction_key in title_key)
        or (faction_key_no_article and faction_key_no_article in title_key)
    ):
        score += 25
        reasons.append("title matches faction")

    if faction_key and faction_key in snippet_key:
        score += 15
        reasons.append("snippet mentions faction")

    if faction_key and faction_key in wiki_key:
        score += 15
        reasons.append("page text mentions faction")

    if coords:
        score += 25
        reasons.append("coordinates found")

    vendor_words = ("quartermaster", "vendor", "provisioner", "emissary", "steward", "rewards")
    if any(word in wikitext.lower() for word in vendor_words):
        score += 10
        reasons.append("vendor-like page text")

    if vendor_names:
        score += 8
        reasons.append("possible vendor name found")

    if re.search(r"\|\s*Quartermaster[s]?\s*=", wikitext, re.IGNORECASE):
        score += 18
        reasons.append("explicit quartermaster field")
    elif re.search(r"\|\s*Vendor[s]?\s*=", wikitext, re.IGNORECASE):
        score += 10
        reasons.append("explicit vendor field")

    if page_class == "npc":
        score += 15
        reasons.append("npc/vendor page preferred")
    elif page_class == "generic":
        score -= 10
        reasons.append("generic faction/reputation page penalty")

    if page_class == "npc" and coords:
        score += 10
        reasons.append("npc page with coordinates")

    if page_class == "generic" and not coords:
        score -= 10
        reasons.append("generic page without coordinates")

    if not coords:
        score -= 25
        reasons.append("no coordinates penalty")

    return score, reasons

# ==========================================
# 8. SEARCH PLAN
# ==========================================
def build_search_queries(faction_name: str) -> List[str]:
    cleaned = normalize_name(faction_name)
    return [
        f'"{cleaned}" quartermaster',
        f'"{cleaned}" vendor',
        f'"{cleaned}"',
    ]

def gather_candidate_pages(faction_name: str) -> List[Dict[str, str]]:
    candidates: List[Dict[str, str]] = []
    seen_titles = set()

    for query in build_search_queries(faction_name):
        for item in search_wiki_pages(query, limit=3):
            title = item.get("title", "").strip()
            if not title:
                continue
            key = title.lower()
            if key in seen_titles:
                continue
            seen_titles.add(key)
            candidates.append(item)

    return candidates[:3]

# ==========================================
# 9. SCRAPE ONE FACTION
# ==========================================
def evaluate_page_candidate(
    faction_name: str,
    title: str,
    snippet: str = "",
    linked_from_title: str = "",
) -> Optional[Dict[str, object]]:
    log("PAGE", f"Evaluating: {title}", C_BLUE)

    wikitext = fetch_page_wikitext(title)
    if not wikitext:
        return None

    html_text = fetch_page_html(title) or ""

    coords = extract_coords_from_wikitext(wikitext)

    html_coords = extract_coords_from_html(html_text)
    for item in html_coords:
        if item not in coords:
            coords.append(item)

    vendor_names = extract_vendorish_names_from_wikitext(wikitext)
    score, reasons = score_candidate(faction_name, title, snippet, wikitext, coords, vendor_names)

    if linked_from_title:
        score += 12
        reasons.append(f"linked from {linked_from_title}")

        if classify_page_title(title) == "npc":
            score += 10
            reasons.append("linked npc/vendor page")

    return {
        "title": title,
        "score": score,
        "reasons": reasons,
        "coords": coords,
        "vendor_names": vendor_names,
        "url": page_url(title),
        "wikitext": wikitext,
        "html_text": html_text,
        "linked_from_title": linked_from_title,
    }

def scrape_waypoint_from_wiki(faction_id: str, faction_name: str) -> Dict[str, object]:
    log("BOT", f"Searching Warcraft Wiki for {faction_name} (ID: {faction_id})...", C_YELLOW)

    pages = gather_candidate_pages(faction_name)
    if not pages:
        return {
            "ok": False,
            "reason": "no search results",
            "reason_group": "no search results",
            "best_score": 0,
            "best_title": "",
            "review": f"{faction_id},{faction_name} -> no wiki results",
        }

    evaluated_pages: List[Dict[str, object]] = []

    # First pass: evaluate direct search-result pages
    for page in pages:
        title = page["title"]
        snippet = page.get("snippet", "")

        result = evaluate_page_candidate(
            faction_name=faction_name,
            title=title,
            snippet=snippet,
            linked_from_title="",
        )
        if result:
            evaluated_pages.append(result)

    if not evaluated_pages:
        return {
            "ok": False,
            "reason": "no page content",
            "reason_group": "no readable page",
            "best_score": 0,
            "best_title": "",
            "review": f"{faction_id},{faction_name} -> no readable wiki page",
        }

    # Sort current best direct pages
    evaluated_pages.sort(key=lambda x: int(x["score"]), reverse=True)
    best_direct = evaluated_pages[0]

        # Second pass: if direct pages had no coords, follow explicit quartermaster/vendor
    # names only from the single best direct page.
    if not best_direct["coords"]:
        linked_titles_seen = set()

        base_page = best_direct
        wikitext = str(base_page.get("wikitext", ""))
        base_title = str(base_page["title"])
        html_text = str(base_page.get("html_text", ""))

        preferred_titles = extract_quartermaster_names_from_html(html_text)
        if not preferred_titles:
            preferred_titles = extract_quartermaster_names_from_wikitext(wikitext)

        log("DEBUG", f"{base_title} preferred_titles={preferred_titles}", C_YELLOW)

        filtered_candidate_titles: List[str] = []

        for title in preferred_titles:
            if title not in filtered_candidate_titles:
                filtered_candidate_titles.append(title)

        # Only use generic fallback links if we found no explicit quartermaster/vendor titles.
        if not filtered_candidate_titles:
            fallback_titles = extract_likely_npc_links_from_wikitext(wikitext, faction_name)
            faction_key = slugify_for_compare(faction_name)
            faction_key_no_article = slugify_for_compare(strip_leading_article(faction_name))

            for title in fallback_titles:
                title_key = slugify_for_compare(title)
                if (
                    (faction_key and faction_key in title_key)
                    or (faction_key_no_article and faction_key_no_article in title_key)
                ):
                    if title not in filtered_candidate_titles:
                        filtered_candidate_titles.append(title)

        for linked_title in filtered_candidate_titles[:4]:
            key = linked_title.lower()
            if key in linked_titles_seen:
                continue
            linked_titles_seen.add(key)

            result = evaluate_page_candidate(
                faction_name=faction_name,
                title=linked_title,
                snippet="",
                linked_from_title=base_title,
            )
            if result:
                if linked_title in preferred_titles:
                    result["score"] = int(result["score"]) + 35
                    result["reasons"].append("followed explicit quartermaster/vendor field")

                evaluated_pages.append(result)

        evaluated_pages.sort(key=lambda x: int(x["score"]), reverse=True)
        
    # Prefer any page with coordinates over a higher-scoring page without coordinates.
    pages_with_coords = [p for p in evaluated_pages if p.get("coords")]
    if pages_with_coords:
        pages_with_coords.sort(key=lambda x: int(x["score"]), reverse=True)
        best = pages_with_coords[0]
    else:
        evaluated_pages.sort(key=lambda x: int(x["score"]), reverse=True)
        best = evaluated_pages[0]

    if best["score"] < MIN_CONFIDENCE_TO_WRITE or not best["coords"]:
        reason_text = "; ".join(best["reasons"]) if best["reasons"] else "no details"

    if not best["coords"]:
        reason_group = "no coordinates after npc-link follow"
        reason = f"no coordinates ({best['score']})"
    else:
        reason_group = "low confidence"
        reason = f"low confidence ({best['score']})"

    review_note = reason_text
    if str(best["title"]).strip().lower() != str(faction_name).strip().lower():
        review_note += " | npc resolved but no fixed coordinates"

    return {
        "ok": False,
        "reason": reason,
        "reason_group": reason_group,
        "best_score": best["score"],
        "best_title": best["title"],
        "review": (
            f"{faction_id},{faction_name} -> {best['title']} | "
            f"score={best['score']} | {review_note} | {best['url']}"
        ),
    }

    map_id, x, y = best["coords"][0]

    npc_name = str(best["title"])

    vendor_names = best.get("vendor_names") or []
    if vendor_names:
        candidate = str(vendor_names[0]).strip()
        if re.match(r"^[A-Z][A-Za-z'`.-]+(?:\s+[A-Z][A-Za-z'`.-]+){0,3}$", candidate):
            npc_name = candidate

    line = format_waypoint_line(faction_id, map_id, x, y, npc_name)

    log(
        "FOUND",
        f"{faction_name}: {line} (score {best['score']})",
        C_GREEN,
    )

    return {
        "ok": True,
        "line": line,
        "faction_id": faction_id,
        "faction_name": faction_name,
        "source_title": best["title"],
        "source_url": best["url"],
        "score": best["score"],
    }

def print_final_report(
    total_count: int,
    success_count: int,
    review_count: int,
    success_scores: List[int],
    miss_scores: List[int],
    miss_reasons: Counter,
    top_miss_candidates: List[Tuple[str, int, str]],
) -> None:
    print()
    log("SUCCESS", "Wiki scraping complete!", C_GREEN)
    log("RESULT", f"Processed: {total_count}", C_YELLOW)
    log("RESULT", f"Confident hits: {success_count}", C_YELLOW)
    log("RESULT", f"Needs manual review: {review_count}", C_YELLOW)

    hit_rate = (success_count / total_count * 100.0) if total_count > 0 else 0.0
    log("RESULT", f"Hit rate: {hit_rate:.1f}%", C_YELLOW)

    if success_scores:
        avg_hit = sum(success_scores) / len(success_scores)
        best_hit = max(success_scores)
        worst_hit = min(success_scores)
        log("STATS", f"Hit scores -> avg {avg_hit:.1f} | min {worst_hit} | max {best_hit}", C_GREEN)

    if miss_scores:
        avg_miss = sum(miss_scores) / len(miss_scores)
        best_miss = max(miss_scores)
        worst_miss = min(miss_scores)
        log("STATS", f"Miss scores -> avg {avg_miss:.1f} | min {worst_miss} | max {best_miss}", C_RED)

    if miss_reasons:
        print(f"\n{C_PURPLE}=== Miss Breakdown ==={C_RESET}")
        for reason, count in miss_reasons.most_common():
            print(f"{C_RED}- {reason}: {count}{C_RESET}")

    if top_miss_candidates:
        print(f"\n{C_PURPLE}=== Top Review Targets ==={C_RESET}")
        for faction_name, score, page_title in sorted(top_miss_candidates, key=lambda x: x[1], reverse=True)[:10]:
            print(f"{C_YELLOW}- {faction_name}: score {score} | {page_title}{C_RESET}")

    log("INFO", f"Check {OUTPUT_FILE} and {REVIEW_FILE}.", C_CYAN)

# ==========================================
# 10. MAIN
# ==========================================
def main() -> None:
    os.system("")  # helps enable ANSI colors on some terminals

    print(f"{C_CYAN}=== Odysseus Warcraft Wiki Scraper Bot ==={C_RESET}\n")

    global ZONE_NAME_TO_MAP_ID
    ZONE_NAME_TO_MAP_ID = load_map_lookup()
    ZONE_NAME_TO_MAP_ID.update(ZONE_NAME_OVERRIDES)

    log("INFO", f"Zone lookup size after overrides: {len(ZONE_NAME_TO_MAP_ID)}", C_CYAN)
    log("INFO", f"Thunder Totem mapID: {ZONE_NAME_TO_MAP_ID.get('thunder totem')}", C_CYAN)
    log("INFO", f"Highmountain mapID: {ZONE_NAME_TO_MAP_ID.get('highmountain')}", C_CYAN)

    queue = read_missing_factions()
    if not queue:
        return

    log("INFO", f"Loaded {len(queue)} factions from {MISSING_LOG}.", C_CYAN)
    log("INFO", "Mode: Warcraft Wiki API + strict scraper.py-compatible output.", C_CYAN)
    log("INFO", f"Output: {OUTPUT_FILE}", C_CYAN)
    log("INFO", f"Manual review list: {REVIEW_FILE}\n", C_CYAN)

    success_count = 0
    review_count = 0
    success_scores: List[int] = []
    miss_scores: List[int] = []
    miss_reasons: Counter = Counter()
    top_miss_candidates: List[Tuple[str, int, str]] = []

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out_f, \
         open(REVIEW_FILE, "w", encoding="utf-8") as review_f:

        out_f.write("# Automatically scraped waypoints from Warcraft Wiki\n")
        out_f.write("# Format is scraper.py-compatible. Do not edit spacing inside the dict keys.\n\n")

        review_f.write("# Items needing manual review\n\n")

        for index, faction in enumerate(queue, start=1):
            print(f"{C_PURPLE}--- Faction {index} / {len(queue)} ---{C_RESET}")

            result = scrape_waypoint_from_wiki(faction["id"], faction["name"])

            if result.get("ok"):
                out_f.write(result["line"] + "\n")
                out_f.write(
                    f"# Source: {result['source_title']} | score={result['score']} | {result['source_url']}\n"
                )
                out_f.flush()
                success_count += 1
                success_scores.append(int(result["score"]))
            else:
                review_f.write(result["review"] + "\n")
                review_f.flush()
                review_count += 1
                log("MISS", f"{faction['name']} -> {result['reason']}", C_RED)
                miss_reasons[result.get("reason_group", "other")] += 1
                miss_scores.append(int(result.get("best_score", 0)))
                top_miss_candidates.append((
                    faction["name"],
                    int(result.get("best_score", 0)),
                    str(result.get("best_title", "")),
                ))

            sleep_with_jitter(index)

    print_final_report(
        total_count=len(queue),
        success_count=success_count,
        review_count=review_count,
        success_scores=success_scores,
        miss_scores=miss_scores,
        miss_reasons=miss_reasons,
        top_miss_candidates=top_miss_candidates,
    )

if __name__ == "__main__":
    main()