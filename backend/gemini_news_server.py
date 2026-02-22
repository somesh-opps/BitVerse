import os
import json
import re
import textwrap
from google import genai
from flask import Flask, request, jsonify
from flask_cors import CORS

# ─────────────────────────────
#  CONFIG
# ─────────────────────────────
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyDA6CQgVB5ycY0BQoWLm_Kc8zRgdAkg_NA")

MODEL_NAME         = "gemini-2.0-flash"
MODEL_NAME_FALLBACK = "models/gemini-2.5-flash"
PORT               = 8001

VALID_CATEGORIES = [
    "Disease Alert",
    "Weather",
    "Market",
    "Fertilizer",
    "Seasonal Tips",
    "Pest Control",
    "Technology",
    "Soil Health",
]

app = Flask(__name__)
CORS(app)


# ─────────────────────────────
#  HELPERS
# ─────────────────────────────

def _build_prompt(region: str, weather_data: str, soil_data: str, plants: list[str]) -> str:
    plants_str   = ", ".join(plants) if plants else "general crops"
    weather_str  = weather_data if weather_data else "not specified"
    soil_str     = soil_data    if soil_data    else "not specified"

    return textwrap.dedent(f"""
        You are an expert agricultural news editor for CropIntel, an AI-powered farming assistant.

        Generate exactly 8 unique, realistic, and informative news articles relevant to farmers.

        Context:
        - Region: {region}
        - Weather conditions: {weather_str}
        - Soil data: {soil_str}
        - Crops / plants of interest: {plants_str}

        Each article must belong to exactly one of these categories:
        {json.dumps(VALID_CATEGORIES)}

        Try to cover a variety of categories across the 8 articles.

        Return ONLY a valid JSON array with no markdown fences, no extra text.
        Each element must have exactly these keys:
        {{
          "title":        "<concise headline, max 80 chars>",
          "category":     "<one of the valid categories above>",
          "summary":      "<2-3 sentence summary, informative and relevant>",
          "full_content": "<4-6 paragraphs of detailed article content, separated by newline characters>"
        }}
    """).strip()


def _parse_articles(raw: str) -> list[dict]:
    """Extract and validate the JSON array from the model response."""
    # Strip potential markdown code fences
    raw = re.sub(r"```(?:json)?", "", raw).strip()

    articles = json.loads(raw)

    validated = []
    for art in articles:
        if not isinstance(art, dict):
            continue
        title        = str(art.get("title",        "")).strip()
        category     = str(art.get("category",     "General")).strip()
        summary      = str(art.get("summary",      "")).strip()
        full_content = str(art.get("full_content", "")).strip()

        if not title or not summary or not full_content:
            continue
        if category not in VALID_CATEGORIES:
            category = "Seasonal Tips"

        validated.append({
            "title":        title,
            "category":     category,
            "summary":      summary,
            "full_content": full_content,
        })

    return validated


# ─────────────────────────────
#  ROUTES
# ─────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "CropIntel News Feed"}), 200


@app.route("/news-feed", methods=["POST"])
def news_feed():
    body = request.get_json(silent=True) or {}

    region            = str(body.get("region",            "General")).strip() or "General"
    weather_data      = str(body.get("weather_data",      "")).strip()
    soil_data         = str(body.get("soil_data",         "")).strip()
    plants_of_interest = body.get("plants_of_interest",   [])

    if not isinstance(plants_of_interest, list):
        plants_of_interest = []

    prompt = _build_prompt(region, weather_data, soil_data, plants_of_interest)

    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
        # Try primary model, fall back to 1.5-flash on quota errors
        for model in (MODEL_NAME, MODEL_NAME_FALLBACK):
            try:
                response = client.models.generate_content(model=model, contents=prompt)
                raw_text = response.text
                break
            except Exception as inner_e:
                err_str = str(inner_e)
                if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                    if model == MODEL_NAME_FALLBACK:
                        return jsonify({
                            "success": False,
                            "message": "Gemini API quota exceeded. Please check your API key billing or try again tomorrow.",
                        }), 429
                    continue   # try next model
                raise          # re-raise non-quota errors
        else:
            return jsonify({"success": False, "message": "All Gemini models quota exhausted."}), 429
    except Exception as e:
        return jsonify({"success": False, "message": f"Gemini API error: {str(e)}"}), 502

    try:
        articles = _parse_articles(raw_text)
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Failed to parse Gemini response: {str(e)}",
            "raw":     raw_text,
        }), 500

    if not articles:
        return jsonify({"success": False, "error": "No valid articles returned by the model.", "raw": raw_text}), 500

    return jsonify({"success": True, "articles": articles}), 200


# ─────────────────────────────
#  ENTRY POINT
# ─────────────────────────────
if __name__ == "__main__":
    print(f"🌱 CropIntel News Feed server starting on http://127.0.0.1:{PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=True)
