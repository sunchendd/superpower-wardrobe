import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


def test_health_endpoint():
    from main import app
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_classify_returns_category_color_tags():
    mock_result = {"category": "tops", "color": "white", "tags": ["casual", "tshirt", "knit"]}
    with patch("main.classify_image", return_value=mock_result):
        from main import app
        client = TestClient(app)
        response = client.post("/classify", json={"image_url": "https://example.com/shirt.jpg"})
    assert response.status_code == 200
    data = response.json()
    assert data["category"] in ["tops", "bottoms", "shoes", "outerwear", "accessories"]
    assert "color" in data
    assert isinstance(data["tags"], list)


def test_classify_empty_url_returns_400():
    with patch("main.classify_image", side_effect=ValueError("image_url is required")):
        from main import app
        client = TestClient(app)
        response = client.post("/classify", json={"image_url": ""})
    assert response.status_code == 400


def test_classify_result_parses_all_fields():
    mock_result = {"category": "bottoms", "color": "blue", "tags": ["denim", "casual", "streetwear"]}
    with patch("main.classify_image", return_value=mock_result):
        from main import app
        client = TestClient(app)
        response = client.post("/classify", json={"image_url": "https://example.com/jeans.jpg"})
    data = response.json()
    assert data["category"] == "bottoms"
    assert data["color"] == "blue"
    assert "denim" in data["tags"]
