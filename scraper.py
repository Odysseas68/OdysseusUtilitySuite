import csv
import os
import time

# --- TERMINAL COLORS ---
C_CYAN = '\033[96m'
C_GREEN = '\033[92m'
C_YELLOW = '\033[93m'
C_RED = '\033[91m'
C_PURPLE = '\033[95m'
C_RESET = '\033[0m'

FACTION_CSV = "Faction.csv"
PARAGON_CSV = "ParagonReputation.csv"
OUTPUT_FILE = "xpbar_data.lua"

SCRAPE_ALL = True 
TARGET_FACTIONS = [2590, 2594, 2570, 2563, 2503]

# =================================================================
# STATIC OVERRIDES: Major Quartermaster Coordinates
# =================================================================
CUSTOM_WAYPOINTS = {
    # --- MIDNIGHT (Example) ---
    2710: {"mapID": 2395, "x": 43.4, "y": 47.4, "npcName": "Caeris Fairdawn"},            #Silvermoon Court
    2696: {"mapID": 2437, "x": 45.9, "y": 65.9, "npcName": "Magovu"},                     #Amani Tribe
    2704: {"mapID": 2413, "x": 51.0, "y": 50.8, "npcName": "Naynar"},                     #Hara’ti
    2699: {"mapID": 2405, "x": 52.5, "y": 72.9, "npcName": "Void Researcher Anomander"},  #The Singularity
    2770: {"mapID": 2444, "x": 39.3, "y": 80.9, "npcName": "Thraxadar"},                  #The Slayer's Duellum

    # --- THE WAR WITHIN ---
    2590: {"mapID": 2339, "x": 39.1, "y": 24.2, "npcName": "Auditor Balwurz"},       # Council of Dornogal
    2594: {"mapID": 2214, "x": 47.3, "y": 32.9, "npcName": "Waxmonger Squick"},      # Assembly of the Deeps
    2570: {"mapID": 2215, "x": 41.3, "y": 53.1, "npcName": "Auralia Steelstrike"},   # Hallowfall Arathi
    2563: {"mapID": 2255, "x": 55.5, "y": 41.2, "npcName": "Lady Vinazian"},         # The Severed Threads

    # --- DRAGONFLIGHT ---
    2510: {"mapID": 2112, "x": 58.9, "y": 38.3, "npcName": "Unatos"},                # Valdrakken Accord
    2503: {"mapID": 2023, "x": 62.7, "y": 41.3, "npcName": "Huseng"},                # Maruuk Centaur
    2511: {"mapID": 2024, "x": 13.1, "y": 49.3, "npcName": "Murik"},                 # Iskaara Tuskarr
    2507: {"mapID": 2022, "x": 47.0, "y": 82.6, "npcName": "Cataloger Jakes"},       # Dragonscale Expedition
    2564: {"mapID": 2133, "x": 56.4, "y": 55.6, "npcName": "Harlowe Marl"},          # Loamm Niffen
    2574: {"mapID": 2200, "x": 50.2, "y": 61.6, "npcName": "Moon Priestess Lasara"}, # Dream Wardens
}

