import http.client
import json
import os
import time
import urllib.request

API_URL = "https://openrouter.ai/api/v1/chat/completions"
API_KEY_VARIABLE = "OPENROUTER_API_KEY"
DEFAULT_MODEL = "google/gemini-3.8-flash"
MAX_ATTEMPTS = 5
BACKOFF_SECONDS = 4.0
TIMEOUT_SECONDS = 180
FENCE = "```"


def api_key() -> str:
    key = os.environ.get(API_KEY_VARIABLE)
    if not key:
        raise RuntimeError(f"{API_KEY_VARIABLE} manquante")
    return key


def parse_json_payload(text: str):
    body = text.strip()
    if body.startswith(FENCE):
        body = body.split("\n", 1)[1]
        body = body.rsplit(FENCE, 1)[0]
    return json.loads(body)


def complete_json(
    system: str, user: str, model: str = DEFAULT_MODEL, temperature: float = 0.9
):
    last_error: Exception | None = None
    for _ in range(MAX_ATTEMPTS):
        try:
            return parse_json_payload(complete(system, user, model, temperature))
        except json.JSONDecodeError as error:
            last_error = error
    raise RuntimeError(f"OpenRouter n'a pas rendu de JSON valide en {MAX_ATTEMPTS} essais : {last_error}")


def complete(
    system: str, user: str, model: str = DEFAULT_MODEL, temperature: float = 0.9
) -> str:
    payload = json.dumps(
        {
            "model": model,
            "temperature": temperature,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        API_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key()}",
            "Content-Type": "application/json",
        },
    )
    last_error: Exception | None = None
    for attempt in range(MAX_ATTEMPTS):
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                document = json.loads(response.read().decode("utf-8"))
            content = document["choices"][0]["message"]["content"]
            if not isinstance(content, str) or not content.strip():
                raise KeyError("réponse vide")
            return content
        except (OSError, http.client.HTTPException, KeyError, json.JSONDecodeError) as error:
            last_error = error
            time.sleep(BACKOFF_SECONDS * (attempt + 1))
    raise RuntimeError(f"OpenRouter injoignable après {MAX_ATTEMPTS} essais : {last_error}")
