import csv
import os
import re
import sys
from typing import Dict, Optional

# ==========================================
# 1. CONFIGURATION & CONSTANTS
# ==========================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

NODE_CSV = r"d:\Wow.export.data\TaxiNodes.csv"
PATH_CSV = r"d:\Wow.export.data\TaxiPath.csv"
OUTPUT_LUA = "Odysseus_RoutingDB.lua"

# Terminal Colors
C_CYAN = '\033[96m'
C_GREEN = '\033[92m'
C_YELLOW = '\033[93m'
C_RED = '\033[91m'
C_RESET = '\033[0m'

# Pre-compile filters for performance
PATCH_REGEX = re.compile(r'\b\d{2}\.\d\b')
INVALID_KEYWORDS = (
    "QUEST", "QA ", " QA", "TEST", "SCENARIO", 
    "INTRO FLIGHT", "DEBUG", "UNUSED", "BAT RIDE",
    "TELEPORT", "BASE", "TOP", "INTERNAL", "DEV ONLY"
)

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def detect_delimiter(filepath: str) -> str:
    """Sniffs the first line of the file to determine if it uses commas or semicolons."""
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            first_line = f.readline()
            if ';' in first_line:
                return ';'
            elif '\t' in first_line:
                return '\t'
            return ','
    except Exception:
        return ',' # Fallback to comma

def get_col_name(row: Dict[str, str], target_substr: str) -> Optional[str]:
    """Safely finds a column name even if Blizzard changes the exact formatting."""
    target = target_substr.upper()
    return next((k for k in row.keys() if k and target in k.upper()), None)

def clean_node_name(raw_name: str) -> str:
    """Strips coordinates and secondary tags from node names."""
    if not raw_name:
        return "Unknown Node"
    return raw_name.split(',')[0].strip()

def is_valid_node(name: str) -> bool:
    """Acts as an aggressive bouncer to block quests, test nodes, and datamined alpha content."""
    upper_name = name.upper()
    
    if PATCH_REGEX.search(upper_name):
        return False
        
    for keyword in INVALID_KEYWORDS:
        if keyword in upper_name:
            return False
            
    return True

def print_log(level: str, msg: str):
    """Standardized terminal logger."""
    if level == "INFO":
        print(f"{C_YELLOW}[INFO] {msg}{C_RESET}")
    elif level == "SUCCESS":
        print(f"{C_GREEN}[+] {msg}{C_RESET}")
    elif level == "ERROR":
        print(f"{C_RED}[ERROR] {msg}{C_RESET}")
        
# ==========================================
# 3. CORE COMPILER LOGIC
# ==========================================
def parse_nodes() -> Dict[int, str]:
    """Reads TaxiNodes.csv and builds a dictionary of valid nodes."""
    print_log("INFO", f"Parsing {NODE_CSV}...")
    nodes: Dict[int, str] = {}
    
    # THE FIX: Automatically detect the delimiter!
    delim = detect_delimiter(NODE_CSV)
    
    try:
        with open(NODE_CSV, mode='r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f, delimiter=delim)
            for row in reader:
                node_id_col = get_col_name(row, 'ID')
                name_col = get_col_name(row, 'NAME_LANG')
                
                if node_id_col and name_col and row[node_id_col]:
                    nid = int(row[node_id_col])
                    name = clean_node_name(row[name_col])
                    
                    if is_valid_node(name):
                        nodes[nid] = name
                        
        print_log("SUCCESS", f"Loaded {len(nodes)} clean locations.")
        return nodes
    except Exception as e:
        print_log("ERROR", f"Failed to read nodes: {e}")
        sys.exit(1)

def parse_paths(valid_nodes: Dict[int, str]) -> Dict[int, Dict[int, int]]:
    """Reads TaxiPath.csv and maps edges ONLY between validated nodes."""
    print_log("INFO", f"Parsing {PATH_CSV}...")
    routes: Dict[int, Dict[int, int]] = {}
    path_count = 0
    
    # THE FIX: Automatically detect the delimiter!
    delim = detect_delimiter(PATH_CSV)
    
    try:
        with open(PATH_CSV, mode='r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f, delimiter=delim)
            for row in reader:
                from_col = get_col_name(row, 'FROMTAXINODE')
                to_col = get_col_name(row, 'TOTAXINODE')
                cost_col = get_col_name(row, 'COST')

                if from_col and to_col and row[from_col] and row[to_col]:
                    from_id = int(row[from_col])
                    to_id = int(row[to_col])
                    cost = int(row[cost_col]) if cost_col and row.get(cost_col) else 0

                    if from_id in valid_nodes and to_id in valid_nodes:
                        if from_id not in routes:
                            routes[from_id] = {}
                        routes[from_id][to_id] = cost
                        path_count += 1
                        
        print_log("SUCCESS", f"Mapped {path_count} direct flight connections.")
        return routes
    except Exception as e:
        print_log("ERROR", f"Failed to read paths: {e}")
        sys.exit(1)

def write_lua_database(nodes: Dict[int, str], routes: Dict[int, Dict[int, int]]):
    """Formats the Python dictionaries into a World of Warcraft Lua script."""
    print_log("INFO", f"Compiling {OUTPUT_LUA}...")
    
    try:
        with open(OUTPUT_LUA, "w", encoding="utf-8") as f:
            f.write('-- ==========================================\n')
            f.write('-- ODYSSEUS AUTO-GENERATED ROUTING DATABASE\n')
            f.write('-- ==========================================\n')
            f.write('local addonName, OUS = ...\n\n')
            
            f.write('OUS.TaxiNodes = {\n')
            for nid, name in sorted(nodes.items()):
                safe_name = name.replace('"', '\\"')
                f.write(f'    [{nid}] = "{safe_name}",\n')
            f.write('}\n\n')

            f.write('OUS.TaxiRoutes = {\n')
            for from_id in sorted(routes.keys()):
                f.write(f'    [{from_id}] = {{\n')
                for to_id, cost in sorted(routes[from_id].items()):
                    f.write(f'        [{to_id}] = {{ cost = {cost} }},\n')
                f.write('    },\n')
            f.write('}\n')
            
        print(f"\n{C_GREEN}[SUCCESS] Relational Geography Database created!{C_RESET}")
    except Exception as e:
        print_log("ERROR", f"Failed to write Lua file: {e}")

# ==========================================
# 4. MAIN EXECUTION
# ==========================================
def main():
    print(f"\n{C_CYAN}=== Odysseus Relational Routing Compiler ==={C_RESET}\n")

    if not os.path.exists(NODE_CSV) or not os.path.exists(PATH_CSV):
        print_log("ERROR", "Missing CSV files! Please download TaxiNodes.csv and TaxiPath.csv.")
        input("Press Enter to exit...")
        sys.exit(1)

    valid_nodes = parse_nodes()
    mapped_routes = parse_paths(valid_nodes)
    write_lua_database(valid_nodes, mapped_routes)
    
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()