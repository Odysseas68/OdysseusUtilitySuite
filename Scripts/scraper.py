import csv
import os
import sys
import logging
import re
import ast
from typing import Dict, Any, Optional

# ==========================================
# 0. LOGGING SETUP
# ==========================================
def setup_missing_waypoints_logger():
    """Write ONLY unresolved factions to missing_waypoints.log."""
    logging.basicConfig(
        level=logging.WARNING,
        format="%(message)s",
        handlers=[
            logging.FileHandler(MISSING_LOG, mode="w", encoding="utf-8")
        ]
    )

def log_missing_waypoint(faction_info: str):
    logging.warning(faction_info)

# ==========================================
# 1. CONFIGURATION & FILE PATHS
# ==========================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# CSV INPUTS
PARAGON_CSV = r"d:\Wow.export.data\ParagonReputation.csv"
FACTION_CSV = r"d:\Wow.export.data\Faction.csv"

# GENERATED OUTPUT
OUTPUT_FILE = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "xpbar_data.lua"))

# LOGS / AUXILIARY INPUTS
MISSING_LOG = "missing_waypoints.log"
SCRAPED_WAYPOINTS_FILE = "scraped_waypoints.txt"

os.system("")

# ANSI colors
C_CYAN = '\033[96m'
C_GREEN = '\033[92m'
C_YELLOW = '\033[93m'
C_RED = '\033[91m'
C_PURPLE = '\033[95m'
C_GRAY = '\033[90m'
C_RESET = '\033[0m'

SCRAPE_ALL = False

TARGET_FACTIONS = {
    # === MIDNIGHT ===
    2710, 2696, 2704, 2699, 2770, 2764,

    # === THE WAR WITHIN ===
    2590, 2594, 2570, 2563, 2600, 2601, 2605,

    # === DRAGONFLIGHT ===
    2503, 2507, 2510, 2511, 2564, 2574, 2544, 2526, 2550, 2532, 2517, 2518,
}

FORBIDDEN_WORDS = (
    "UNUSED", "REUSE", "DO NOT USE", "DEPRECATED", "TRASH", "QA ", "TEST"
)

# Manual curated waypoints are still the highest-trust source.
CUSTOM_WAYPOINTS: Dict[int, Dict[str, Any]] = {
    2710: {"mapID": 2395, "x": 43.4, "y": 47.4, "npcName": "Caeris Fairdawn"},
    2696: {"mapID": 2437, "x": 45.9, "y": 65.9, "npcName": "Magovu"},
    2704: {"mapID": 2413, "x": 51.0, "y": 50.8, "npcName": "Naynar"},
    2699: {"mapID": 2405, "x": 52.5, "y": 72.9, "npcName": "Void Researcher Anomander"},
    2770: {"mapID": 2444, "x": 39.3, "y": 80.9, "npcName": "Thraxadar"},
    2590: {"mapID": 2339, "x": 39.1, "y": 24.2, "npcName": "Auditor Balwurz"},
    2594: {"mapID": 2214, "x": 47.3, "y": 32.9, "npcName": "Waxmonger Squick"},
    2570: {"mapID": 2215, "x": 41.3, "y": 53.1, "npcName": "Auralia Steelstrike"},
    2563: {"mapID": 2255, "x": 55.5, "y": 41.2, "npcName": "Lady Vinazian"},
    2510: {"mapID": 2112, "x": 58.9, "y": 38.3, "npcName": "Tattukiaka"},
    2511: {"mapID": 2023, "x": 64.1, "y": 41.0, "npcName": "Quartermaster Huseng"},
    2507: {"mapID": 2112, "x": 31.0, "y": 61.8, "npcName": "Sorotis"},
    2503: {"mapID": 2025, "x": 47.1, "y": 82.6, "npcName": "Cataloger Jakes"},
    2564: {"mapID": 2133, "x": 55.7, "y": 55.5, "npcName": "Ponzo"},
    2574: {"mapID": 2200, "x": 49.8, "y": 62.2, "npcName": "Pipsee"},
    2544: {"mapID": 2022, "x": 35.6, "y": 59.2, "npcName": "Rabul"},
    2526: {"mapID": 2024, "x": 65.6, "y": 36.0, "npcName": "Sonovo"},
    2550: {"mapID": 2025, "x": 61.5, "y": 50.9, "npcName": "Soridormi"},
}

