import json

def find_all_providers(har_path):
    with open(har_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    entries = data.get('log', {}).get('entries', [])
    
    # Collect all unique domains that are NOT content/meta APIs
    skip = {
        'db.videasy.net', 'ww2-fmovies.com', 'tmdb.org', 'cloudflare',
        'googleapis.com', 'gstatic.com', 'google.com', 'doubleclick',
        'fonts.', 'analytics', 'gtag', 'beacon', 'cdn-cgi',
        'sentry', 'datadog', 'hotjar', 'intercom', 'segment',
        'facebook', 'twitter', 'instagram', 'reddit',
    }

    seen = set()
    providers = []

    for entry in entries:
        url = entry.get('request', {}).get('url', '')
        
        # Skip if it matches skip patterns
        if any(s in url for s in skip):
            continue

        try:
            from urllib.parse import urlparse
            parsed = urlparse(url)
            domain = parsed.netloc
            path = parsed.path
        except:
            continue

        key = f"{domain}{path.split('?')[0]}"
        if key in seen:
            continue
        seen.add(key)

        # Only show likely video/player domains
        if any(x in domain for x in [
            'vidsrc', 'embed', 'player', 'stream', 'watch', 'movie',
            'video', 'play', 'multi', 'source', 'server', 'film',
            'show', 'series', 'anime', 'cdn', 'media', 'hls', 'm3u8',
            'sup', 'sub', 'caption', 'api', '.ru', '.net', '.io', '.me',
            '.to', '.cc', '.xyz', '.vip', '.pro', '.tv'
        ]):
            providers.append(url)

    for p in sorted(providers):
        print(p)

find_all_providers("HTTPToolkit_2026-04-19_16-55.har")
