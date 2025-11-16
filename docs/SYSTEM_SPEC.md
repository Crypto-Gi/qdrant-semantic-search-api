# Qdrant Semantic Search API – System Specification

## 1. High-Level System Specification

### 1.1 Purpose

The Qdrant Semantic Search API is a **FastAPI-based HTTP microservice** that exposes
semantic search over **Qdrant** vector collections using **Ollama** for embedding
generation. It is optimized for:

- Release-notes style corpora (e.g. ECOS / Orchestrator release notes)
- General-purpose semantic search with:
  - Multi-query batching
  - Flexible metadata filtering
  - Page-based context window retrieval
  - Dual development/production Qdrant configurations
  - Optional API key authentication

### 1.2 Architecture Overview

```text
Client (CLI, app, MCP server)
   |
   | HTTP (port 8001 -> 8000 in container)
   v
FastAPI app (app/main.py)
   |
   |-- SearchSystem  ----> Qdrant (vector DB)
   |       |              - collections: filenames, content (page-based)
   |       |
   |       '---> Ollama (embedding service)
   |
   |-- Auth (optional API key)
   |-- JSON logging + correlation IDs
```

**Major components**:

- **FastAPI app** (`app/main.py`)
  - Defines the web API, middleware, and dependencies.
  - Exposes three primary endpoints:
    - `GET /health`
    - `POST /search`
    - `POST /search/filenames`
- **SearchSystem class** (`app/main.py`)
  - Encapsulates Qdrant and Ollama client management.
  - Implements filter compilation, batch search, and page context windows.
- **Configuration layer** (`tamplate.env`, `.env`)
  - Environment-based configuration with DEV/PROD Qdrant options.
  - Configurable SSL, API keys, embedding models, and timeouts.
- **External services**
  - **Qdrant** – vector database storing embeddings.
  - **Ollama** – embedding generation service for query vectors.

### 1.3 Core Workflows

#### 1.3.1 Semantic Search (`POST /search`)

1. Client sends JSON request with:
   - `collection_name`
   - `search_queries` (array)
   - Optional `filter`, `embedding_model`, `limit`, `context_window_size`
   - Optional `use_production`, `qdrant_url`, `qdrant_api_key`, `qdrant_verify_ssl`
2. FastAPI validates the payload (Pydantic `SearchRequest`).
3. `SearchSystem` is instantiated:
   - Resolves Qdrant configuration from env and/or request overrides.
   - Ensures the collection exists (creates if missing) with configured vector size.
   - Reuses pooled Qdrant/Ollama clients when possible.
4. For each query string:
   - Generate an embedding via Ollama.
   - Build a `QueryRequest` with optional Qdrant filter.
5. Call `qclient.query_batch_points(...)` to get batched results.
6. For each result point:
   - If payload looks like page-based content (`metadata.filename` + `metadata.page_number`):
     - Fetch context pages around `center_page` using `_get_context_pages`.
     - Deduplicate `(filename, page_number)` pairs.
     - Return `{ filename, score, center_page, combined_page, page_numbers }`.
   - Otherwise (generic collection):
     - Return `{ score, filename, metadata? }`.
7. FastAPI wraps results in `{ "results": [[...], [...]] }` (one list per query).

#### 1.3.2 Filename Discovery (`POST /search/filenames`)

1. Client sends `query`, `collection_name`, optional `limit`, and optional Qdrant
   connection overrides.
2. Endpoint creates a Qdrant client with `_create_qdrant_client`.
3. Runs `scroll` with `MatchText` filter on `metadata.filename`.
4. Deduplicates filenames and returns up to `limit` unique matches.

#### 1.3.3 Health Check (`GET /health`)

- Returns a JSON document indicating overall status and whether Qdrant/Ollama
  pooled clients have been created successfully.


## 2. Technical Specification

### 2.1 HTTP API

#### 2.1.1 `GET /health`

- **Description**: Liveness and dependency status endpoint.
- **Authentication**: Optional. Required if `API_KEY_ENABLED=true`.
- **Response**:

```json
{
  "status": "ok",
  "services": {
    "qdrant": "ok" | "offline",
    "ollama": "ok" | "offline"
  }
}
```

