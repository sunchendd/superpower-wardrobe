import pytest
import base64
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from PIL import Image
from io import BytesIO
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from main import app, BATCH_LIMIT

client = TestClient(app)


def _mock_classify_result():
    return {
        "category": {"label": "tops", "confidence": 0.92},
        "color": {"label": "blue", "confidence": 0.87},
        "tags": [
            {"label": "casual", "confidence": 0.85},
            {"label": "streetwear", "confidence": 0.72},
            {"label": "sport", "confidence": 0.60},
        ],
        "material": {"label": "cotton", "confidence": 0.78},
        "pattern": {"label": "solid", "confidence": 0.91},
    }


def _make_test_image_base64():
    img = Image.new("RGB", (10, 10), color="red")
    buf = BytesIO()
    img.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


# --- Health ---

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


# --- Classify: confidence scores ---

def test_classify_returns_confidence_scores():
    with patch("main.classify_image", return_value=_mock_classify_result()):
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data["category"], dict)
    assert "label" in data["category"]
    assert "confidence" in data["category"]
    assert 0 <= data["category"]["confidence"] <= 1

    assert isinstance(data["color"], dict)
    assert "label" in data["color"]
    assert "confidence" in data["color"]
    assert 0 <= data["color"]["confidence"] <= 1


def test_classify_tags_have_confidence():
    with patch("main.classify_image", return_value=_mock_classify_result()):
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    data = response.json()
    assert isinstance(data["tags"], list)
    for tag in data["tags"]:
        assert "label" in tag
        assert "confidence" in tag
        assert 0 <= tag["confidence"] <= 1


# --- Classify: material and pattern ---

def test_classify_returns_material_and_pattern():
    with patch("main.classify_image", return_value=_mock_classify_result()):
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    data = response.json()
    assert "material" in data
    assert isinstance(data["material"], dict)
    assert data["material"]["label"] in [
        "cotton", "polyester", "denim", "leather", "wool", "silk", "linen", "synthetic",
    ]
    assert 0 <= data["material"]["confidence"] <= 1

    assert "pattern" in data
    assert isinstance(data["pattern"], dict)
    assert data["pattern"]["label"] in [
        "solid", "striped", "plaid", "floral", "graphic", "polka_dot", "camo", "abstract",
    ]
    assert 0 <= data["pattern"]["confidence"] <= 1


# --- Classify: backward compatibility ---

def test_classify_backward_compatible_keys():
    with patch("main.classify_image", return_value=_mock_classify_result()):
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    data = response.json()
    assert "category" in data
    assert "color" in data
    assert "tags" in data


def test_classify_empty_url_returns_400():
    with patch("main.classify_image", side_effect=ValueError("image_url is required")):
        response = client.post("/classify", json={"image_url": ""})
    assert response.status_code == 400


# --- Remove background ---

def test_remove_background_with_url():
    mock_img = Image.new("RGBA", (10, 10), color=(0, 0, 0, 0))

    with patch("main._load_image", return_value=Image.new("RGB", (10, 10))):
        with patch("rembg.remove", return_value=mock_img):
            response = client.post("/remove-background", json={"image_url": "https://example.com/img.jpg"})

    assert response.status_code == 200
    data = response.json()
    assert "image_base64" in data
    assert data["format"] == "png"
    decoded = base64.b64decode(data["image_base64"])
    img = Image.open(BytesIO(decoded))
    assert img.format == "PNG"


def test_remove_background_with_base64():
    img_b64 = _make_test_image_base64()
    mock_img = Image.new("RGBA", (10, 10), color=(0, 0, 0, 0))

    with patch("main._load_image", return_value=Image.new("RGB", (10, 10))):
        with patch("rembg.remove", return_value=mock_img):
            response = client.post("/remove-background", json={"image_base64": img_b64})

    assert response.status_code == 200
    data = response.json()
    assert "image_base64" in data
    assert data["format"] == "png"


def test_remove_background_missing_input_returns_400():
    response = client.post("/remove-background", json={})
    assert response.status_code == 400


# --- Batch classify ---

def test_batch_classify_returns_results():
    with patch("main.classify_image", return_value=_mock_classify_result()):
        response = client.post(
            "/batch-classify",
            json={"images": [{"url": "https://example.com/a.jpg"}, {"url": "https://example.com/b.jpg"}]},
        )
    assert response.status_code == 200
    data = response.json()
    assert "results" in data
    assert len(data["results"]) == 2
    for r in data["results"]:
        assert r["status"] == "success"
        assert "category" in r
        assert "material" in r
        assert "pattern" in r


def test_batch_classify_handles_partial_failures():
    side_effects = [_mock_classify_result(), Exception("download failed")]
    with patch("main.classify_image", side_effect=side_effects):
        response = client.post(
            "/batch-classify",
            json={"images": [{"url": "https://example.com/a.jpg"}, {"url": "https://bad-url.com/x.jpg"}]},
        )
    assert response.status_code == 200
    data = response.json()
    assert data["results"][0]["status"] == "success"
    assert data["results"][1]["status"] == "error"


def test_batch_classify_exceeds_limit_returns_422():
    images = [{"url": f"https://example.com/{i}.jpg"} for i in range(BATCH_LIMIT + 1)]
    response = client.post("/batch-classify", json={"images": images})
    assert response.status_code == 422


def test_batch_classify_empty_list():
    response = client.post("/batch-classify", json={"images": []})
    assert response.status_code == 200
    assert response.json()["results"] == []
