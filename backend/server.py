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

# Simple persistence for user profiles
PROFILES_FILE = Path(__file__).parent / "profiles.json"

def load_profiles():
    if not PROFILES_FILE.exists():
        return {"users": {}}
    with open(PROFILES_FILE, "r") as f:
        return json.load(f)

def save_profiles(profiles):
    with open(PROFILES_FILE, "w") as f:
        json.dump(profiles, f, indent=2)

@app.route('/profiles', methods=['GET'])
def get_profiles():
    return jsonify(load_profiles())

@app.route('/swipe', methods=['POST'])
def save_swipe():
    data = request.json
    user_id = data.get("user_id", "default")
    item = data.get("item")
    feedback = data.get("feedback")
    
    if not item or not feedback:
        return jsonify({"error": "Missing item or feedback"}), 400
    
    profiles = load_profiles()
    if user_id not in profiles["users"]:
        profiles["users"][user_id] = {"likes": [], "passes": [], "tags": {}}
    
    user = profiles["users"][user_id]
    if feedback in ["like", "love"]:
        user["likes"].append(item["name"])
        # Update tag preferences
        for tag in item.get("tags", []):
            user["tags"][tag] = user["tags"].get(tag, 0) + 1
    else:
        user["passes"].append(item["name"])
        for tag in item.get("tags", []):
            user["tags"][tag] = user["tags"].get(tag, 0) - 1
            
    save_profiles(profiles)
    return jsonify({"status": "success"})

@app.route('/split', methods=['POST'])
def split_bill():
    data = request.json
    items = data.get("items", [])
    if not items:
        return jsonify({"error": "No items to split"}), 400
        
    profiles = load_profiles()
    users = profiles.get("users", {})
    
    if not users:
        return jsonify({"error": "No user profiles found. Please train the model first."}), 400
        
    assignment = []
    
    for item in items:
        scores = {}
        item_tags = set(item.get("tags", []))
        
        for u_id, u_data in users.items():
            user_tags = u_data.get("tags", {})
            # Calculate match score based on common tags
            score = 0
            for tag in item_tags:
                score += user_tags.get(tag, 0)
                
            # Bonus for exact name match in previous likes
            if item["name"] in u_data.get("likes", []):
                score += 10
                
            scores[u_id] = score
            
        # Determine winner
        best_user = max(scores, key=scores.get)
        confidence = scores[best_user]
        
        # If score is too low or tie, mark as shared
        if confidence <= 0:
            target = "Shared"
        else:
            target = best_user
            
        assignment.append({
            "item_name": item["name"],
            "price": item["price"],
            "assigned_to": target,
            "confidence": confidence
        })
        
    return jsonify({
        "assignment": assignment,
        "summary": { u_id: sum(float(a["price"].replace("$","")) for a in assignment if a["assigned_to"] == u_id) for u_id in list(users.keys()) + ["Shared"] }
    })

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
        
        # Post-process to ensure premium, relevant images
        for item in data.get("items", []):
            category = item.get("categories", ["All"])[-1] # Use the most specific category
            if category in UNSPLASH_MAPPING:
                # Add the curated image as the primary image
                item["images"] = [UNSPLASH_MAPPING[category]] + item["images"][:1]
        
        return jsonify(data)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if temp_path.exists():
            temp_path.unlink()

if __name__ == '__main__':
    app.run(port=5001, debug=True)
