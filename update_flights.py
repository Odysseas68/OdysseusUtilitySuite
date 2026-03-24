import os
import re

# THE FIX: Force Python to run inside the exact folder this script is located in!
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# Wake up Windows CMD to process ANSI color codes
os.system("")

# Define our UI Colors
C_BLUE = "\033[96m"   # Cyan/Sky Blue
C_GREEN = "\033[92m"  # Bright Green
C_YELLOW = "\033[93m" # Bright Yellow
C_RED = "\033[91m"    # Bright Red
C_RESET = "\033[0m"   # Resets color back to default white/gray

# File names
MASTER_FILE = "flightdata.lua" # Updated to match your .toc file!
UPDATE_FILE = "update.txt"

def parse_lua_table(filepath):
    """Reads a Lua file and extracts the nested table into a Python dictionary."""
    data = {}
    if not os.path.exists(filepath):
        return data
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Find blocks of ["StartLocation"] = { ... }
    outer_pattern = re.compile(r'\["(.*?)"\]\s*=\s*\{([^}]*)\}')
    for match in outer_pattern.finditer(content):
        start_node = match.group(1)
        inner_content = match.group(2)
        
        if start_node not in data:
            data[start_node] = {}
            
        # Find inner nodes: ["DestLocation"] = 120,
        inner_pattern = re.compile(r'\["(.*?)"\]\s*=\s*(\d+)')
        for inner_match in inner_pattern.finditer(inner_content):
            dest_node = inner_match.group(1)
            time_val = int(inner_match.group(2))
            data[start_node][dest_node] = time_val
            
    return data

def clean_legacy_duplicates(flight_data):
    """
    Scans the flight database and removes old short-name flights 
    if a modern full-name flight already exists.
    """
    def get_short_name(name):
        return name.split(',')[0].strip()

    modern_start_nodes = [node for node in flight_data.keys() if ',' in node]

    for full_start in modern_start_nodes:
        short_start = get_short_name(full_start)
        
        if short_start in flight_data and short_start != full_start:
            for old_dest in list(flight_data[short_start].keys()):
                old_dest_short = get_short_name(old_dest)
                
                is_duplicate = False
                for modern_dest in flight_data[full_start].keys():
                    if get_short_name(modern_dest) == old_dest_short:
                        is_duplicate = True
                        break
                
                if is_duplicate:
                    # Delete the legacy duplicate!
                    del flight_data[short_start][old_dest]
            
            # If the old category is now empty, delete it completely
            if not flight_data[short_start]:
                del flight_data[short_start]

    return flight_data

def write_lua_table(filepath, data):
    """Writes the Python dictionary back into a perfectly formatted Lua file."""
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

def main():
    print(f"\n{C_BLUE}=== Odysseus Flight Database Updater ==={C_RESET}\n")
    
    if not os.path.exists(UPDATE_FILE):
        print(f"{C_RED}Error:{C_RESET} Could not find '{C_YELLOW}{UPDATE_FILE}{C_RESET}' inside {SCRIPT_DIR}.")
        print("Please make sure the file isn't accidentally named 'update.txt.txt'!")
        input("\nPress Enter to exit...")
        return
        
    # 1. Read the pasted updates
    updates = parse_lua_table(UPDATE_FILE)
    if not updates:
        print(f"{C_YELLOW}No new flight data found in update.txt. Nothing to do!{C_RESET}")
        input("\nPress Enter to exit...")
        return
        
    # 2. Read the master database
    print(f"Reading master database from {C_YELLOW}{MASTER_FILE}{C_RESET}...")
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
            
    # --- THE FIX: Purge the legacy duplicates before saving! ---
    print(f"\nScanning for and removing legacy duplicate formats...")
    master_data = clean_legacy_duplicates(master_data)
            
    # 4. Write the beautifully merged data back to the master file
    print(f"Saving {C_GREEN}{total_updates}{C_RESET} updates to {C_YELLOW}{MASTER_FILE}{C_RESET}...")
    write_lua_table(MASTER_FILE, master_data)
    
    # 5. Clear out the update file so it's fresh for next time
    with open(UPDATE_FILE, 'w', encoding='utf-8') as f:
        f.write("-- Paste your exported flights here next time!\n")
        
    print(f"\n{C_GREEN}Success!{C_RESET} Your master database is completely up to date and deduplicated.")
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()