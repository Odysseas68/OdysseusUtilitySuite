import csv
import os
import sys
import logging
from typing import Dict, Any, Optional

# ==========================================
# 0. LOGGING SETUP
# ==========================================
def setup_missing_waypoints_logger():
    """Sets up the logger to write ONLY to the missing_waypoints.log file."""
    logging.basicConfig(
        level=logging.WARNING,
        format='%(message)s',
        handlers=[
            logging.FileHandler('missing_waypoints.log', mode='w', encoding='utf-8')
        ]
    )

def log_missing_waypoint(faction_info: str):
    """Custom helper function to log factions that lack coordinates."""
    logging.warning(faction_info)

# ==========================================
# 1. CONFIGURATION & CONSTANTS & FILE PATHS
# ==========================================
# SCRIPT_DIR is now your new sub-directory (/OdysseusUtilitySuite/Tools/)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# INPUTS: These were already absolute paths on your D: drive, so they stay the same!
PARAGON_CSV = r"d:\Wow.export.data\ParagonReputation.csv"
FACTION_CSV = r"d:\Wow.export.data\Faction.csv"

# OUTPUTS: We tell Python to save the Lua file ONE FOLDER UP (..) into the main addon root
# OUTPUT_FILE = os.path.join(SCRIPT_DIR, '..', 'xpbar_data.lua')
# Optional: This just makes the path look pretty in the terminal!
OUTPUT_FILE = os.path.abspath(os.path.join(SCRIPT_DIR, '..', 'xpbar_data.lua'))

# LOGS: We keep these inside your new Tools folder to keep the addon root perfectly clean!
MISSING_LOG = "missing_waypoints.log"

os.system("")

C_CYAN = '\033[96m'
C_GREEN = '\033[92m'
C_YELLOW = '\033[93m'
C_RED = '\033[91m'
C_PURPLE = '\033[95m'
C_RESET = '\033[0m'

SCRAPE_ALL = False 
# Add the specific IDs for The War Within, Dragonflight, etc. here!
TARGET_FACTIONS = {
    # === MIDNIGHT ===
    2710, # Silvermoon Court
    2696, # Magovu's Faction
    2704, # Naynar's Faction
    2699, # Void Researcher Anomander's Faction
    2770, # Thraxadar's Faction
    2764, # Prey: Season 1
    2742, # Delves: Season 1

    # === THE WAR WITHIN ===
    2590, # Council of Dornogal
    2594, # The Assembly of the Deeps
    2570, # Hallowfall Arathi
    2563, # The Severed Threads
    2600, # The Weaver (Severed Threads Pact)
    2601, # The General (Severed Threads Pact)
    2605, # The Vizier (Severed Threads Pact)
    
    # === DRAGONFLIGHT ===
    2503, # Dragonscale Expedition
    2507, # Valdrakken Accord
    2510, # Iskaara Tuskarr
    2511, # Maruuk Centaur
    2564, # Loamm Niffen
    2574, # Dream Wardens
    2544, # Artisan's Consortium
    2526, # Winterpelt Furbolg
    2550, # Soridormi
    2532, # Cobalt Assembly
    2517, # Sabellian
    2518, # Wrathion
}
FORBIDDEN_WORDS = ("UNUSED", "REUSE", "DO NOT USE", "DEPRECATED", "TRASH", "QA ", "TEST")

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
    2510: {"mapID": 2112, "x": 58.9, "y": 38.3, "npcName": "Unatos"},                
    2503: {"mapID": 2023, "x": 62.7, "y": 41.3, "npcName": "Huseng"},                
    2511: {"mapID": 2024, "x": 13.1, "y": 49.3, "npcName": "Murik"},                 
    2507: {"mapID": 2022, "x": 47.0, "y": 82.6, "npcName": "Cataloger Jakes"},       
    2564: {"mapID": 2133, "x": 56.4, "y": 55.6, "npcName": "Harlowe Marl"},          
    2574: {"mapID": 2200, "x": 50.2, "y": 61.6, "npcName": "Moon Priestess Lasara"},
    # --- Automatically Scraped ---
    2517: {"mapID": 2022, "x": 26.70, "y": 62.60, "npcName": "Wrathion"},
    2518: {"mapID": 2022, "x": 26.70, "y": 62.60, "npcName": "Wrathion"},
    2526: {"mapID": 2024, "x": 63.2, "y": 58.6, "npcName": "Garzquote"},
    2544: {"mapID": 2112, "x": 35.51, "y": 58.98, "npcName": "Rabul"},
}

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def detect_delimiter(filepath: str) -> str:
    """Sniffs the first line of the file to determine if it uses commas or semicolons."""
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            first_line = f.readline()
            if ';' in first_line: return ';'
            elif '\t' in first_line: return '\t'
            return ','
    except Exception:
        return ','