#### 2.1.2 `POST /search`

- **Description**: Core semantic search endpoint with advanced filtering and
  optional context window retrieval.
- **Authentication**: Optional. Required if `API_KEY_ENABLED=true`.

**Request body (Pydantic `SearchRequest`):**

```jsonc
{
  "collection_name": "string",                  // required
  "search_queries": ["string", "string"],      // required, non-empty
  "filter": {                                     // optional
    "field.path": {
      "match_text": "string" | ["string", ...],
      "match_value": 123 | "value" | [1, 2, 3],
      "gte": 0,
      "lte": 100
    }
  },
  "embedding_model": "string",                  // optional; defaults to env
  "limit": 5,                                     // optional; >= 1
  "context_window_size": 5,                       // optional; >= 0
  "use_production": false,                        // optional; default false
  "qdrant_url": "https://...:6333",             // optional override
  "qdrant_api_key": "string",                   // optional override
  "qdrant_verify_ssl": true                       // optional override
}
```

**Filter semantics:**

- Each top-level key (e.g. `"metadata.filename"`, `"metadata.page_number"`) maps
  to one field condition.
- Supported condition types:
  - **Text matching (`match_text`)**
    - String → `MatchText(text=...)`.
    - Array → OR logic via `Filter(should=[FieldCondition(...), ...])`.
  - **Value matching (`match_value`)**
    - Scalar → `MatchValue(value=...)`.
    - Array → OR logic via `MatchAny(any=[...])`.
  - **Numeric ranges (`gte` / `lte`)**
    - Build `models.Range` with lower/upper bounds.
- All top-level field conditions are AND-ed together in a `models.Filter(must=...)`.

**Response shape:**

```jsonc
{
  "results": [
    [
      // For page-based collections (e.g. "content")
      {
        "filename": "document.pdf",
        "score": 0.95,
        "center_page": 42,
        "combined_page": "... context text ...",
        "page_numbers": [40, 41, 42, 43, 44]
      }
    ],
    [
      // For generic collections (e.g. filenames)
      {
        "score": 0.88,
        "filename": "ECOS_9.3.2.1_Release_Notes_RevB",
        "metadata": { "...": "..." }
      }
    ]
  ]
}
```

**Error handling:**

- `400 Bad Request`
  - Conflicting parameters (e.g. `use_production=true` AND custom Qdrant
    overrides).
  - Invalid filter configuration (`SearchException`).
- `422 Unprocessable Entity`
  - Pydantic validation errors (missing fields, invalid types, limit < 1, etc.).
- `500 Internal Server Error`
  - Unhandled exceptions.

#### 2.1.3 `POST /search/filenames`

- **Description**: Fuzzy search against `metadata.filename`, returning unique
  filenames only (no page content).
- **Authentication**: Optional. Required if `API_KEY_ENABLED=true`.

**Request body (Pydantic `FilenameSearchRequest`):**

```jsonc
{
  "query": "string",                // required
  "collection_name": "string",      // required
  "limit": 10,                        // optional; 1–1000
  "use_production": false,           // optional
  "qdrant_url": "https://...",      // optional
  "qdrant_api_key": "string",       // optional
  "qdrant_verify_ssl": true          // optional
}
```

**Response:**

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

**Implementation:**

- Uses `_create_qdrant_client(...)` to build a Qdrant client.
- Calls `scroll` with `MatchText` on `metadata.filename`.
- Deduplicates filenames and returns up to `limit` unique entries.


### 2.2 Data & Collections

While the API is collection-agnostic, it is designed around two common patterns:

- **Filenames collection**
  - Embedding model: typically `granite-embedding:30m` (384 dimensions).
  - Documents represent filenames / high-level metadata.
  - Payload fields often include:
    - `pagecontent` – short text (e.g. filename or summary).
    - `metadata` – optional metadata.

- **Content collection**
  - Embedding model: typically `bge-m3` (1024 dimensions).
  - Each vector corresponds to a document page/chunk.
  - Payload fields:
    - `pagecontent` – the actual content text.
    - `metadata.filename` – source document name.
    - `metadata.page_number` – page index.


