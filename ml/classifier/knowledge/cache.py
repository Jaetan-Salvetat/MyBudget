"""Téléchargements des sources ouvertes, gardés sur disque entre deux runs."""

import json
import urllib.parse
import urllib.request
from pathlib import Path

from paths import CACHE_DIR

USER_AGENT = "MyBudget-quick-add/1.0 (https://github.com/Jaetan-Salvetat)"
TIMEOUT_SECONDS = 120


def fetch(url: str, filename: str, refresh: bool = False) -> Path:
    """Retourne le chemin local du fichier, en le téléchargeant si besoin."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    target = CACHE_DIR / filename
    if target.exists() and not refresh:
        return target

    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
        payload = response.read()
    target.write_bytes(payload)
    return target


def fetch_json(url: str, filename: str, refresh: bool = False) -> dict:
    return json.loads(fetch(url, filename, refresh).read_text(encoding="utf-8"))


def sparql(query: str, filename: str, refresh: bool = False) -> list[dict]:
    """Interroge le Wikidata Query Service et retourne les lignes de résultat."""
    endpoint = "https://query.wikidata.org/sparql?" + urllib.parse.urlencode(
        {"query": query, "format": "json"}
    )
    payload = fetch_json(endpoint, filename, refresh)
    return payload["results"]["bindings"]
