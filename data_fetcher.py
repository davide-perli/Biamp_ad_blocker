import requests # type: ignore

url = "https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts"

response = requests.get(url)
content = response.text

output_file = "ad-domains.txt"

domains = []
for line in content.splitlines():
    if line.startswith("0.0.0.0"):
        parts = line.split()
        if len(parts) >= 2:
            domain = parts[1].strip()
            if not domain.replace('.', '').isdigit():
               domains.append(domain)

with open(output_file, "w") as f:
    for domain in domains:
        f.write(domain + "\n")

print(f"Extracted {len(domains)} domains to {output_file}")