### 2.3 Configuration & Environment

Configuration is driven by environment variables (loaded via `.env` using
`python-dotenv`). The canonical template is `tamplate.env`.

**Global / app settings**

```env
ENVIRONMENT=development         # "development" or "production"
DEBUG=false                     # toggles log level
REQUEST_TIMEOUT=30              # uvicorn keep-alive timeout
CONTEXT_WINDOW_SIZE=5           # default context window for page retrieval
```

**API key authentication**

```env
API_KEY_ENABLED=false
API_KEY=your-api-key
```

- When `API_KEY_ENABLED=false`, authentication is bypassed entirely.
- When `true`, all endpoints require `Authorization: Bearer <API_KEY>`.

**Qdrant development configuration**

```env
DEV_QDRANT_URL=http://localhost:6333
DEV_QDRANT_API_KEY=
DEV_QDRANT_VERIFY_SSL=false
```

**Qdrant production configuration**

```env
PROD_QDRANT_URL=https://your-qdrant.instance:6333
PROD_QDRANT_API_KEY=your-api-key
PROD_QDRANT_VERIFY_SSL=true
```

**Fallback configuration (backward compatibility)**

```env
QDRANT_URL=
QDRANT_API_KEY=
QDRANT_VERIFY_SSL=true
QDRANT_HOST=127.0.0.1
QDRANT_FORCE_IGNORE_SSL=false
```

**Embedding providers**

```env
# Embedding provider selection
EMBEDDING_PROVIDER=ollama

# Ollama configuration (default provider)
OLLAMA_HOST=http://your-ollama-host:11434
DEFAULT_EMBEDDING_MODEL=mxbai-embed-large
DEFAULT_VECTOR_SIZE=1024

# Gemini configuration (optional)
# GEMINI_API_KEY should be provided securely via environment/secret manager
GEMINI_API_KEY=
GEMINI_EMBEDDING_MODEL=gemini-embedding-001
GEMINI_EMBEDDING_TASK_TYPE=RETRIEVAL_QUERY
GEMINI_EMBEDDING_DIM=768
```

#### 2.3.1 Qdrant Configuration Precedence

In `_create_qdrant_client`, configuration precedence is:

1. **Request parameters** – `qdrant_url`, `qdrant_api_key`, `qdrant_verify_ssl`.
2. **Environment-specific variables** – `DEV_*` or `PROD_*` based on
   `use_production` flag.
3. **Generic environment variables** – `QDRANT_URL`, `QDRANT_API_KEY`,
   `QDRANT_VERIFY_SSL`.
4. **Fallback** – `QDRANT_HOST` (HTTP) and default SSL settings.

For SSL:

- If `qdrant_verify_ssl` is explicitly set in the request, it is used.
- Else, if `QDRANT_FORCE_IGNORE_SSL=true`, SSL verification is disabled.
- Else, for HTTPS URLs, `*_VERIFY_SSL` settings are honored.

In **production** (`ENVIRONMENT=production`), startup validation ensures:

- Qdrant URL is HTTPS.
- An API key is configured.


### 2.4 Dependencies

From `app/requirements.txt`:

- `fastapi>=0.68.0` – web framework
- `uvicorn>=0.15.0` – ASGI server
- `qdrant-client>=1.1.1` – Qdrant Python client
- `ollama>=0.1.4` – Ollama Python client
- `pydantic>=1.8.2` – data validation
- `python-dotenv>=0.19.0` – `.env` loading
- `python-json-logger>=2.0.7` – structured logging
- `requests>=2.28.0` – HTTP client for Gemini API

External services:

- **Qdrant** – vector database.
- **Ollama** – embedding service (default provider).
- **Gemini API** – managed text embedding service from Google.


## 3. Implementation Specification

### 3.1 FastAPI App (`app/main.py`)

#### 3.1.1 Configuration & Logging

- At import time:
  - `.env` is loaded with `load_dotenv()`.
  - Module-level constants are derived from environment variables.
  - `validate_production_config()` is called:
    - If `ENVIRONMENT == "production"`:
      - Qdrant URL must be HTTPS.
      - An API key must be configured.
    - Otherwise logs a development-mode summary.
