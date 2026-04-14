import requests
import re
from bs4 import BeautifulSoup
import time

API_KEY = 'YOUR_API_KEY'          # Replace with your API key
CSE_ID = 'YOUR_CSE_ID'            # Replace with your Search Engine ID
QUERY = 'raku programming language'
NUM_RESULTS = 10                  # Number of results per request (max 10 per Google API)
DELAY_BETWEEN_REQUESTS = 1       # To avoid rate limits

def google_search(query, api_key, cse_id, num=10, start=1):
    url = 'https://www.googleapis.com/customsearch/v1'
    params = {
        'key': api_key,
        'cx': cse_id,
        'q': query,
        'num': num,
        'start': start,
        'sort': 'date',
        'dateRestrict': 'w1',  # restrict to last week
    }
    response = requests.get(url, params=params)
    response.raise_for_status()
    return response.json()

def extract_raku_sentences(text):
    # Split snippet into sentences and return only those mentioning 'raku'
    sentences = re.split(r'(?<=[.!?]) +', text)
    return [s for s in sentences if 'raku' in s.lower()]

def get_author_from_page(url):
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; RakuScraper/1.0)"
        }
        resp = requests.get(url, headers=headers, timeout=10)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')
        # Try meta tag 'author'
        author_meta = soup.find('meta', attrs={'name': 'author'})
        if author_meta and author_meta.get('content'):
            return author_meta['content'].strip()

        # Try meta tag 'article:author' (common in OpenGraph)
        og_author = soup.find('meta', attrs={'property': 'article:author'})
        if og_author and og_author.get('content'):
            return og_author['content'].strip()

        # Try common author selectors
        for candidate in ['.author', '.byline', '.post-author']:
            el = soup.select_one(candidate)
            if el:
                return el.get_text(strip=True)

    except Exception as e:
        print(f"Error fetching author from {url}: {e}")
    return "Unknown"

def main():
    all_results = []
    start_index = 1

    # Google API allows max 100 results by paging with &start
    while start_index <= NUM_RESULTS:
        results = google_search(QUERY, API_KEY, CSE_ID, num=min(10, NUM_RESULTS - start_index +1), start=start_index)
        items = results.get('items', [])
        if not items:
            break

        for item in items:
            link = item.get('link')
            snippet = item.get('snippet', '')
            sentences = extract_raku_sentences(snippet)
            author = get_author_from_page(link) if link else "Unknown"

            print(f"Link: {link}")
            print(f"Author: {author}")
            print("Sentences mentioning 'raku':")
            for s in sentences:
                print(f"  - {s}")
            print("-" * 60)

        start_index += len(items)
        time.sleep(DELAY_BETWEEN_REQUESTS)

if __name__ == '__main__':
    main()