# ==========================================
# 2. UTILITY HELPERS
# ==========================================
def print_log(tag: str, msg: str, color: str = C_CYAN):
    print(f"{color}[{tag}] {msg}{C_RESET}")

def escape_lua_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')

def clean_name(value: str) -> str:
    return (value or "").strip()

def get_first(row: dict, *keys, default=""):
    for key in keys:
        if key in row and row[key] not in (None, ""):
            return row[key]
    return default

def parse_int(value: Any, default: int = 0) -> int:
    try:
        return int(float(str(value).strip()))
    except (ValueError, TypeError):
        return default

def lua_num(value: float) -> str:
    return f"{float(value):.2f}".rstrip("0").rstrip(".")

# ==========================================
# 3. OPTIONAL SCRAPED WAYPOINT IMPORT
# ==========================================
def load_scraped_waypoints() -> int:
    """
    Reads scraped_waypoints.txt and merges entries into CUSTOM_WAYPOINTS
    only if the factionID does not already exist in CUSTOM_WAYPOINTS.

    Accepts lines like:
        2590: {"mapID": 2339, "x": 39.1, "y": 24.2, "npcName": "Auditor Balwurz"},
        2590: {'mapID': 2339, 'x': 39.1, 'y': 24.2, 'npcName': 'Auditor Balwurz'},
        2590: {"mapID": 2339, "x": 39.1, "y": 24.2, "npcName": "Auditor Balwurz"}, # comment
    """
    if not os.path.exists(SCRAPED_WAYPOINTS_FILE):
        print_log("INFO", f"No {SCRAPED_WAYPOINTS_FILE} found. Skipping scraped imports.", C_GRAY)
        return 0

    imported = 0
    ignored_existing = 0
    ignored_invalid = 0

    line_pattern = re.compile(r"^\s*(\d+)\s*:\s*(\{.*\})\s*,?\s*$")

    with open(SCRAPED_WAYPOINTS_FILE, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()

            if not line or line.startswith("#"):
                continue

            # Remove trailing inline comments.
            line = re.sub(r"\s+#.*$", "", line).strip()

            match = line_pattern.match(line)
            if not match:
                ignored_invalid += 1
                continue

            faction_id = int(match.group(1))
            dict_text = match.group(2)

            try:
                data = ast.literal_eval(dict_text)
            except Exception:
                ignored_invalid += 1
                continue

            if not isinstance(data, dict):
                ignored_invalid += 1
                continue

            try:
                map_id = int(data["mapID"])
                x = float(data["x"])
                y = float(data["y"])
                npc_name = str(data.get("npcName", "")).strip()
            except (KeyError, ValueError, TypeError):
                ignored_invalid += 1
                continue

            if map_id <= 0 or not (0.0 <= x <= 100.0) or not (0.0 <= y <= 100.0):
                ignored_invalid += 1
                continue

            if faction_id in CUSTOM_WAYPOINTS:
                ignored_existing += 1
                continue

            CUSTOM_WAYPOINTS[faction_id] = {
                "mapID": map_id,
                "x": x,
                "y": y,
                "npcName": npc_name or "Unknown NPC",
                "source": "scraped",
            }
            imported += 1

    print_log("INFO", f"Imported {imported} scraped waypoint(s) from {SCRAPED_WAYPOINTS_FILE}.", C_GREEN)
    if ignored_existing > 0:
        print_log("INFO", f"Skipped {ignored_existing} scraped waypoint(s) because CUSTOM_WAYPOINTS already had them.", C_YELLOW)
    if ignored_invalid > 0:
        print_log("WARN", f"Ignored {ignored_invalid} invalid line(s) in {SCRAPED_WAYPOINTS_FILE}.", C_YELLOW)

    return imported

# ==========================================
# 4. PARAGON CSV PARSER
# ==========================================
def parse_paragon_data() -> Dict[int, Dict[str, Any]]:
    print_log("INFO", f"Reading Paragon CSV: {PARAGON_CSV}")
    paragon_data: Dict[int, Dict[str, Any]] = {}

    try:
        with open(PARAGON_CSV, "r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, delimiter=';')

            for row in reader:
                faction_id = parse_int(get_first(row, "FactionID", "FactionId", "ID", "Id"))
                if faction_id <= 0:
                    continue

                threshold = parse_int(get_first(row, "LevelThreshold", "Threshold", "levelThreshold", "threshold"), 10000)
                quest_id = parse_int(get_first(row, "QuestID", "QuestId", "questID", "questId"))

                paragon_data[faction_id] = {
                    "threshold": threshold,
                    "questID": quest_id,
                }

        print_log("SUCCESS", f"Processed {len(paragon_data)} paragon entries.", C_GREEN)
        return paragon_data

    except Exception as e:
        print_log("ERROR", f"Paragon CSV failed: {e}", C_RED)
        sys.exit(1)

# ==========================================
# 5. FACTION CSV PARSER
# ==========================================
def parse_faction_data(paragon_data: Dict[int, Dict[str, Any]]) -> Dict[int, Dict[str, Any]]:
    print_log("INFO", f"Reading Faction CSV: {FACTION_CSV}")

    faction_data: Dict[int, Dict[str, Any]] = {}

    try:
        with open(FACTION_CSV, "r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, delimiter=';')

            for row in reader:
                fid = parse_int(get_first(row, "ID", "Id", "FactionID", "FactionId"))
                if fid <= 0:
                    continue

                name = clean_name(get_first(row, "Name_lang", "Name", "name"))
                linked_paragon_id = parse_int(get_first(row, "ParagonFactionID", "ParagonFactionId", "ParagonID", "ParagonId"), 0)

                upper_name = name.upper()
                is_valid_name = True
                for word in FORBIDDEN_WORDS:
                    if word in upper_name:
                        is_valid_name = False
                        break

                should_keep = (
                    name != ""
                    and is_valid_name
                    and (
                        SCRAPE_ALL
                        or fid in TARGET_FACTIONS
                        or fid in paragon_data
                        or linked_paragon_id > 0
                    )
                )

                if not should_keep:
                    continue

                p_info: Optional[Dict[str, Any]] = None

                if linked_paragon_id > 0 and linked_paragon_id in paragon_data:
                    p_info = dict(paragon_data[linked_paragon_id])
                    p_info["paragonFactionID"] = linked_paragon_id
                elif fid in paragon_data:
                    p_info = dict(paragon_data[fid])
                    p_info["paragonFactionID"] = fid

                faction_data[fid] = {
                    "name": name,
                    "paragon": p_info,
                    "linked_p_id": linked_paragon_id,
                }

        print_log("SUCCESS", f"Processed {len(faction_data)} valid factions.", C_GREEN)
        return faction_data

    except Exception as e:
        print_log("ERROR", f"Faction CSV failed: {e}", C_RED)
        sys.exit(1)

# ==========================================
# 6. WAYPOINT LINKING
# ==========================================
def link_waypoints(faction_data: Dict[int, Dict[str, Any]]):
    links_made = 0

    for fid, data in faction_data.items():
        if fid in CUSTOM_WAYPOINTS:
            linked_pid = data.get("linked_p_id", 0)
            if linked_pid > 0 and linked_pid not in CUSTOM_WAYPOINTS:
                CUSTOM_WAYPOINTS[linked_pid] = dict(CUSTOM_WAYPOINTS[fid])
                print_log("LINK", f"Auto-copied {data['name']} coordinates to Paragon ID {linked_pid}!", C_PURPLE)
                links_made += 1

    if links_made == 0:
        print_log("INFO", "No new Paragon waypoint links needed.", C_GRAY)

# ==========================================
# 7. LUA WRITER
# ==========================================
def is_pure_paragon_row(fid: int, data: Dict[str, Any]) -> bool:
    """
    True when this row is itself the paragon faction row, not the base faction row.
    """
    return bool(data.get("paragon")) and data["paragon"]["paragonFactionID"] == fid

def write_lua_file(faction_data: Dict[int, Dict[str, Any]]):
    print_log("INFO", f"\nCompiling {OUTPUT_FILE}...")
    missing_count = 0
    logged_missing_keys = set()

    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write('-- ==========================================\n')
            f.write('-- ODYSSEUS AUTO-GENERATED FACTION DATABASE\n')
            f.write('-- ==========================================\n')
            f.write('local addonName, OUS = ...\n\n')
            f.write('OUS.FactionData = {\n')

            for fid, data in sorted(faction_data.items()):
                display_name = data["name"] or f"Paragon Faction {fid}"
                safe_name = escape_lua_string(display_name)

                f.write(f'    [{fid}] = {{\n')
                f.write(f'        name = "{safe_name}",\n')

                if data["paragon"]:
                    f.write('        isParagon = true,\n')
                    f.write(f'        paragonFactionID = {data["paragon"]["paragonFactionID"]},\n')
                    f.write(f'        paragonThreshold = {data["paragon"]["threshold"]},\n')
                    f.write(f'        paragonQuestID = {data["paragon"]["questID"]},\n')
                else:
                    f.write('        isParagon = false,\n')

                if fid in CUSTOM_WAYPOINTS:
                    wp = CUSTOM_WAYPOINTS[fid]
                    npc_name = escape_lua_string(str(wp.get("npcName", "Unknown NPC")))
                    f.write(
                        f'        rewardNPC = {{ mapID = {wp["mapID"]}, x = {lua_num(wp["x"])}, y = {lua_num(wp["y"])}, npcName = "{npc_name}" }},\n'
                    )
                else:
                    # Only log one research entry per logical faction, and prefer the base faction.
                    if not is_pure_paragon_row(fid, data):
                        missing_key = clean_name(display_name).lower()
                        if missing_key and missing_key not in logged_missing_keys:
                            log_missing_waypoint(f"{fid},{display_name}")
                            logged_missing_keys.add(missing_key)
                            missing_count += 1

                    f.write('        rewardNPC = { mapID = 0, x = 0.0, y = 0.0, npcName = "" },\n')

                f.write('    },\n')

            f.write('}\n')

        if missing_count > 0:
            print_log("INFO", f"Logged {missing_count} factions missing waypoints to '{MISSING_LOG}'", C_YELLOW)

        print(f"\n{C_GREEN}[SUCCESS] {len(faction_data)} factions successfully compiled to {OUTPUT_FILE}!{C_RESET}")

    except Exception as e:
        print_log("ERROR", f"Failed to write Lua file: {e}", C_RED)
        sys.exit(1)

# ==========================================
# 8. MAIN EXECUTION
# ==========================================
def main():
    print(f"{C_CYAN}=================================================={C_RESET}")
    print(f"{C_PURPLE}   Odysseus Relational Faction Compiler{C_RESET}")
    print(f"{C_CYAN}=================================================={C_RESET}\n")

    setup_missing_waypoints_logger()

    if not os.path.exists(FACTION_CSV) or not os.path.exists(PARAGON_CSV):
        print_log("ERROR", "Missing CSV files! Ensure Faction.csv and ParagonReputation.csv are present.", C_RED)
        input("Press Enter to exit...")
        sys.exit(1)

    load_scraped_waypoints()

    paragon_data = parse_paragon_data()
    faction_data = parse_faction_data(paragon_data)
    link_waypoints(faction_data)
    write_lua_file(faction_data)

    input("Press Enter to exit...")

if __name__ == "__main__":
    main()