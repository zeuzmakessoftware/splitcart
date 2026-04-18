import os
import json
from pathlib import Path
from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
from google import genai
from google.genai import types
from dotenv import load_dotenv

app = Flask(__name__)
CORS(app)

load_dotenv(Path(__file__).parent / ".env")

def get_gemini_client():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY in .env")
    return genai.Client(api_key=api_key)

# Mapping categories to high-quality Unsplash images to ensure premium feel
UNSPLASH_MAPPING = {
    "Produce": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=800&q=80",
    "Protein": "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=800&q=80",
    "Pantry": "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=800&q=80",
    "Frozen": "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?auto=format&fit=crop&w=800&q=80",
    "Snacks": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=800&q=80",
    "Organic": "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80"
}

ENRICHED_SCHEMA = {
    "type": "object",
    "properties": {
        "store": {"type": "string"},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "integer"},
                    "name": {"type": "string"},
                    "brand": {"type": "string"},
                    "price": {"type": "string"},
                    "detail": {"type": "string"},
                    "matchScore": {"type": "integer"},
                    "images": {"type": "array", "items": {"type": "string"}},
                    "tags": {"type": "array", "items": {"type": "string"}},
                    "categories": {"type": "array", "items": {"type": "string"}},
                    "note": {"type": "string"}
                },
                "required": ["id", "name", "brand", "price", "detail", "matchScore", "images", "tags", "categories", "note"]
            }
        }
    },
    "required": ["store", "items"]
}

@app.route('/upload', methods=['POST'])
def handle_upload():
    if 'receipt' not in request.files:
        return jsonify({"error": "No receipt file provided"}), 400
    
    file = request.files['receipt']
    temp_path = Path(__file__).parent / "temp_receipt.jpg"
    file.save(temp_path)
    
    try:
        client = get_gemini_client()
        image = Image.open(temp_path)
        
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                """Extract items from this receipt and enrich them for a high-end personal shopping UI.
                
                Rules:
                - Return only the JSON object.
                - Use categories: All, Produce, Protein, Pantry, Frozen, Snacks, Organic.
                - For images, use high-quality Unsplash URLs (e.g. https://images.unsplash.com/photo-...) relevant to the item.
                - matchScore should be 80-98.
                - tags should be sophisticated (e.g., 'Artisanal', 'Cold Pressed', 'Grass Fed').
                - note should be a short, premium curation insight.
                """,
                image,
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ENRICHED_SCHEMA,
                temperature=0.1,
            ),
        )
        
        data = json.loads(response.text)
        return jsonify(data)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if temp_path.exists():
            temp_path.unlink()

if __name__ == '__main__':
    app.run(port=5001, debug=True)
