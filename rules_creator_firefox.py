import json

MAX_RULES_PER_FILE = 10000

with open("ad-domains.txt", "r") as f:
    domains = [line.strip() for line in f if line.strip()]

total = len(domains)
file_count = (total + MAX_RULES_PER_FILE - 1) // MAX_RULES_PER_FILE

for file_idx in range(file_count):
    start = file_idx * MAX_RULES_PER_FILE
    end = min(start + MAX_RULES_PER_FILE, total)
    rules = []
    for i, domain in enumerate(domains[start:end], start=1):
        rule = {
            "id": start + i,
            "priority": 1,
            "action": {"type": "block"},
            "condition": {
                "urlFilter": f"{domain}^",
                "resourceTypes": [
                    "main_frame",
                    "sub_frame",
                    "script",
                    "image",
                    "xmlhttprequest"
                ]
            }
        }
        rules.append(rule)
    filename = f"firefox_extension/rules_{file_idx + 1}.json"
    with open(filename, "w") as out:
        json.dump(rules, out, indent=2)
    print(f"Wrote {len(rules)} rules to {filename}")

# Run this for compression to zip file since here instead of path\to\file is path/to/file
# .\req_libraries\Scripts\python.exe -c "import zipfile; from pathlib import Path; root=Path('firefox_extension'); out=Path('firefox-extension.zip'); files=[p for p in root.rglob('*') if p.is_file() and '_metadata' not in p.parts]; z=zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9); [z.write(p, p.relative_to(root).as_posix()) for p in files]; z.close()"