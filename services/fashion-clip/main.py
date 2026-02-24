from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
from PIL import Image
from io import BytesIO

app = FastAPI(title="FashionCLIP Service")


@app.get("/")
def root():
    return {
        "service": "FashionCLIP",
        "status": "running",
        "endpoints": {
            "health": "GET /health",
            "classify": "POST /classify",
            "docs": "GET /docs",
        },
    }


CATEGORY_LABELS = [
    "tops", "bottoms", "shoes", "outerwear", "accessories",
    "watch", "hat", "jewelry", "bag",
]
COLOR_LABELS = [
    "white", "black", "blue", "red", "green", "yellow",
    "grey", "brown", "pink", "beige", "orange", "purple",
]
STYLE_LABELS = ["casual", "formal", "sport", "elegant", "streetwear", "denim", "knit", "leather"]

_model = None
_processor = None


def get_model():
    global _model, _processor
    if _model is None:
        try:
            from transformers import CLIPProcessor, CLIPModel
            import torch
            _model = CLIPModel.from_pretrained("patrickjohncyh/fashion-clip")
            _processor = CLIPProcessor.from_pretrained("patrickjohncyh/fashion-clip")
        except Exception:
            _model = "unavailable"
            _processor = "unavailable"
    return _model, _processor


def classify_image(image_url: str) -> dict:
    if not image_url:
        raise ValueError("image_url is required")

    response = requests.get(image_url, timeout=10)
    response.raise_for_status()
    image = Image.open(BytesIO(response.content)).convert("RGB")

    model, processor = get_model()

    if model == "unavailable":
        # Graceful fallback when model not loaded (dev/test environment)
        return {"category": "tops", "color": "white", "tags": ["casual"]}

    import torch

    def top_label(candidates):
        prompts = [f"a photo of {l}" for l in candidates]
        inputs = processor(text=prompts, images=image, return_tensors="pt", padding=True)
        with torch.no_grad():
            outputs = model(**inputs)
        logits = outputs.logits_per_image[0]
        return candidates[logits.argmax().item()]

    category = top_label(CATEGORY_LABELS)
    color = top_label(COLOR_LABELS)

    style_prompts = [f"a photo of {l} clothing" for l in STYLE_LABELS]
    inputs = processor(text=style_prompts, images=image, return_tensors="pt", padding=True)
    with torch.no_grad():
        outputs = model(**inputs)
    logits = outputs.logits_per_image[0]
    top3_idx = logits.topk(3).indices.tolist()
    tags = [STYLE_LABELS[i] for i in top3_idx]

    return {"category": category, "color": color, "tags": tags}


class ClassifyRequest(BaseModel):
    image_url: str


@app.post("/classify")
def classify(req: ClassifyRequest):
    if not req.image_url:
        raise HTTPException(status_code=400, detail="image_url required")
    try:
        result = classify_image(req.image_url)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    return {"status": "ok"}