- Logging:
  - Uses `python-json-logger` to emit JSON logs.
  - Defines a `correlation_id` `ContextVar`.
  - `CorrelationIdFilter` injects the correlation ID into each log record.

#### 3.1.2 Middleware

```python
@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    corr_id = str(uuid.uuid4())
    correlation_id.set(corr_id)
    # log start, call downstream, log completion
```

- Adds a unique correlation ID per request.
- Logs `Request started` and `Request completed` with path/method/client IP.
- Attaches `X-Correlation-ID` header to the response.

#### 3.1.3 API Key Authentication

- Uses `HTTPBearer(auto_error=False)`.
- `verify_api_key(credentials: HTTPAuthorizationCredentials = Security(security))`:
  - If `API_KEY_ENABLED=false`: returns immediately (auth bypassed).
  - If enabled but `API_KEY` is empty: logs error and returns 500.
  - If no credentials: returns 401.
  - If wrong credentials: returns 403 and logs a warning.
  - If correct: returns `True`.
- All endpoints depend on `verify_api_key` via `Depends`.


### 3.2 SearchSystem Class

#### 3.2.1 Responsibilities

- Manage Qdrant clients (dev/prod pools and custom per-request clients).
- Manage embedding clients for query-time embeddings via a provider abstraction
  (Ollama by default, optional Gemini).
- Enforce configuration rules (e.g. no mixing `use_production` with custom
  Qdrant parameters).
- Create collections if missing, with correct vector configuration.
- Build Qdrant filter objects from the high-level `filter` dictionary.
- Execute batch semantic search and shape responses for page-based vs generic
  collections.

#### 3.2.2 Client Management

- Pooled clients:
  - `_qdrant_pool_dev` and `_qdrant_pool_prod` are class attributes.
  - `_get_qdrant_client(use_production)` lazily initializes the appropriate pool
    using `_create_qdrant_client(...)`.
- Custom clients:
  - When request-level overrides are given, `SearchSystem` creates a non-pooled
    client for that instance only.
  - `__del__` attempts to close custom clients.
- Ollama client:
  - `_ollama_pool` is a class attribute.
  - `_get_ollama_client()` lazily creates `ollama.Client(host=OLLAMA_HOST, timeout=10)`.

#### 3.2.3 `_create_qdrant_client`

Key behaviors:

- Parses the final Qdrant URL with `urllib.parse.urlparse`.
- Derives protocol (`http`/`https`), host, port.
- Builds a `client_params` dict:
  - `host`, `port?`, `timeout=10`, `prefer_grpc=True`.
  - Adds `https=True` and `verify=<bool>` when protocol is HTTPS.
  - Adds `api_key` if available.
- Logs a JSON event describing:
  - `connection_type` (pooled/custom)
  - `environment_mode` (development/production)
  - `protocol`, `host`, `port`, `https`, `verify_ssl`
  - `authenticated` flag
  - `config_sources` (which env/parameter produced URL/API key/verify_ssl)
- **Never logs actual API key values.**

#### 3.2.4 `_build_filter_conditions`

- Input: `filter_dict: Optional[Dict[str, Dict]]` from the REST API.
- For each `field_path, condition` pair:
  - If `"match_text"` in condition:
    - If value is array → builds `should` list of `FieldCondition` with
      `MatchText`, wraps them in `Filter(should=[...])` and appends to `must`.
    - If value is scalar → appends a single `FieldCondition` with `MatchText`.
  - Elif `"match_value"` in condition:
    - If array → uses `MatchAny(any=...)`.
    - If scalar → uses `MatchValue(value=...)`.
  - Elif any of `"gte"`, `"lte"` → builds `Range` and a `FieldCondition`.
  - Else logs a warning about unknown condition type.
- Returns a `models.Filter(must=must_conditions)` or `None` if empty.
- On error, logs details (including the problematic filter) and raises
  `SearchException("Invalid filter configuration")`.

#### 3.2.5 Context Windows (`_get_context_pages`)