def print_log(level: str, msg: str):
    if level == "INFO": print(f"{C_YELLOW}[INFO] {msg}{C_RESET}")
    elif level == "SUCCESS": print(f"{C_GREEN}[+] {msg}{C_RESET}")
    elif level == "LINK": print(f"{C_CYAN}[LINK] {msg}{C_RESET}")
    elif level == "ERROR": print(f"{C_RED}[ERROR] {msg}{C_RESET}")

def get_col_name(row: Dict[str, str], target_substr: str) -> Optional[str]:
    target = target_substr.upper()
    return next((k for k in row.keys() if k and target in k.upper()), None)

# ==========================================
# 3. CORE PARSING LOGIC
# ==========================================
def parse_paragon_data() -> Dict[int, Dict[str, int]]:
    print_log("INFO", f"Analyzing {PARAGON_CSV}...")
    paragon_data: Dict[int, Dict[str, int]] = {}
    delim = detect_delimiter(PARAGON_CSV)
    
    try:
        with open(PARAGON_CSV, mode='r', encoding='utf-8-sig') as p_file:
            reader = csv.DictReader(p_file, delimiter=delim)
            for row in reader:
                fac_id_col = get_col_name(row, 'FACTIONID')
                thresh_col = get_col_name(row, 'LEVELTHRESHOLD')
                quest_col = get_col_name(row, 'QUESTID')

                if fac_id_col and row[fac_id_col]:
                    fid = int(row[fac_id_col])
                    paragon_data[fid] = {
                        "threshold": int(row[thresh_col]) if thresh_col and row.get(thresh_col) else 0,
                        "questID": int(row[quest_col]) if quest_col and row.get(quest_col) else 0
                    }
                    
        print_log("SUCCESS", f"Mapped {len(paragon_data)} Paragon quest links.\n")
        return paragon_data
    except Exception as e:
        print_log("ERROR", f"Paragon CSV failed: {e}")
        sys.exit(1)

def parse_faction_data(paragon_data: Dict[int, Dict[str, int]]) -> Dict[int, Dict[str, Any]]:
    print_log("INFO", f"Analyzing {FACTION_CSV} and building relationships...")
    faction_data: Dict[int, Dict[str, Any]] = {}
    delim = detect_delimiter(FACTION_CSV)

    try:
        with open(FACTION_CSV, mode='r', encoding='utf-8-sig') as f_file:
            reader = csv.DictReader(f_file, delimiter=delim)
            for row in reader:
                id_col = get_col_name(row, 'ID')
                name_col = get_col_name(row, 'NAME_LANG') or get_col_name(row, 'NAME')
                para_link_col = get_col_name(row, 'PARAGONFACTIONID')

                if id_col and row[id_col]:
                    fid = int(row[id_col])
                    name = row[name_col] if name_col and row.get(name_col) else ""
                    linked_paragon_id = int(row[para_link_col]) if para_link_col and row.get(para_link_col) else 0
                    
                    is_valid_name = True
                    upper_name = name.upper()
                    for word in FORBIDDEN_WORDS:
                        if word in upper_name:
                            is_valid_name = False
                            break
                    
                    if (name != "" and is_valid_name and (SCRAPE_ALL or fid in TARGET_FACTIONS)) or fid in paragon_data:
                        p_info = None
                        if linked_paragon_id > 0 and linked_paragon_id in paragon_data:
                            p_info = dict(paragon_data[linked_paragon_id])
                            p_info["paragonFactionID"] = linked_paragon_id
                        elif fid in paragon_data:
                            p_info = dict(paragon_data[fid])
                            p_info["paragonFactionID"] = fid

                        faction_data[fid] = {
                            "name": name,
                            "paragon": p_info,
                            "linked_p_id": linked_paragon_id
                        }
                        
        print_log("SUCCESS", f"Processed {len(faction_data)} valid factions.")
        return faction_data
    except Exception as e:
        print_log("ERROR", f"Faction CSV failed: {e}")
        sys.exit(1)

