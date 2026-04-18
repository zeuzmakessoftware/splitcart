import httpx
import json
import os
from pathlib import Path

def test_itemize():
    # FastAPI default port is 8000
    url = "http://localhost:8000/itemize"
    
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
            
            # 60 second timeout for Gemini processing
            response = httpx.post(url, files=files, timeout=60.0)
            
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
