import json

def find_fmovies_servers(har_path):
    with open(har_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    entries = data.get('log', {}).get('entries', [])
    for entry in entries:
        req = entry.get('request', {})
        url = req.get('url', '')
        
        # Check responses for servers
        if 'ww2-fmovies.com' in url or 'videasy.net' in url or 'vidsrc' in url:
            res = entry.get('response', {})
            body = res.get('content', {}).get('text', '')
            if body and ('UpCloud' in body or 'Vidcloud' in body or 'servers' in body.lower() or 'sources' in body.lower()):
                print(f"Found something interesting in: {url}")
                # Print a snippet around the match
                idx = body.lower().find('server')
                if idx == -1: idx = body.lower().find('source')
                if idx != -1:
                    start = max(0, idx - 100)
                    end = min(len(body), idx + 800)
                    print(body[start:end])
                    print("="*80)

find_fmovies_servers("HTTPToolkit_2026-04-19_16-55.har")
