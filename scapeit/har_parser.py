import json, re, sys

from pathlib import Path


def load_har(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# Extract URLs with keywords related to video streaming operations
KEYWORDS = ["watch", "stream", "search", "season", "episode", "price", "rgshows.ru"]

pattern = re.compile(r"(?i)" + "|".join(map(re.escape, KEYWORDS)))


def extract_entries(har):
    entries = har.get("log", {}).get("entries", [])
    result = []
    for e in entries:
        request = e.get("request", {})
        url = request.get("url", "")
        if pattern.search(url):
            headers = {h["name"]: h["value"] for h in request.get("headers", [])}
            result.append(
                {"url": url, "method": request.get("method"), "headers": headers}
            )
    return result


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python har_parser.py <har_file>")
        sys.exit(1)
    har_path = Path(sys.argv[1])
    har = load_har(har_path)
    for item in extract_entries(har):
        print("URL:", item["url"])
        print("Method:", item["method"])
        print("Headers:")
        for k, v in item["headers"].items():
            print("  {}: {}".format(k, v))
        print("---")
