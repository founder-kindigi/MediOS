import requests
import re
import json
import time
import os
from bs4 import BeautifulSoup

BASE_URL = "https://dawaai.pk"
LETTERS = [chr(i) for i in range(ord('a'), ord('z') + 1)]

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
}

session = requests.Session()
session.headers.update(HEADERS)


def parse_price(price_text):
    nums = re.findall(r'[\d,]+', price_text.replace(',', ''))
    prices = [int(n.replace(',', '')) for n in nums]
    if len(prices) >= 2:
        return prices[1], prices[0]
    elif len(prices) == 1:
        return prices[0], prices[0]
    return 0, 0


def scrape_letter(letter):
    url = f"{BASE_URL}/all-medicines/{letter}"
    products = []
    page = 1
    
    while True:
        page_url = f"{url}/{page}" if page > 1 else url
        print(f"  Fetching {page_url}...")
        
        try:
            r = session.get(page_url, timeout=120)
            r.raise_for_status()
        except Exception as e:
            print(f"  Error fetching {page_url}: {e}")
            break
        
        soup = BeautifulSoup(r.text, 'html.parser')
        cards = soup.select('div.card')
        
        if not cards:
            print(f"  No product cards found on {page_url}")
            break
        
        for card in cards:
            try:
                name_el = card.select_one('h2 a')
                if not name_el:
                    continue
                name = name_el.get_text(strip=True)
                product_url = name_el.get('href', '')
                
                p_tags = card.select('div.card-body > p')
                manufacturer = p_tags[0].get_text(strip=True) if len(p_tags) > 0 else ''
                pack_size_text = p_tags[1].get_text(strip=True) if len(p_tags) > 1 else ''
                pack_size = pack_size_text.replace('Pack Size:', '').strip() if 'Pack Size:' in pack_size_text else pack_size_text
                
                h4 = card.select_one('div.card-body h4')
                selling_price, original_price = 0, 0
                if h4:
                    selling_price, original_price = parse_price(h4.get_text())
                
                btn = card.select_one('button.AddToCart')
                product_id = None
                if btn and btn.get('onclick'):
                    m = re.search(r'(\d+)', btn['onclick'])
                    if m:
                        product_id = int(m.group(1))
                
                if name:
                    products.append({
                        'name': name,
                        'generic_name': '',
                        'manufacturer': manufacturer,
                        'pack_size': pack_size,
                        'selling_price': selling_price,
                        'original_price': original_price,
                        'product_url': product_url,
                        'product_id': product_id,
                        'source': 'dawaai.pk',
                    })
            except Exception as e:
                print(f"  Error parsing card: {e}")
                continue
        
        print(f"  Found {len(cards)} cards, extracted {len(products)} products so far (page {page})")
        
        next_btn = soup.select_one('a[rel="next"]')
        if next_btn:
            page += 1
            time.sleep(1)
        else:
            break
    
    return products


def main():
    all_products = []
    total = 0
    
    for letter in LETTERS:
        print(f"Scraping letter '{letter}'...")
        products = scrape_letter(letter)
        all_products.extend(products)
        total += len(products)
        print(f"  Letter '{letter}': {len(products)} products (total: {total})")
        time.sleep(1)
    
    output_path = os.path.join(os.path.dirname(__file__), 'medicines_dawaai.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_products, f, indent=2, ensure_ascii=False)
    
    print(f"\nDone! Total products: {len(all_products)}")
    print(f"Saved to: {output_path}")


if __name__ == '__main__':
    main()
