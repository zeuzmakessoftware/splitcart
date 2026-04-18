from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import os
import shutil
from pathlib import Path
from backend import itemize_receipt
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SplitCart API")

# Enable CORS for the webapp
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "SplitCart Backend is running"}

@app.post("/itemize")
async def api_itemize_receipt(file: UploadFile = File(...)):
    """
    Upload a receipt image and get itemized JSON response.
    """
    # Create temp directory if not exists
    temp_dir = Path(__file__).parent / "temp"
    temp_dir.mkdir(exist_ok=True)
    
    # Generate a unique temp filename to avoid collisions
    import uuid
    temp_filename = f"{uuid.uuid4()}_{file.filename}"
    temp_path = temp_dir / temp_filename
    
    try:
        # Save uploaded file
        with temp_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Call the itemization logic from backend.py
        result = itemize_receipt(str(temp_path))
        return JSONResponse(content=result)
    
    except Exception as e:
        print(f"Error processing receipt: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Cleanup temp file
        if temp_path.exists():
            temp_path.unlink()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
