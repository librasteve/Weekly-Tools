import requests
from bs4 import BeautifulSoup

search_term = "raku programming language"
url = f"https://www.google.com/search?q={search_term}&tbs=qdr:w"

response = requests.get(url)
soup = BeautifulSoup(response.content, 'html.parser')

results = soup.find_all('div', class_='g')

for result in results:
    comment = result.find('span').text
    author = result.find('cite').text
    link = result.find('a')['href']

    print(f"Comment: {comment}")
    print(f"Author: {author}")
    print(f"Link: {link}")
    print("\n")