# 🚀 Qdrant Semantic Search API

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.68+-green.svg)](https://fastapi.tiangolo.com/)
[![Qdrant](https://img.shields.io/badge/Qdrant-1.1+-red.svg)](https://qdrant.tech/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Production-ready FastAPI service for semantic search using Qdrant vector database and Ollama embeddings. Supports multi-tenant deployments, flexible filtering, and per-request configuration.**

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [API Documentation](#-api-documentation)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Testing](#-testing)
- [Advanced Usage](#-advanced-usage)
- [Contributing](#-contributing)

## ✨ Features

### Core Capabilities
- 🔍 **Semantic Search** - Vector similarity search using Qdrant
- 🤖 **Multiple Embedding Models** - Support for granite-embedding:30m, bge-m3, and more via Ollama
- 🎯 **Advanced Filtering** - Text matching, range filters, and combined conditions
- 📄 **Context Windows** - Retrieve surrounding pages for better context
- 🔄 **Batch Queries** - Process multiple search queries in a single request
- 🌐 **Multi-Tenant** - Per-request Qdrant URL and API key configuration

### Production Features
- 🐳 **Docker Ready** - Containerized deployment with docker-compose
- 🔐 **Environment-Based Config** - Separate dev/prod configurations
- 📊 **Structured Logging** - JSON logging with correlation IDs
- ⚡ **Connection Pooling** - Efficient resource management
- 🔄 **Auto-Restart** - Self-healing container configuration
- 🧪 **Comprehensive Tests** - 50+ automated test cases (98% pass rate)

### API-Driven Design
- 🎛️ **Per-Request Configuration** - Override Qdrant URL, API key, and embedding model per request
- 🔧 **Flexible Payload Handling** - Supports multiple collection structures
- 📈 **Health Checks** - Monitor service and dependency status
- 🚦 **CORS Enabled** - Ready for web applications

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Ollama service with embedding models
- Qdrant instance (local or cloud)

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api
```

### 2. Configure Environment
```bash
cp tamplate.env .env
# Edit .env with your configuration
```

**Required Environment Variables:**
```env
# Ollama Configuration
OLLAMA_HOST=http://your-ollama-host:11434

# Production Qdrant
PROD_QDRANT_URL=https://your-qdrant-instance:6333
PROD_QDRANT_API_KEY=your-api-key

# Embedding Model
DEFAULT_EMBEDDING_MODEL=granite-embedding:30m
DEFAULT_VECTOR_SIZE=384
```

### 3. Start Service
```bash
docker compose up -d
```

### 4. Verify Health
```bash
curl http://localhost:8001/health
```

### 5. Run Your First Search
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "your_collection",
    "search_queries": ["your search query"],
    "use_production": true,
    "limit": 5
  }'
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  Client Applications                    │
│  (Web, Mobile, CLI, etc.)               │
└────────────────┬────────────────────────┘
                 │ HTTP/HTTPS
                 │ Port 8001
                 ▼
┌─────────────────────────────────────────┐
│  FastAPI Application                    │
│  ┌───────────────────────────────────┐  │
│  │ Search Endpoint                   │  │
│  │ - Semantic search                 │  │
│  │ - Filtering & pagination          │  │
│  │ - Context window retrieval        │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ Health Check Endpoint             │  │
│  │ - Service status monitoring       │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │                    │
         │                    │
         ▼                    ▼
┌──────────────────┐  ┌──────────────────┐
│ Ollama Service   │  │ Qdrant Vector DB │
│ - Embeddings     │  │ - Collections    │
│ - granite-30m    │  │ - Vector search  │
│ - bge-m3         │  │ - Filtering      │
└──────────────────┘  └──────────────────┘
```

## 📚 API Documentation

### POST /search/filenames

**Fuzzy search on metadata.filename field and return matching filenames. Does not return page content - only unique filenames that match the query.**

#### Request Body
```json
{
  "query": "string (required, min 1)",
  "collection_name": "string (required, min 1)",
  "limit": "integer (optional, default 10, max 1000)",
  "use_production": "boolean (optional, default false)",
  "qdrant_url": "string (optional, override)",
  "qdrant_api_key": "string (optional, override)",
  "qdrant_verify_ssl": "boolean (optional, override)"
}
```

#### Response
```json
{
  "query": "ecos 9.3",
  "total_matches": 5,
  "filenames": [
    {
      "filename": "ECOS_9.3.7.0_Release_Notes_RevB",
      "score": null
    }
  ]
}
```

#### Examples

**Basic Filename Discovery:**
```bash
curl -X POST http://localhost:8001/search/filenames \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ecos 9.3",
    "collection_name": "content",
    "limit": 10
  }'
```

**Production Environment:**
```bash
curl -X POST http://localhost:8001/search/filenames \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ECOS_9.3.7.0_Release_Notes_RevB",
    "collection_name": "content",
    "limit": 1,
    "use_production": true
  }'
```

**Custom Qdrant Instance:**
```bash
curl -X POST http://localhost:8001/search/filenames \
  -H "Content-Type: application/json" \
  -d '{
    "query": "release notes",
    "collection_name": "my_collection",
    "limit": 100,
    "qdrant_url": "https://my-qdrant.cloud:6333",
    "qdrant_api_key": "my-secret-key"
  }'
```

### POST /search

**Semantic search with advanced filtering and configuration options.**

#### Request Body

```json
{
  "collection_name": "string (required)",
  "search_queries": ["string (required, min 1)"],
  "embedding_model": "string (optional, default from env)",
  "filter": {
    "metadata.field": {
      "match_text": "string or array",
      "match_value": "any or array",
      "gte": "number",
      "lte": "number"
    }
  },
  "limit": "integer (optional, default 5)",
  "context_window_size": "integer (optional, default 5)",
  "use_production": "boolean (optional, default false)",
  "qdrant_url": "string (optional, override)",
  "qdrant_api_key": "string (optional, override)",
  "qdrant_verify_ssl": "boolean (optional, override)"
}
```

#### Response

```json
{
  "results": [
    [
      {
        "filename": "document.pdf",
        "score": 0.95,
        "content": "matched content...",
        "metadata": {...}
      }
    ]
  ]
}
```

#### Examples

**Basic Search:**
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "documents",
    "search_queries": ["machine learning"],
    "limit": 10
  }'
```

**Search with Filtering:**
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "documents",
    "search_queries": ["installation guide"],
    "embedding_model": "bge-m3",
    "filter": {
      "metadata.filename": {"match_text": "ECOS"},
      "metadata.page_number": {"gte": 1, "lte": 10}
    },
    "use_production": true,
    "limit": 5
  }'
```

**Multi-Tenant Search (Custom Qdrant):**
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "my_collection",
    "search_queries": ["query"],
    "qdrant_url": "https://my-qdrant.cloud:6333",
    "qdrant_api_key": "my-secret-key",
    "limit": 5
  }'
```

### GET /health

**Check service health and dependency status.**

#### Response

```json
{
  "status": "ok",
  "services": {
    "qdrant": "ok",
    "ollama": "ok"
  }
}
```

## 🔐 API Key Authentication

### Overview
All API endpoints support optional API key authentication using Bearer tokens. When enabled, all requests must include an `Authorization` header.

### Setup

#### 1. Generate API Key
```bash
# Generate a secure random API key
openssl rand -hex 32
```

#### 2. Configure Environment Variables
```env
# Enable API key authentication
API_KEY_ENABLED=true

# Your secret API key
API_KEY=your-generated-api-key-here
```

#### 3. Make Authenticated Requests
```bash
# Include Authorization header in all requests
curl -X POST http://localhost:8001/search/filenames \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key-here" \
  -d '{
    "query": "ecos",
    "collection_name": "content",
    "limit": 10
  }'
```

### Security Features

- ✅ **Bearer Token Authentication** - Industry standard (same as AWS, GitHub, Stripe)
- ✅ **HTTPS Encrypted** - API keys are encrypted in transit when using HTTPS
- ✅ **Optional Authentication** - Can be disabled for development (`API_KEY_ENABLED=false`)
- ✅ **All Endpoints Protected** - `/search`, `/search/filenames`, and `/health` all require authentication when enabled

### Error Responses

**Missing API Key (401 Unauthorized):**
```json
{"detail": "Missing authentication credentials"}
```

**Invalid API Key (403 Forbidden):**
```json
{"detail": "Invalid API key"}
```

### MCP Server Configuration

The MCP server automatically includes the API key in all requests when configured:

```env
# mcp-server/.env
API_KEY=your-api-key-here
```

The MCP server `config.py` automatically adds the `Authorization: Bearer <API_KEY>` header to all HTTP requests.

---

## ⚙️ Configuration

### Environment Variables

#### API Key Authentication
```env
# Enable/disable API key authentication
API_KEY_ENABLED=false

# Your secret API key (generate with: openssl rand -hex 32)
API_KEY=
```

#### Ollama Configuration
```env
OLLAMA_HOST=http://192.168.254.22:11434
```

#### Development Qdrant
```env
DEV_QDRANT_URL=http://localhost:6333
DEV_QDRANT_API_KEY=
DEV_QDRANT_VERIFY_SSL=false
```

#### Production Qdrant
```env
PROD_QDRANT_URL=https://your-instance.cloud.qdrant.io:6333
PROD_QDRANT_API_KEY=your-api-key
PROD_QDRANT_VERIFY_SSL=true
```

#### Embedding Provider Configuration

```env
# Provider: "ollama" (default) or "gemini"
EMBEDDING_PROVIDER=ollama

# Embedding model & vector size (must match Qdrant collection configuration)
DEFAULT_EMBEDDING_MODEL=granite-embedding:30m
DEFAULT_VECTOR_SIZE=384

# Gemini configuration (only used when EMBEDDING_PROVIDER=gemini)
GEMINI_API_KEY=
GEMINI_EMBEDDING_MODEL=gemini-embedding-001
GEMINI_EMBEDDING_TASK_TYPE=RETRIEVAL_QUERY
GEMINI_EMBEDDING_DIM=768
```

##### Choosing a Provider

- **Ollama (default)**
  - Runs embeddings locally via your Ollama server.
  - Best when you control the infrastructure and want low external dependencies.
- **Gemini**
  - Uses Google Gemini Embeddings API for query-time embeddings.
  - Set `EMBEDDING_PROVIDER=gemini` and configure the `GEMINI_*` variables.
  - Ensure your Qdrant collection vector size matches `GEMINI_EMBEDDING_DIM` (for example, 768).

#### Qdrant configuration precedence & overrides

The service builds the Qdrant client using the following precedence:

1. **Request parameters** (if provided):
   - `qdrant_url`
   - `qdrant_api_key`
   - `qdrant_verify_ssl`
2. **Environment-specific variables** (based on `use_production` flag):
   - Dev: `DEV_QDRANT_URL`, `DEV_QDRANT_API_KEY`, `DEV_QDRANT_VERIFY_SSL`
   - Prod: `PROD_QDRANT_URL`, `PROD_QDRANT_API_KEY`, `PROD_QDRANT_VERIFY_SSL`
3. **Generic env variables**: `QDRANT_URL`, `QDRANT_API_KEY`, `QDRANT_VERIFY_SSL`
4. **Fallback**: `QDRANT_HOST` with HTTP and default SSL settings

Rules:

- If you set any of `qdrant_url`, `qdrant_api_key`, or `qdrant_verify_ssl` in the request body,
  you **must not** set `use_production=true`. That combination is rejected with an error.
- If no request-level Qdrant fields are provided, `use_production` controls whether the
  DEV or PROD env variables are used.
- `QDRANT_FORCE_IGNORE_SSL=true` globally disables SSL verification unless `qdrant_verify_ssl`
  is explicitly set on the request.

#### Embedding provider overrides

Embedding provider selection is currently **env-only**:

- `EMBEDDING_PROVIDER` (`ollama` or `gemini`) is read from the environment at startup.
- When `EMBEDDING_PROVIDER=ollama`, the service uses the configured Ollama host/model.
- When `EMBEDDING_PROVIDER=gemini`, the service uses the configured Gemini API key,
  model, task type, and output dimension (`GEMINI_*` variables).

There are **no request-level fields** to override the embedding provider or Gemini
API key/model per call in this phase. All embedding configuration is controlled by
environment variables.

#### Application Settings
```env
ENVIRONMENT=production
CONTEXT_WINDOW_SIZE=5
REQUEST_TIMEOUT=30
DEBUG=false
```

### Embedding Model Mapping

| Collection Type | Embedding Model | Vector Size |
|----------------|-----------------|-------------|
| filenames | granite-embedding:30m | 384 |
| content | bge-m3 | 1024 |
| custom | mxbai-embed-large | 1024 |

## 🐳 Deployment

### Docker Compose (Recommended)

```bash
# Start service
docker compose up -d

# View logs
docker compose logs -f search_api

# Restart service
docker compose restart

# Stop service
docker compose down
```

### Manual Docker Build

```bash
# Build image
docker build -t qdrant-search-api ./app

# Run container
docker run -d \
  --name search_api \
  -p 8001:8000 \
  --env-file .env \
  qdrant-search-api
```

### Production Deployment Checklist

- [ ] Configure production Qdrant URL and API key
- [ ] Set `ENVIRONMENT=production`
- [ ] Enable SSL verification (`PROD_QDRANT_VERIFY_SSL=true`)
- [ ] Configure Ollama service endpoint
- [ ] Set up HTTPS/TLS for API endpoint
- [ ] Configure rate limiting (if needed)
- [ ] Set up monitoring and logging
- [ ] Test health check endpoint
- [ ] Run comprehensive test suite
- [ ] Configure backup and recovery

## 🧪 Testing

### Run Comprehensive Test Suite

```bash
# Execute all 51 tests
./comprehensive_tests.sh
```

**Test Coverage:**
- ✅ Basic search operations (5 tests)
- ✅ Batch query processing (5 tests)
- ✅ Text filtering (10 tests)
- ✅ Range filtering (5 tests)
- ✅ Combined filters (5 tests)
- ✅ Context windows (5 tests)
- ✅ Embedding models (3 tests)
- ✅ Version-specific searches (7 tests)
- ✅ Edge cases (5 tests)
- ✅ Health checks (1 test)

**Expected Results:** 50/51 tests passing (98% success rate)

### Manual Testing

```bash
# Test health endpoint
curl http://localhost:8001/health

# Test basic search
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test",
    "search_queries": ["test query"],
    "limit": 3
  }'
```

## 🔧 Advanced Usage

### Custom Filtering

#### Text Matching
```json
{
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS"
    }
  }
}
```

#### Array Matching (OR Logic)
```json
{
  "filter": {
    "metadata.filename": {
      "match_text": ["ECOS", "Orchestrator"]
    }
  }
}
```

#### Range Filtering
```json
{
  "filter": {
    "metadata.page_number": {
      "gte": 1,
      "lte": 10
    }
  }
}
```

#### Combined Filters (AND Logic)
```json
{
  "filter": {
    "metadata.filename": {"match_text": "ECOS"},
    "metadata.page_number": {"gte": 1, "lte": 20}
  }
}
```

### Context Window Retrieval

Retrieve surrounding pages for better context:

```json
{
  "collection_name": "content",
  "search_queries": ["installation"],
  "context_window_size": 10,
  "limit": 2
}
```

Returns matched page ± 10 pages (21 pages total per result).

### Batch Queries

Process multiple queries in one request:

```json
{
  "collection_name": "documents",
  "search_queries": [
    "installation guide",
    "troubleshooting",
    "configuration"
  ],
  "limit": 5
}
```

Returns array of result arrays (one per query).

## 📖 Documentation

 - [System & API Specification](docs/SYSTEM_SPEC.md) - Architecture, technical details, and implementation notes
 - [Quick Test Reference](docs/QUICK_TEST_REFERENCE.md) - Common usage patterns and key test examples
 - [Test Documentation](docs/TEST_DOCUMENTATION.md) - Detailed test suite information

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r app/requirements.txt

# Run locally
cd app
uvicorn main:app --reload --port 8000
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Qdrant](https://qdrant.tech/) - Vector similarity search engine
- [FastAPI](https://fastapi.tiangolo.com/) - Modern web framework
- [Ollama](https://ollama.ai/) - Local LLM and embedding models
- [Pydantic](https://pydantic-docs.helpmanual.io/) - Data validation

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/qdrant-semantic-search-api/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/qdrant-semantic-search-api/discussions)

## 🗺️ Roadmap

- [ ] Add authentication and authorization
- [ ] Implement rate limiting
- [ ] Add caching layer
- [ ] Support for more embedding models
- [ ] GraphQL API support
- [ ] Streaming responses
- [ ] Async batch processing
- [ ] Metrics and monitoring dashboard

---

**Built with ❤️ for semantic search enthusiasts**

**Keywords**: semantic search, vector database, qdrant, fastapi, ollama, embeddings, similarity search, RAG, retrieval augmented generation, python api, docker, multi-tenant, production-ready
