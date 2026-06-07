import json, time, os, requests

INPUT_FILE = os.path.join(os.path.dirname(__file__), "medicines_dawaai.json")
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), "medicines_with_composition.json")

session = requests.Session()
session.headers.update({'User-Agent': 'Mozilla/5.0', 'Accept-Encoding': 'gzip'})

with open(INPUT_FILE, 'r', encoding='utf-8') as f:
    products = json.load(f)

stems = sorted(set(p['name'].split()[0].strip().lower() for p in products if p.get('name')))
total = len(stems)
print(f"Products: {len(products)}, Unique stems: {total}")

stem_to_generic = {}
done = found = 0

for stem in stems:
    try:
        r = session.get(f"https://drugsinfo.pk/api/search?q={stem}", timeout=10)
        r.raise_for_status()
        hits = r.json().get('hits', [])
        gen = ''
        for h in hits:
            if h.get('type') == 'molecule':
                gen = h.get('title', '')
                break
        if not gen:
            for h in hits:
                if h.get('type') == 'brand':
                    s = h.get('subtitle', '')
                    if ' · ' in s:
                        gen = s.split(' · ')[0].strip()
                        break
        if gen:
            found += 1
            stem_to_generic[stem] = gen
    except Exception as e:
        pass
    done += 1
    if done % 500 == 0:
        print(f"{done}/{total} stems, found={found}")
    time.sleep(0.15)

print(f"Done lookup: {found}/{total} stems have generic names")

for p in products:
    stem = p.get('name', '').split()[0].strip().lower() if p.get('name') else ''
    if stem in stem_to_generic:
        p['generic_name'] = stem_to_generic[stem]

filled = len([p for p in products if p.get('generic_name')])
print(f"Products with generic names: {filled}/{len(products)}")

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(products, f, indent=2, ensure_ascii=False)
print(f"Saved to {OUTPUT_FILE}")

print("\nSamples (first 20):")
for p in products[:20]:
    print(f"  {p['name']:35s} | {p.get('generic_name',''):30s} | {p['manufacturer']}")
