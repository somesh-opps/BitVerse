"""
ollama_server.py  –  Local AI server for CropIntel
Wraps your Ollama-hosted model behind a clean REST API.

Endpoints:
  POST /analyze-image   – disease / crop image analysis (vision model)
  POST /chat            – general agricultural Q&A (text model)
  GET  /models          – list models available in your Ollama installation
  GET  /health          – liveness check

Start: python ollama_server.py
Port : 8002
"""

import os
import base64
import json
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

# ─────────────────────────────
#  CONFIG
# ─────────────────────────────
OLLAMA_BASE_URL  = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")

# Change these to whichever models you have pulled / imported in Ollama
VISION_MODEL     = os.getenv("VISION_MODEL", "llava")          # for image analysis
CHAT_MODEL       = os.getenv("CHAT_MODEL",   "llama3.2")       # for text Q&A

PORT = 8002

# ─────────────────────────────
#  APP INIT
# ─────────────────────────────
app = Flask(__name__)
CORS(app)


# ─────────────────────────────
#  HELPERS
# ─────────────────────────────

def _ollama_generate(model: str, prompt: str, images: list[str] | None = None) -> str:
    """
    Call Ollama's /api/generate endpoint.
    `images` should be a list of base64-encoded image strings (no prefix).
    Returns the full response text.
    """
    payload: dict = {
        "model": model,
        "prompt": prompt,
        "stream": False,
    }
    if images:
        payload["images"] = images

    try:
        resp = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json=payload,
            timeout=120,
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("response", "")
    except requests.exceptions.ConnectionError:
        raise RuntimeError(
            "Cannot connect to Ollama. Make sure it is running: ollama serve"
        )
    except requests.exceptions.Timeout:
        raise RuntimeError("Ollama request timed out. The model may need more time.")


def _image_to_base64(file_storage) -> str:
    """Convert a Flask FileStorage object to a base64 string."""
    raw = file_storage.read()
    return base64.b64encode(raw).decode("utf-8")


# ─────────────────────────────
#  ROUTES
# ─────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    """Check that both Flask and Ollama are reachable."""
    try:
        r = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        r.raise_for_status()
        ollama_ok = True
    except Exception:
        ollama_ok = False

    return jsonify({
        "flask": "ok",
        "ollama": "ok" if ollama_ok else "unreachable",
        "ollama_url": OLLAMA_BASE_URL,
    }), 200 if ollama_ok else 503


@app.route("/models", methods=["GET"])
def list_models():
    """Return models available in Ollama."""
    try:
        r = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        r.raise_for_status()
        models = [m["name"] for m in r.json().get("models", [])]
        return jsonify({"models": models})
    except Exception as e:
        return jsonify({"error": str(e)}), 502


@app.route("/analyze-image", methods=["POST"])
def analyze_image():
    """
    Analyze a crop / plant image for diseases, pests, or health status.

    Request (multipart/form-data):
      image   : image file (jpg / png / webp)
      prompt  : (optional) custom question about the image
      context : (optional) JSON string with extra info: region, crop_name, etc.

    Response JSON:
      {
        "analysis": "...",
        "model_used": "llava"
      }
    """
    if "image" not in request.files:
        return jsonify({"error": "No image file provided. Send as multipart field 'image'."}), 400

    image_file = request.files["image"]
    user_prompt = request.form.get("prompt", "").strip()
    context_raw = request.form.get("context", "{}")

    try:
        context = json.loads(context_raw)
    except json.JSONDecodeError:
        context = {}

    # Build the analysis prompt
    crop_name = context.get("crop_name", "the crop")
    region    = context.get("region", "unspecified region")
    extra     = user_prompt if user_prompt else (
        f"Analyze this image of {crop_name} from {region}. "
        "Identify any visible diseases, pests, nutrient deficiencies, or health issues. "
        "Provide: 1) Diagnosis, 2) Severity (low/medium/high), 3) Recommended treatment, "
        "4) Preventive measures for the future. Be concise and practical for a farmer."
    )

    b64_image = _image_to_base64(image_file)

    try:
        result = _ollama_generate(
            model=VISION_MODEL,
            prompt=extra,
            images=[b64_image],
        )
        return jsonify({
            "analysis": result,
            "model_used": VISION_MODEL,
        })
    except RuntimeError as e:
        return jsonify({"error": str(e)}), 503


@app.route("/chat", methods=["POST"])
def chat():
    """
    General agricultural Q&A using your local text model.

    Request JSON:
      {
        "message": "What fertilizer is best for wheat in clay soil?",
        "context": {                   // optional
          "region": "Punjab",
          "crop": "wheat",
          "season": "rabi"
        }
      }

    Response JSON:
      {
        "reply": "...",
        "model_used": "llama3.2"
      }
    """
    body = request.get_json(silent=True) or {}
    message = body.get("message", "").strip()

    if not message:
        return jsonify({"error": "Field 'message' is required."}), 400

    ctx      = body.get("context", {})
    region   = ctx.get("region", "general")
    crop     = ctx.get("crop", "general crops")
    season   = ctx.get("season", "current season")

    system_prefix = (
        f"You are a knowledgeable agricultural advisor for CropIntel. "
        f"The farmer is in {region}, growing {crop} during the {season} season. "
        "Give practical, concise advice.\n\n"
    )
    full_prompt = system_prefix + f"Farmer's question: {message}"

    try:
        reply = _ollama_generate(model=CHAT_MODEL, prompt=full_prompt)
        return jsonify({
            "reply": reply,
            "model_used": CHAT_MODEL,
        })
    except RuntimeError as e:
        return jsonify({"error": str(e)}), 503


# ─────────────────────────────
#  ENTRY POINT
# ─────────────────────────────
if __name__ == "__main__":
    print(f"  CropIntel Ollama Server")
    print(f"  Ollama URL  : {OLLAMA_BASE_URL}")
    print(f"  Vision model: {VISION_MODEL}")
    print(f"  Chat model  : {CHAT_MODEL}")
    print(f"  Listening on: http://0.0.0.0:{PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=True)
