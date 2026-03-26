import os
import time
import random
import requests
import re
import html

# ==========================================
# 1. CONFIGURATION & POLITE BOT SETTINGS
# ==========================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

MISSING_LOG = "missing_waypoints.log"
OUTPUT_FILE = "scraped_waypoints.txt"

HEADERS = {
    "User-Agent": "Odysseus-Addon-Data-Compiler/1.0 (Contact: AddonDev)",
    "Accept": "text/html,application/xhtml+xml"
}

# IMPORTANT: 2 second delay between requests so we don't get IP banned!
THROTTLE_DELAY = 2.0 

C_CYAN = '\033[96m'
C_YELLOW = '\033[93m'
C_GREEN = '\033[92m'
C_RED = '\033[91m'
C_PURPLE = '\033[95m'
C_RESET = '\033[0m'

# ==========================================
# 2. CORE ENGINE
# ==========================================
def read_missing_factions():
    factions_to_scrape = []
    if not os.path.exists(MISSING_LOG):
        print(f"{C_RED}[ERROR] Could not find {MISSING_LOG}! Run scraper.py first.{C_RESET}")
        return factions_to_scrape
        
    with open(MISSING_LOG, 'r', encoding='utf-8') as f:
        for line in f:
            if ',' in line:
                fid, fname = line.strip().split(',', 1)
                factions_to_scrape.append({"id": fid, "name": fname})
                
    return factions_to_scrape

def scrape_waypoint(faction_id: str, faction_name: str) -> str:
    # We use a generic URL format to catch as many as possible
    url = f"https://www.wowhead.com/faction={faction_id}"
    print(f"{C_YELLOW}[BOT] Requesting {faction_name} (ID: {faction_id})...{C_RESET}")
    
    try:
        response = requests.get(url, headers=HEADERS)
        
        if response.status_code == 200:
            clean_text = html.unescape(response.text).replace('\\/', '/')
            
            # The Bulletproof Regex
            tomtom_pattern = r'/way\s+#?(\d+)\s+([\d\.]+)\s+([\d\.]+)\s*([^\<\n\\"]*)'
            matches = re.findall(tomtom_pattern, clean_text)
            
            if matches:
                # We just take the first unique match assuming it's the most upvoted comment
                map_id, x, y, extra_text = matches[0]
                npc_name = extra_text.strip() if extra_text.strip() else "Unknown NPC"
                npc_name = re.sub(r'[^a-zA-Z0-9 \'\-]', '', npc_name).strip()
                
                print(f"{C_GREEN}[+] Found: Map {map_id} | X {x} | Y {y} | {npc_name}{C_RESET}")
                
                # Return perfectly formatted Python dictionary string
                return f'    {faction_id}: {{"mapID": {map_id}, "x": {x}, "y": {y}, "npcName": "{npc_name}"}},'
            else:
                print(f"{C_RED}[-] No TomTom macros found.{C_RESET}")
                return ""
                
        else:
            print(f"{C_RED}[ERROR] Wowhead Status: {response.status_code}{C_RESET}")
            return ""
            
    except Exception as e:
        print(f"{C_RED}[ERROR] Connection failed: {e}{C_RESET}")
        return ""

# ==========================================
# 3. MAIN EXECUTION
# ==========================================
def main():
    print(f"{C_CYAN}=== Odysseus Wowhead Scraper Bot ==={C_RESET}\n")
    
    queue = read_missing_factions()
    if not queue:
        return
        
    print(f"[INFO] Loaded {len(queue)} factions from {MISSING_LOG}.")
    print(f"[INFO] Stealth Mode: Random Jitter + Batch Pauses Enabled.\n")
    
    success_count = 0 # <--- 1. Create the counter here!
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Automatically scraped waypoints from Wowhead Comments\n")
        f.write("# Copy and paste these into your CUSTOM_WAYPOINTS dictionary:\n\n")
        
        for index, faction in enumerate(queue):
            print(f"--- Faction {index + 1} / {len(queue)} ---")
            
            result = scrape_waypoint(faction["id"], faction["name"])
            if result:
                f.write(result + "\n")
                f.flush()
                success_count += 1 # <--- 2. Add 1 to the score every time it finds a match!
                
            # THE STEALTH THROTTLE
            if index > 0 and index % 20 == 0:
                break_time = random.uniform(10.0, 15.0)
                print(f"{C_PURPLE}[BOT] Taking a simulated 'coffee break' for {break_time:.1f} seconds...{C_RESET}\n")
                time.sleep(break_time)
            else:
                jitter = random.uniform(2.5, 4.5)
                print(f"{C_CYAN}[BOT] Sleeping for {jitter:.1f} seconds...{C_RESET}\n")
                time.sleep(jitter)

    # 3. Print the final scorecard at the very end!
    print(f"\n{C_GREEN}[SUCCESS] Scraping complete!{C_RESET}")
    print(f"{C_YELLOW}[RESULT] Found coordinates for {success_count} out of {len(queue)} factions!{C_RESET}")
    print(f"[INFO] Check {OUTPUT_FILE} for results.")

if __name__ == "__main__":
    main()