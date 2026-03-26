import os
import re
import sys
from typing import Dict

# ==========================================
# 1. CONFIGURATION & CONSTANTS & FILE PATHS
# ==========================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# Wake up Windows CMD to process ANSI color codes
os.system("")

# Terminal Colors
C_CYAN = '\033[96m'
C_GREEN = '\033[92m'
C_YELLOW = '\033[93m'
C_RED = '\033[91m'
C_RESET = '\033[0m'

# File names
MASTER_FILE = os.path.abspath(os.path.join(SCRIPT_DIR, '..', 'flightdata.lua'))
UPDATE_FILE = os.path.abspath(os.path.join(SCRIPT_DIR, '..', 'update.txt'))

# Pre-compile Regex Patterns for performance
LUA_OUTER_PATTERN = re.compile(r'\["(.*?)"\]\s*=\s*\{([^}]*)\}')
LUA_INNER_PATTERN = re.compile(r'\["(.*?)"\]\s*=\s*(\d+)')

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def print_log(level: str, msg: str):
    """Standardized terminal logger."""
    if level == "INFO":
        print(f"{C_YELLOW}[INFO] {msg}{C_RESET}")
    elif level == "SUCCESS":
        print(f"{C_GREEN}[+] {msg}{C_RESET}")
    elif level == "ERROR":
        print(f"{C_RED}[ERROR] {msg}{C_RESET}")

def parse_lua_table(filepath: str) -> Dict[str, Dict[str, int]]:
    """Reads a Lua file and extracts the nested table into a Python dictionary."""
    data: Dict[str, Dict[str, int]] = {}
    
    if not os.path.exists(filepath):
        return data
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    for match in LUA_OUTER_PATTERN.finditer(content):
        start_node = match.group(1)
        inner_content = match.group(2)
        
        if start_node not in data:
            data[start_node] = {}
            
        for inner_match in LUA_INNER_PATTERN.finditer(inner_content):
            dest_node = inner_match.group(1)
            time_val = int(inner_match.group(2))
            data[start_node][dest_node] = time_val
            
    return data

def clean_legacy_duplicates(flight_data: Dict[str, Dict[str, int]]) -> Dict[str, Dict[str, int]]:
    """
    Scans the flight database and removes old short-name flights 
    if a modern full-name flight already exists.
    """
    def get_short_name(name: str) -> str:
        return name.split(',')[0].strip()

    # Find nodes that have a comma (modern full-name nodes)
    modern_starts = [node for node in flight_data.keys() if ',' in node]

    for full_start in modern_starts:
        short_start = get_short_name(full_start)
        
        # Check if the legacy short version exists alongside the modern full version
        if short_start in flight_data and short_start != full_start:
            # Create a set of the short names of all modern destinations for instant lookup
            modern_dest_shorts = {get_short_name(d) for d in flight_data[full_start].keys()}
            
            # Iterate over a list wrapper so we can safely delete from the dictionary while looping
            for old_dest in list(flight_data[short_start].keys()):
                if get_short_name(old_dest) in modern_dest_shorts:
                    # Delete the legacy duplicate!
                    del flight_data[short_start][old_dest]
            
            # If the old category is now empty, delete it completely
            if not flight_data[short_start]:
                del flight_data[short_start]

    return flight_data

def write_lua_table(filepath: str, data: Dict[str, Dict[str, int]]):
    """Writes the Python dictionary back into a perfectly formatted Lua file."""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("SFT_FlightData = {\n")
            
            # Sort the starting locations alphabetically for a clean file
            for start_node in sorted(data.keys()):
                f.write(f'    ["{start_node}"] = {{\n')
                
                # Sort the destinations alphabetically too
                for dest_node in sorted(data[start_node].keys()):
                    time_val = data[start_node][dest_node]
                    f.write(f'        ["{dest_node}"] = {time_val},\n')
                    
                f.write("    },\n")
            f.write("}\n")
    except Exception as e:
        print_log("ERROR", f"Failed to write Lua file: {e}")
        sys.exit(1)

def reset_update_file(filepath: str):
    """Clears the update file so it's ready for the next copy-paste."""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("-- Paste your exported flights here next time!\n")
    except Exception as e:
        print_log("ERROR", f"Failed to reset update file: {e}")

# ==========================================
# 3. MAIN EXECUTION
# ==========================================
def main():
    print(f"\n{C_CYAN}=== Odysseus Flight Database Updater ==={C_RESET}\n")
    
    if not os.path.exists(UPDATE_FILE):
        print_log("ERROR", f"Could not find '{UPDATE_FILE}' inside {SCRIPT_DIR}.")
        print("Please make sure the file isn't accidentally named 'update.txt.txt'!")
        input("\nPress Enter to exit...")
        sys.exit(1)
        
    # 1. Read the pasted updates
    updates = parse_lua_table(UPDATE_FILE)
    if not updates:
        print_log("INFO", "No new flight data found in update.txt. Nothing to do!")
        input("\nPress Enter to exit...")
        return
        
    # 2. Read the master database
    print_log("INFO", f"Reading master database from {MASTER_FILE}...")
    master_data = parse_lua_table(MASTER_FILE)
    
    # 3. Merge the updates into the master data
    total_updates = 0
    print("\nProcessing flights:")
    for start_node, dests in updates.items():
        if start_node not in master_data:
            master_data[start_node] = {}
            
        for dest_node, time_val in dests.items():
            master_data[start_node][dest_node] = time_val
            total_updates += 1
            print(f" {C_GREEN}-> Merged:{C_RESET} {C_YELLOW}{start_node}{C_RESET} to {C_YELLOW}{dest_node}{C_RESET} ({C_GREEN}{time_val}s{C_RESET})")
            
    # 4. Deduplicate Legacy Formats
    print(f"\n{C_YELLOW}Scanning for and removing legacy duplicate formats...{C_RESET}")
    master_data = clean_legacy_duplicates(master_data)
            
    # 5. Write the merged data back to the master file
    print_log("INFO", f"Saving {total_updates} updates to {MASTER_FILE}...")
    write_lua_table(MASTER_FILE, master_data)
    
    # 6. Clear out the update file so it's fresh for next time
    reset_update_file(UPDATE_FILE)
        
    print(f"\n{C_GREEN}[SUCCESS] Your master database is completely up to date and deduplicated!{C_RESET}")
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()