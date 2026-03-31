# AGENTS.md - Superpower Wardrobe

This document provides guidance for AI agents working on this codebase.

## Project Overview

A native mobile wardrobe management app (iOS + Android) with AI-powered clothing classification and outfit recommendations. Backend uses Supabase (PostgreSQL + Edge Functions) + Python microservices.

## Project Structure

```
superpower-wardrobe/
├── ios/SuperWardrobe/           # iOS SwiftUI app (Swift 5.9+, iOS 17+)
├── android/superwardrobe/       # Android Kotlin app (Compose)
├── supabase/
│   ├── migrations/              # PostgreSQL migrations
│   └── functions/               # Supabase Edge Functions (TypeScript/Deno)
├── services/
│   ├── backend/                 # Python FastAPI backend
│   └── fashion-clip/           # FashionCLIP AI service (Python FastAPI)
├── web-demo/                    # Web testing interface
└── Makefile                     # Deployment commands
```

---

## Build & Test Commands

### Python Services (FashionCLIP)

```bash
# Install dependencies
pip install -r services/fashion-clip/requirements.txt
pip install -r services/fashion-clip/requirements-dev.txt

# Run tests
cd services/fashion-clip
pytest                    # Run all tests
pytest tests/             # Run specific test directory
pytest tests/test_classify.py -v    # Run single test file

# Run service
cd services/fashion-clip
uvicorn main:app --reload --port 8000

# Docker
docker build -t fashion-clip services/fashion-clip/
docker run -p 8000:8000 fashion-clip
```

### Supabase Edge Functions (TypeScript/Deno)

```bash
# Deploy single function
supabase functions deploy recommend --project-ref <ref>
supabase functions deploy purchase-suggest --project-ref <ref>

# Run tests (logic tests use custom assert functions)
deno run -A supabase/functions/recommend/recommend_logic_test.ts

# Local development
supabase functions serve recommend --local
```

### iOS (Swift)

```bash
# Open in Xcode
open ios/SuperWardrobe/Package.swift

# Build via Xcode (Cmd+B)
# Run via Xcode (Cmd+R)
```

### Android (Kotlin)

```bash
cd android/superwardrobe

# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# Run tests
./gradlew test

# Clean and rebuild
./gradlew clean assembleDebug
```

### Docker Services

```bash
# Start all services
make docker-up

# Stop services
make docker-down

# View logs
make docker-logs

# Rebuild
make docker-rebuild
```

### Full Deployment

```bash
# Deploy Supabase (DB + Edge Functions)
make setup-all ACCESS_TOKEN=<token> OPENWEATHER_KEY=<key>

# Verify deployment
make verify
```

---

## Code Style Guidelines

### General

- **Database columns**: Use `snake_case` (e.g., `user_id`, `created_at`)
- **API responses**: Use camelCase for JSON keys
- **Error handling**: Return proper HTTP status codes (200, 400, 404, 500)
- **Logging**: Include meaningful error messages for debugging

### Swift (iOS)

- **Naming**: PascalCase for types/structs, camelCase for variables/properties
- **Structs**: Use `Codable` for API serialization
- **Database mapping**: Use `CodingKeys` enum for snake_case ↔ camelCase conversion
- **Dependencies**: Use Swift Package Manager (see `Package.swift`)

```swift
struct ClothingItem: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
    }
}
```

### TypeScript (Supabase Edge Functions)

- **Runtime**: Deno (not Node.js)
- **Imports**: Use full URLs for external imports
- **Typing**: Always define types for request/response bodies
- **Database queries**: Use Supabase JS client

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ClothingItem {
    id: string;
    category: string;
    color: string;
}
```

### Python (FastAPI Services)

- **Style**: Follow PEP 8
- **Typing**: Use type hints for all function parameters and return types
- **Pydantic**: Use Pydantic `BaseModel` for request/response validation
- **HTTP exceptions**: Use `HTTPException` with appropriate status codes

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

class ClassifyRequest(BaseModel):
    image_url: str

@app.post("/classify")
def classify(req: ClassifyRequest):
    if not req.image_url:
        raise HTTPException(status_code=400, detail="image_url required")
```

### Android (Kotlin)

- **UI**: Jetpack Compose
- **Architecture**: Follow Android best practices
- **Naming**: PascalCase for classes, camelCase for functions/variables

---

## Testing Guidelines

### Python Tests (pytest)

- Use `unittest.mock.patch` to mock external dependencies
- Test both success and error cases
- Use descriptive test names: `test_<function>_<expected_behavior>`

```python
def test_classify_returns_confidence_scores():
    with patch("main.classify_image", return_value=mock_result):
        response = client.post("/classify", json={"image_url": "https://example.com/img.jpg"})
    assert response.status_code == 200
```

### TypeScript Tests (Deno)

- Edge function logic tests use custom `assert()` functions
- Run directly with `deno run -A <test_file>.ts`
- Tests should verify scoring algorithms and data transformations

---

## Database Conventions

- **Tables**: snake_case plural (e.g., `clothing_items`, `preset_outfits`)
- **Columns**: snake_case (e.g., `user_id`, `image_url`)
- **Primary keys**: UUID stored as string
- **Timestamps**: UTC, ISO 8601 format
- **Junction tables**: `<table1>_<table2>` (e.g., `outfit_items`)

---

## Environment Variables

Required variables (see `.env.example`):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
OPENWEATHER_API_KEY=<openweathermap-key>
```

---

## Common Tasks

### Adding a New Edge Function

1. Create directory in `supabase/functions/<function-name>/`
2. Create `index.ts` with handler
3. Add tests in `<function-name>_test.ts`
4. Deploy: `supabase functions deploy <function-name> --project-ref <ref>`

### Adding a New Clothing Category

1. Update database: Add to `clothing_categories` table
2. Update Python service: Add label to `CATEGORY_LABELS` in `main.py`
3. Update Swift model: Add to relevant enum/struct
4. Update Android model: Add to relevant data class

### Modifying Database Schema

1. Create new migration in `supabase/migrations/`
2. Test locally: Apply migration via Supabase CLI
3. Deploy: `make db-migrate ACCESS_TOKEN=<token>`
