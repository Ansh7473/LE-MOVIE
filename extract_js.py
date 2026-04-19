import json

def extract_js(har_path):
    with open(har_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    entries = data.get('log', {}).get('entries', [])
    for entry in entries:
        req = entry.get('request', {})
        url = req.get('url', '')
        
        if 'component---src-pages-movie-details-index-js' in url:
            res = entry.get('response', {})
            body = res.get('content', {}).get('text', '')
            with open('movie_details.js', 'w', encoding='utf-8') as out:
                out.write(body)
            print("Extracted to movie_details.js")

extract_js("HTTPToolkit_2026-04-19_16-55.har")