def compile_lua_data():
    print(f"{C_CYAN}=================================================={C_RESET}")
    print(f"{C_PURPLE}   Odysseus Relational Faction Compiler...{C_RESET}")
    print(f"{C_CYAN}=================================================={C_RESET}\n")

    if not os.path.exists(FACTION_CSV) or not os.path.exists(PARAGON_CSV):
        print(f"{C_RED}[ERROR] Missing CSV files! Ensure Faction.csv and ParagonReputation.csv are present.{C_RESET}")
        input("Press Enter to exit...")
        return

    # --- STEP 1: PARSE PARAGON DATA ---
    print(f"{C_YELLOW}[INFO] Analyzing {PARAGON_CSV}...{C_RESET}")
    paragon_data = {}
    
    try:
        with open(PARAGON_CSV, mode='r', encoding='utf-8-sig') as p_file:
            reader = csv.DictReader(p_file)
            for row in reader:
                fac_id_col = next((k for k in row.keys() if 'FACTIONID' in k.upper()), None)
                thresh_col = next((k for k in row.keys() if 'LEVELTHRESHOLD' in k.upper()), None)
                quest_col = next((k for k in row.keys() if 'QUESTID' in k.upper()), None)

                if fac_id_col and row[fac_id_col]:
                    fid = int(row[fac_id_col])
                    paragon_data[fid] = {
                        "threshold": int(row[thresh_col]) if thresh_col and row[thresh_col] else 0,
                        "questID": int(row[quest_col]) if quest_col and row[quest_col] else 0
                    }
        print(f"{C_GREEN}[+] Mapped {len(paragon_data)} Paragon quest links.{C_RESET}\n")
    except Exception as e:
        print(f"{C_RED}[ERROR] Paragon CSV failed: {e}{C_RESET}")
        input("Press Enter to exit...")
        return

    # --- STEP 2: PARSE FACTION DATA ---
    print(f"{C_YELLOW}[INFO] Analyzing {FACTION_CSV} and building relationships...{C_RESET}")
    faction_data = {}
    forbidden_words = ["UNUSED", "REUSE", "DO NOT USE", "DEPRECATED", "TRASH", "QA ", "TEST"]

    try:
        with open(FACTION_CSV, mode='r', encoding='utf-8-sig') as f_file:
            reader = csv.DictReader(f_file)
            for row in reader:
                id_col = next((k for k in row.keys() if k.upper() == 'ID'), None)
                name_col = next((k for k in row.keys() if 'NAME_LANG' in k.upper() or 'NAME' in k.upper()), None)
                para_link_col = next((k for k in row.keys() if 'PARAGONFACTIONID' in k.upper()), None)

                if id_col and row[id_col]:
                    fid = int(row[id_col])
                    name = row[name_col] if name_col and row[name_col] else ""
                    linked_paragon_id = int(row[para_link_col]) if para_link_col and row[para_link_col] else 0
                    
                    is_valid_name = True
                    for word in forbidden_words:
                        if word in name.upper():
                            is_valid_name = False
                            break
                    
                    # We grab it if it's valid, OR if it's explicitly a hidden paragon ID we need
                    if (name != "" and is_valid_name and (SCRAPE_ALL or fid in TARGET_FACTIONS)) or fid in paragon_data:
                        
                        # Determine the Paragon info. 
                        # Is this the base faction linking to a Paragon? Or IS this the Paragon faction?
                        p_info = None
                        if linked_paragon_id > 0 and linked_paragon_id in paragon_data:
                            p_info = paragon_data[linked_paragon_id]
                            p_info["paragonFactionID"] = linked_paragon_id
                        elif fid in paragon_data:
                            p_info = paragon_data[fid]
                            p_info["paragonFactionID"] = fid

                        faction_data[fid] = {
                            "name": name,
                            "paragon": p_info,
                            "linked_p_id": linked_paragon_id
                        }
                        print(f"{C_GREEN}[+] Processed Faction:{C_RESET} {fid} - {name}")
                        time.sleep(0.005) 
                        
    except Exception as e:
        print(f"{C_RED}[ERROR] Faction CSV failed: {e}{C_RESET}")
        input("Press Enter to exit...")
        return

    # --- STEP 3: SMART WAYPOINT LINKING ---
    # Automatically copy Custom Waypoints from the Base Faction to the Paragon Faction!
    for fid, data in faction_data.items():
        if fid in CUSTOM_WAYPOINTS:
            linked_pid = data.get("linked_p_id", 0)
            if linked_pid > 0 and linked_pid not in CUSTOM_WAYPOINTS:
                CUSTOM_WAYPOINTS[linked_pid] = CUSTOM_WAYPOINTS[fid]
                print(f"{C_CYAN}[LINK] Auto-copied {data['name']} coordinates to Paragon ID {linked_pid}!{C_RESET}")

    # --- STEP 4: WRITE LUA FILE ---
    print(f"\n{C_YELLOW}[INFO] Compiling {OUTPUT_FILE}...{C_RESET}")
    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write('-- Auto-Generated by Odysseus Relational Compiler\n')
            f.write('local addonName, OUS = ...\n\n')
            f.write('OUS.FactionData = {\n')
            
            for fid, data in sorted(faction_data.items()):
                # Fix blank names for hidden paragon rows
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
                    f.write(f'        rewardNPC = {{ mapID = 0, x = 0.0, y = 0.0 }},\n') 
                    
                f.write(f'    }},\n')
                
            f.write('}\n')
        
        print(f"{C_GREEN}[SUCCESS] {len(faction_data)} Factions successfully compiled to {OUTPUT_FILE}!{C_RESET}")
        input("Press Enter to exit...")
        
    except Exception as e:
        print(f"{C_RED}[ERROR] Failed to write Lua file: {e}{C_RESET}")
        input("Press Enter to exit...")

if __name__ == "__main__":
    compile_lua_data()