- Given `filename` and `center_page_number`:
  - Uses `CONTEXT_WINDOW_SIZE` or a request-level override.
  - Builds a `Range(gte=center - window, lte=center + window)` with guard rails
    (page numbers clamped to `[0, 1000]`).
  - Calls `scroll` with a filter on `metadata.filename` + `metadata.page_number`
    range.
  - Filters points whose payload matches `_has_page_structure`.
  - Sorts valid pages by `metadata.page_number` and returns payloads.

#### 3.2.6 Batch Search (`batch_search`)

- Input:
  - `search_queries: List[str]`
  - `filter: Optional[Dict]`
  - `limit: int`
  - `embedding_model: str`
- Steps:
  1. Build Qdrant filter via `_build_filter_conditions`.
  2. For each query, generate an embedding via `_generate_query_embedding`.
  3. Build a `QueryRequest` per query and call `query_batch_points`.
  4. For each query response:
     - Iterate `scored_point`s.
     - Determine if payload has page structure ("content" style) based on
       presence of `metadata.filename` and `metadata.page_number`.
     - For page-based payloads:
       - Fetch context pages.
       - Deduplicate `(filename, page_number)` across results.
       - Build result objects with `filename`, `score`, `center_page`,
         `combined_page`, `page_numbers`.
     - For generic payloads:
       - Build result objects with `score`, `filename` (derived from
         `payload.source` or `payload.pagecontent`), and optional metadata.
  5. Return a list of result lists (one list per query).
- On any exception, logs and raises `SearchException("Search operation failed")`.


### 3.3 Endpoints & Error Handling

- **`/health`**
  - Lightweight, no Qdrant/Ollama calls are forced.
  - Reports whether pooled clients have been created ("ok" vs "offline").
- **`/search`**
  - Validates request via Pydantic (`SearchRequest`).
  - Logs summary of the request (collection, query_count, use_production,
    whether custom config is used).
  - Maps domain errors to HTTP status codes:
    - `ValueError` → 400 with validation message.
    - `SearchException` → 400 with generic "Search processing failed".
    - Any other `Exception` → 500 "Internal server error".
- **`/search/filenames`**
  - Similar logging for correlation IDs and summary.
  - On error, surfaces 400 with `"Filename search failed: ..."`.


### 3.4 Security Considerations

- **Transport**
  - Production mode requires HTTPS Qdrant URL and API key at startup.
  - The API itself should be placed behind HTTPS/TLS for client access.
- **Authentication**
  - Bearer token (`Authorization: Bearer <API_KEY>`) when enabled.
  - Tokens are not logged; only authentication status and configuration sources
    are.
- **Configuration safety**
  - `QDRANT_FORCE_IGNORE_SSL` is explicitly documented as dev-only.
  - Production validation guards against HTTP Qdrant endpoints.


### 3.5 Edge Cases & Constraints

- **Filter constraints**
  - Empty arrays for `match_text` or `match_value` are ignored with a warning.
  - Invalid ranges where `gte > lte` are logged with a warning.
- **Context window**
  - Large windows are bounded by page-number maximum (1000) and by
    `2 * window + 1` maximum number of pages fetched per hit.
- **Error fallbacks**
  - If context retrieval fails for a single hit, the system logs a warning and
    continues processing other hits.
  - If filter construction fails for the entire request, a `SearchException` is
    thrown and mapped to HTTP 400.


### 3.6 Testing Surface

- **Shell-based E2E test suite** (`tests/comprehensive_tests.sh`)
  - 50 tests across:
    - Basic search
    - Batch search
    - Text filters
    - Range filters
    - Combined filters
    - Context windows
    - Embedding models
    - Version-specific queries
    - Edge cases
    - Health check
- **Supplemental tests**
  - `tests/test_array_value_filter.sh` – tests `match_value` behavior with
    single values and arrays.
  - Documentation:
    - `docs/QUICK_TEST_REFERENCE.md` – high-level test overview & examples.
    - `docs/TEST_DOCUMENTATION.md` – detailed test design and coverage.
  - Legacy/archived testing and deployment docs under `docs/archive/` and
    `archive/old_tests/` provide historical context for earlier versions.

This document is intended as a **single source of truth** for future developers
and LLMs integrating with or maintaining the Qdrant Semantic Search API.
