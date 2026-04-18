import httpx
import json
from pathlib import Path


DEMO_PAYLOAD = {
    "friends": [
        {
            "id": "maya",
            "name": "Maya",
            "vibe": "Fresh plates and lighter proteins",
            "insight": "Her swipe history leans toward fresh, clean, protein-heavy picks.",
            "category_weights": {"produce": 1.1, "protein": 1.2, "organic": 1.0, "drinks": 0.5},
            "tag_weights": {"fresh": 1.2, "light": 1.0, "protein-forward": 1.1, "plant-forward": 0.8},
            "share_affinity": 0.5,
        },
        {
            "id": "jordan",
            "name": "Jordan",
            "vibe": "Big flavors and comfort picks",
            "insight": "Tends to absorb savory, indulgent, and comfort-food orders.",
            "category_weights": {"protein": 1.3, "pantry": 0.9, "snacks": 1.1, "dessert": 0.7},
            "tag_weights": {"savory": 1.2, "comfort-food": 1.15, "indulgent": 1.0, "shareable": 0.7},
            "share_affinity": 0.7,
        },
        {
            "id": "riley",
            "name": "Riley",
            "vibe": "Snacks, sweets, and group orders",
            "insight": "The model routes shareables and snacky sides here first.",
            "category_weights": {"snacks": 1.3, "dessert": 1.2, "drinks": 0.9, "shared": 1.1},
            "tag_weights": {"snacky": 1.2, "sweet": 1.1, "shareable": 1.2, "caffeinated": 0.7},
            "share_affinity": 1.0,
        },
    ],
    "group_bias": {
        "category_weights": {"protein": 0.8, "snacks": 0.6, "organic": 0.4},
        "tag_weights": {"fresh": 0.7, "savory": 0.5, "shareable": 0.6},
    },
}

def test_itemize():
    # FastAPI default port is 8000
    url = "http://localhost:8000/scan-and-split"
    
    # Path to the test receipt in the same directory
    receipt_path = Path(__file__).parent / "receipt.jpg"
    
    if not receipt_path.exists():
        print(f"Error: {receipt_path} not found.")
        print("Please ensure 'receipt.jpg' exists in the backend directory.")
        return

    print(f"--- SplitCart API Test ---")
    print(f"Endpoint: {url}")
    print(f"File:     {receipt_path.name}")
    print(f"Status:   Sending request (this may take a few seconds)...")

    try:
        with receipt_path.open("rb") as f:
            files = {"file": (receipt_path.name, f, "image/jpeg")}
            data = {"payload": json.dumps(DEMO_PAYLOAD)}
            
            # 60 second timeout for Gemini processing
            response = httpx.post(url, files=files, data=data, timeout=60.0)
            
            if response.status_code == 200:
                print("\n✅ Success! Received JSON response:")
                print("-" * 40)
                print(json.dumps(response.json(), indent=2))
                print("-" * 40)
            else:
                print(f"\n❌ Server returned error {response.status_code}:")
                print(response.text)
                
    except httpx.ConnectError:
        print("\n❌ Failed to connect to server.")
        print("Make sure the backend is running: `python main.py` or `uvicorn main:app --reload`")
    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")

if __name__ == "__main__":
    test_itemize()
