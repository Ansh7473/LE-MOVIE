import json, requests, sys

HAR_PATH = r"D:\\CURSOR\\javascript.html\\python\\real world projects\\LE-MOVIE\\scapeit\\HTTPToolkit_2026-04-20_01-07.har"

with open(HAR_PATH, "r", encoding="utf-8") as f:
    har = json.load(f)

entries = har.get("log", {}).get("entries", [])

for idx, e in enumerate(entries, 1):
    req = e.get("request", {})
    url = req.get("url", "")
    method = req.get("method", "GET")
    headers = {h.get("name"): h.get("value") for h in req.get("headers", [])}

    try:
        resp = requests.request(method, url, headers=headers, timeout=10, stream=True)
        status = resp.status_code
        content_length = resp.headers.get("Content-Length", "unknown")
        preview_bytes = resp.raw.read(200)
        preview_hex = preview_bytes[:60].hex() + (
            "…" if len(preview_bytes) > 60 else ""
        )
        print(
            f"{idx:3d}. {method:6} {url.split('/')[-2:][0] if url else ''} → {status}"
        )
        print(f"  Headers: Content-Length={content_length}")
        print(f"  Preview (hex): {preview_hex}")
        print("---")
    except Exception as exc:
        print(f"{idx:3d}. {method:6} {url if url else 'N/A'} -- failed: {exc}")
        print("---")