def link_waypoints(faction_data: Dict[int, Dict[str, Any]]):
    links_made = 0
    for fid, data in faction_data.items():
        if fid in CUSTOM_WAYPOINTS:
            linked_pid = data.get("linked_p_id", 0)
            if linked_pid > 0 and linked_pid not in CUSTOM_WAYPOINTS:
                CUSTOM_WAYPOINTS[linked_pid] = CUSTOM_WAYPOINTS[fid]
                print_log("LINK", f"Auto-copied {data['name']} coordinates to Paragon ID {linked_pid}!")
                links_made += 1
                
    if links_made == 0:
        print_log("INFO", "No new Paragon waypoint links needed.")

def write_lua_file(faction_data: Dict[int, Dict[str, Any]]):
    print_log("INFO", f"\nCompiling {OUTPUT_FILE}...")
    missing_count = 0
    
    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write('-- ==========================================\n')
            f.write('-- ODYSSEUS AUTO-GENERATED FACTION DATABASE\n')
            f.write('-- ==========================================\n')
            f.write('local addonName, OUS = ...\n\n')
            f.write('OUS.FactionData = {\n')
            
            for fid, data in sorted(faction_data.items()):
                display_name = data["name"]
                if display_name == "":
                    display_name = f"Paragon Faction {fid}"

                safe_name = display_name.replace('"', '\\"')
                f.write(f'    [{fid}] = {{\n')
                f.write(f'        name = "{safe_name}",\n')
                
                if data["paragon"]:
                    f.write(f'        isParagon = true,\n')
                    f.write(f'        paragonFactionID = {data["paragon"]["paragonFactionID"]},\n')
                    f.write(f'        paragonThreshold = {data["paragon"]["threshold"]},\n')
                    f.write(f'        paragonQuestID = {data["paragon"]["questID"]},\n')
                else:
                    f.write(f'        isParagon = false,\n')
                
                if fid in CUSTOM_WAYPOINTS:
                    wp = CUSTOM_WAYPOINTS[fid]
                    f.write(f'        rewardNPC = {{ mapID = {wp["mapID"]}, x = {wp["x"]}, y = {wp["y"]} }},\n')
                else:
                    # SILENTLY LOG THE MISSING WAYPOINT!
                    log_missing_waypoint(f"{fid},{display_name}")
                    missing_count += 1
                    f.write(f'        rewardNPC = {{ mapID = 0, x = 0.0, y = 0.0 }},\n') 
                    
                f.write(f'    }},\n')
                
            f.write('}\n')
        
        if missing_count > 0:
            print_log("INFO", f"Logged {missing_count} factions missing waypoints to 'missing_waypoints.log'")
            
        print(f"\n{C_GREEN}[SUCCESS] {len(faction_data)} Factions successfully compiled to {OUTPUT_FILE}!{C_RESET}")
        
    except Exception as e:
        print_log("ERROR", f"Failed to write Lua file: {e}")
        sys.exit(1)

# ==========================================
# 4. MAIN EXECUTION
# ==========================================
def main():
    print(f"{C_CYAN}=================================================={C_RESET}")
    print(f"{C_PURPLE}   Odysseus Relational Faction Compiler{C_RESET}")
    print(f"{C_CYAN}=================================================={C_RESET}\n")

    # Initialize the silent file logger BEFORE doing anything else
    setup_missing_waypoints_logger()

    if not os.path.exists(FACTION_CSV) or not os.path.exists(PARAGON_CSV):
        print_log("ERROR", "Missing CSV files! Ensure Faction.csv and ParagonReputation.csv are present.")
        input("Press Enter to exit...")
        sys.exit(1)

    paragon_data = parse_paragon_data()
    faction_data = parse_faction_data(paragon_data)
    link_waypoints(faction_data)
    write_lua_file(faction_data)
    
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()