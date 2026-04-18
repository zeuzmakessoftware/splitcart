from pathlib import Path
import shutil

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from backend import itemize_receipt, scan_and_split_receipt

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


class GroupBiasPayload(BaseModel):
    category_weights: dict[str, float] = Field(default_factory=dict)
    tag_weights: dict[str, float] = Field(default_factory=dict)


class FriendProfilePayload(BaseModel):
    id: str
    name: str
    vibe: str = ""
    insight: str = ""
    category_weights: dict[str, float] = Field(default_factory=dict)
    tag_weights: dict[str, float] = Field(default_factory=dict)
    share_affinity: float = 0.4


class ScanAndSplitPayload(BaseModel):
    friends: list[FriendProfilePayload]
    group_bias: GroupBiasPayload = Field(default_factory=GroupBiasPayload)


def _write_upload(file: UploadFile) -> tuple[Path, Path]:
    temp_dir = Path(__file__).parent / "temp"
    temp_dir.mkdir(exist_ok=True)

    import uuid

    temp_filename = f"{uuid.uuid4()}_{file.filename}"
    temp_path = temp_dir / temp_filename

    with temp_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return temp_dir, temp_path


@app.post("/itemize")
async def api_itemize_receipt(file: UploadFile = File(...)):
    """
    Upload a receipt image and get itemized JSON response.
    """
    temp_path: Path | None = None

    try:
        _, temp_path = _write_upload(file)
        result = itemize_receipt(str(temp_path))
        return JSONResponse(content=result)

    except Exception as exc:
        print(f"Error processing receipt: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))

    finally:
        if temp_path and temp_path.exists():
            temp_path.unlink()


@app.post("/scan-and-split")
async def api_scan_and_split(
    file: UploadFile = File(...),
    payload: str = Form(...),
):
    """
    Upload a receipt image plus swipe-derived taste profiles and receive
    itemized lines, assignments, and friend totals in one response.
    """
    temp_path: Path | None = None

    try:
        parsed_payload = ScanAndSplitPayload.model_validate_json(payload)
        _, temp_path = _write_upload(file)
        result = scan_and_split_receipt(
            str(temp_path),
            friends=[friend.model_dump() for friend in parsed_payload.friends],
            group_bias=parsed_payload.group_bias.model_dump(),
        )
        return JSONResponse(content=result)

    except Exception as exc:
        print(f"Error processing split receipt: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))

    finally:
        if temp_path and temp_path.exists():
            temp_path.unlink()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
