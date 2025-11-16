# Phase 3 – Embedding Provider Abstraction & Gemini Integration (BMAD Spec)

## 1. Background

### 1.1 Current Project Summary

The project is a **FastAPI-based semantic search microservice** backed by **Qdrant** as the vector database and **Ollama** as the current embedding provider. It exposes HTTP endpoints (e.g. `/health`, `/search`, `/search/filenames`) and is designed to be deployed via Docker.

Key characteristics:

- **API**: FastAPI app (`app/main.py`) exposing search endpoints.
- **Vector DB**: Qdrant, configured via environment variables, with collections for filenames and page-level content.
- **Embeddings**: Currently generated exclusively via **Ollama** (e.g., bge-m3, granite), tightly coupled into the `SearchSystem` implementation.
- **Configuration**: `.env`/`tamplate.env` controls Qdrant host/ports, collection names, SSL, embedding model name, API key auth, etc.
- **Testing**: A comprehensive shell test suite (`tests/comprehensive_tests.sh`) covers health, search, filters, batch queries, and edge cases.
- **Deployment**: `docker-compose.yml` + `app/Dockerfile` support containerized deployment.

### 1.2 Current Architecture (High-Level)

```text
[Client]  -->  [FastAPI /search, /search/filenames]
                |
                v
           [SearchSystem]
                |
        (direct call to Ollama embeddings)
                v
           [Ollama Server]
                |
                v
             [Qdrant]
```

- `SearchSystem` is responsible for:
  - Generating query embeddings via Ollama.
  - Building Qdrant filter conditions.
  - Calling Qdrant for vector search (including batch query support).
  - Post-processing results into API responses (context windows, filenames, etc.).

### 1.3 Constraints & Assumptions

- **No breaking changes**: Existing behavior must remain the default; current users should not need to change client code.
- **Single source of collection truth**: This service reads collection names and vector sizes from `.env`; it **does not perform indexing** nor control how vectors are written into Qdrant.
- **Indexing pipeline is external**: The ingestion/indexing process that computes document embeddings and writes them into Qdrant is **out of scope** for this service.
- **Per-environment collections**: Each environment (DEV/PROD) may point to different Qdrant collections, but the service treats them simply as configured names.
- **API stability**: No new mandatory request fields or breaking changes to existing endpoints for this phase.
- **Security**:
  - API key auth for this service is already implemented and must remain intact.
  - New provider credentials (Gemini API key) must be handled securely via environment variables.

### 1.4 Known Challenges with the Current Design

- **Tight coupling to Ollama**:
  - Embedding generation is hard-wired inside `SearchSystem`.
  - Adding a new provider requires editing core logic rather than swapping implementations.

- **Limited provider flexibility**:
  - No clean way to switch providers per environment (e.g., Ollama in DEV, Gemini in PROD) or per deployment without code changes.

- **Embedding dimensionality assumptions**:
  - Vector sizes are effectively tied to current models (e.g., 384, 1024) with no explicit abstraction.
  - Switching to a provider like Gemini, which supports multiple output dimensions, requires clear, explicit configuration.

- **Testing complexity**:
  - Tests implicitly assume Ollama is available and functioning.
  - No isolated tests for embedding logic vs search logic.

---

## 2. Motivation

### 2.1 Purpose of the Next Phase

This phase introduces a **modular embedding provider abstraction** and an implementation for **Google Gemini embeddings** while preserving current behavior by default.

Goals:

- Allow the service to use **Gemini embeddings** (via the Gemini API) for query-time embedding generation.
- Keep **Ollama as the default provider**, ensuring zero breaking changes for existing users.
- Make it easy to add more embedding providers in the future.

### 2.2 Why This Phase is Necessary

- **Business value**:
  - Access to **managed, production-grade embeddings** from Google Gemini with strong benchmarks and multilingual support.
  - **Vendor flexibility** and risk mitigation: ability to switch providers without rewriting the service.
  - Better alignment with **enterprise requirements** (SLA, compliance) by being able to use cloud-hosted embeddings.

- **Technical value**:
  - Decouples the FastAPI service from any single embedding provider.
  - Clarifies embedding configuration (provider, model, output dimensionality) via environment variables.
  - Enables a clean separation of concerns: `SearchSystem` focuses on search logic, while provider implementations focus on calling external services.

- **Scalability and performance**:
  - Gemini supports **higher throughput** scenarios and optimized embedding variants.
  - Configurable **output dimensionality** (e.g., 768) allows tuning storage cost and search performance.

- **Long-term impact**:
  - Establishes a pattern for **plugin-like providers** (e.g., OpenAI, Vertex, custom models) without touching core code each time.
  - Eases future experimentation with different models and providers per environment.

### 2.3 Risks & Considerations

- **Vector dimensionality mismatch**:
  - Qdrant collections must be created with the same vector size as the embeddings produced by the provider.
  - This service assumes the external indexing pipeline and Qdrant schema are already aligned; misalignment will cause runtime errors.

- **Operational risk**:
  - Gemini introduces dependency on Googles API and its availability/quotas.
  - Need to handle timeouts, retries, and error codes without impacting API SLAs.

- **Cost & rate limiting**:
  - Gemini is a paid API; query volume will map directly to cost.
  - Need observability (logging/metrics) for embedding call volume.

- **Security**:
  - Gemini API key must be stored securely (.env, secrets management).
  - API keys must never be logged or exposed in error messages.

---

## 3. Actions (Workstreams & Tasks)

### 3.1 Workstream A – Embedding Provider Abstraction & Configuration

**Objective**: Introduce a clear `EmbeddingClient` abstraction and configuration schema without changing runtime behavior.

**Tasks**:

1. **Define `EmbeddingClient` interface**
   - Methods (conceptual):
     - `embed(texts: List[str]) -> List[List[float]]`
     - `embed_one(text: str) -> List[float]` (convenience wrapper around `embed`).
   - Define expected behaviors:
     - Deterministic output for same input and config.
     - Raise well-defined exceptions on provider errors.

2. **Design provider factory**
   - `EmbeddingProviderFactory.from_env()` reads environment variables and returns an `EmbeddingClient` instance.
   - Supported values for `EMBEDDING_PROVIDER`:
     - `"ollama"` (default, current behavior).
     - `"gemini"` (new behavior).

3. **Configuration schema**
   - Add (to spec and env template) the following variables:

     | Variable                     | Example value              | Description                                           |
     |------------------------------|----------------------------|-------------------------------------------------------|
     | `EMBEDDING_PROVIDER`         | `ollama` (default)         | Which provider to use (`ollama`, `gemini`, etc.).     |
     | `GEMINI_API_KEY`             | `<secret>`                 | API key for Gemini embeddings.                        |
     | `GEMINI_EMBEDDING_MODEL`     | `gemini-embedding-001`     | Gemini embedding model name.                          |
     | `GEMINI_EMBEDDING_TASK_TYPE` | `RETRIEVAL_QUERY`          | Task type for query embeddings.                       |
     | `GEMINI_EMBEDDING_DIM`       | `768`                      | Output dimensionality (must match Qdrant vector size) |

   - Document assumptions regarding external indexing (use of `RETRIEVAL_DOCUMENT`).

4. **Documentation updates (design phase)**
   - Update `docs/SYSTEM_SPEC.md` and `.env` template to describe the new provider abstraction and env variables (implementation will follow later).

**Dependencies**: None (pure design work).

---

### 3.2 Workstream B1 – Refactor Existing Ollama Logic into `EmbeddingClient`

**Objective**: Introduce the abstraction in code while preserving current behavior with Ollama.

**Tasks** (to be executed later, not in this spec phase):

1. **Implement `OllamaEmbeddingClient`**
   - Wrap current Ollama embedding call logic into a class implementing `EmbeddingClient`.
   - Read existing configuration (e.g., `DEFAULT_EMBEDDING_MODEL`, `OLLAMA_HOST`).

2. **Integrate provider into `SearchSystem`**
   - In `SearchSystem.__init__`, instantiate `self.embedding_client = EmbeddingProviderFactory.from_env()`.
   - Replace direct Ollama calls (e.g., `_generate_query_embedding`) with `self.embedding_client.embed_one(query)`.

3. **Add unit tests**
   - Tests with `EMBEDDING_PROVIDER=ollama` to ensure no behavioral change.
   - Tests that factory returns `OllamaEmbeddingClient` when env is missing or explicitly `ollama`.

**Dependencies**: Workstream A design and env-variable specification.

---

### 3.3 Workstream B2 – Implement `GeminiEmbeddingClient`

**Objective**: Add a Gemini-backed implementation of `EmbeddingClient` using the Gemini Embeddings API.

**Tasks** (to be executed later):

1. **Library / transport choice**
   - Option 1: Use **REST** via `requests`.
   - Option 2: Add `google-genai` Python SDK as a dependency.
   - This spec assumes **Option 1 (REST)** for minimal dependencies; can be revisited.

2. **Implement `GeminiEmbeddingClient`**
   - Constructor parameters (from env):
     - `api_key = GEMINI_API_KEY`
     - `model = GEMINI_EMBEDDING_MODEL` (default `gemini-embedding-001`)
     - `task_type = GEMINI_EMBEDDING_TASK_TYPE` (default `RETRIEVAL_QUERY`)
     - `output_dimensionality = GEMINI_EMBEDDING_DIM` (default `768`)
   - Implement `embed(texts: List[str])`:
     - Call Gemini **batch embedding** endpoint (`:embedContent` or `:batchEmbedContents` depending on final choice).
     - Build request payload with `task_type`, `content.parts[].text`, and optional `output_dimensionality`.
     - Parse response JSON and return list of vectors (`values`).
   - Implement `embed_one(text: str)` as a simple wrapper.

3. **Error handling and timeouts**
   - Configure reasonable timeout (e.g., 3–5 seconds) per request.
   - On non-2xx responses, raise a custom provider exception with sanitized error details.
   - Handle retry logic minimally (e.g., one retry on transient network errors), or leave retries to upstream infra.

4. **Factory integration**
   - Update `EmbeddingProviderFactory.from_env()` to:
     - Return `GeminiEmbeddingClient` when `EMBEDDING_PROVIDER=gemini`.
     - Validate that `GEMINI_API_KEY` is present; otherwise fail fast at startup.

**Dependencies**: Workstream A (config) and B1 (abstraction in place).

---

### 3.4 Workstream C – Testing, Validation, and Performance

**Objective**: Ensure correctness, robustness, and acceptable performance for both providers.

**Tasks** (later):

1. **Unit tests**
   - Mock Gemini and Ollama HTTP calls, test `EmbeddingClient` behavior in isolation.
   - Verify exceptions on timeouts and non-2xx responses.

2. **Integration tests**
   - Run `tests/comprehensive_tests.sh` with:
     - `EMBEDDING_PROVIDER=ollama` (regression baseline).
     - `EMBEDDING_PROVIDER=gemini`, pointing to a Gemini-backed Qdrant collection (with matching vector dimensions).

3. **Performance validation**
   - Measure typical end-to-end latency for `/search` with Gemini.
   - Confirm P95/P99 latencies are acceptable for expected workloads.

---

### 3.5 Workstream D – Documentation & Operationalization

**Objective**: Make the new capabilities understandable and operable by other engineers and operators.

**Tasks** (later):

1. **Docs updates**
   - Update `docs/SYSTEM_SPEC.md` with:
     - Embedding provider abstraction section.
     - Example configurations for `ollama` and `gemini`.
   - Update `README.md` with:
     - Short section on selecting embedding provider.
     - Example `.env` snippet.

2. **Runbooks**
   - Add troubleshooting notes (e.g., what to check if embeddings fail, how to confirm which provider is active).

3. **Change management**
   - Document how to roll out Gemini gradually (e.g., start in DEV with small traffic, then promote).

---

## 4. Details by Workstream

### 4.1 Technical Specifications – Embedding Abstraction

#### 4.1.1 Interface Definition

Conceptual Python interface (for design only, not code yet):

```text
class EmbeddingClient:
    def embed(self, texts: List[str]) -> List[List[float]]:
        """Return one embedding vector per input text.

        - Must preserve ordering.
        - Must raise a provider-specific exception on failure.
        """

    def embed_one(self, text: str) -> List[float]:
        """Embedding for a single text. Convenience helper."""
```

#### 4.1.2 Factory Behavior

- Function: `EmbeddingProviderFactory.from_env()` (exact placement TBD, e.g., `app/embeddings.py`).
- Logic:
  1. Read `EMBEDDING_PROVIDER`.
  2. If unset or `"ollama"` → return `OllamaEmbeddingClient`.
  3. If `"gemini"` → validate `GEMINI_API_KEY` and return `GeminiEmbeddingClient`.
  4. For unknown values → fail fast with clear error message at startup.

#### 4.1.3 Architectural Diagram (New Design)

```text
[Client]  -->  [FastAPI /search, /search/filenames]
                |
                v
           [SearchSystem]
                |
         [EmbeddingClient abstraction]
           /                    \
          v                      v
[OllamaEmbeddingClient]   [GeminiEmbeddingClient]
          |                      |
        [Ollama]             [Gemini API]
                \            /
                 \          /
                  v        v
                     [Qdrant]
```

- `SearchSystem` only interacts with `EmbeddingClient`.
- Provider details (Ollama vs Gemini) are hidden behind the abstraction.

---

### 4.2 Data Flows

#### 4.2.1 Query-Time Flow with Ollama (unchanged default)

1. Client calls `/search` with query and optional filters.
2. FastAPI routes to `SearchSystem.batch_search`.
3. `SearchSystem` calls `embedding_client.embed(...)`.
4. `OllamaEmbeddingClient` sends request to Ollama and returns vectors.
5. `SearchSystem` calls Qdrant with these vectors.
6. Qdrant returns nearest neighbors.
7. `SearchSystem` post-processes results (context windows, filenames) and returns JSON.

#### 4.2.2 Query-Time Flow with Gemini

1. Client calls `/search` with query and optional filters (same contract).
2. FastAPI routes to `SearchSystem.batch_search`.
3. `SearchSystem` calls `embedding_client.embed(...)`.
4. `GeminiEmbeddingClient`:
   - Reads `GEMINI_API_KEY`, `GEMINI_EMBEDDING_MODEL`, `GEMINI_EMBEDDING_TASK_TYPE`, `GEMINI_EMBEDDING_DIM`.
   - Calls Gemini embeddings endpoint (e.g., `gemini-embedding-001:embedContent`).
   - Returns list of vectors with dimensionality `GEMINI_EMBEDDING_DIM`.
5. `SearchSystem` calls Qdrant with these vectors, assuming collection vector size matches `GEMINI_EMBEDDING_DIM`.
6. Qdrant returns nearest neighbors.
7. `SearchSystem` post-processes results and returns JSON.

---

### 4.3 API / Endpoint Details

- **No new endpoints** in this phase.
- Existing endpoints (`/health`, `/search`, `/search/filenames`) retain their request and response formats.
- Provider selection is purely via **environment configuration**.

Potential future extension (not in scope for this phase):

- Optional query parameter or header (e.g., `X-Embedding-Provider`) to override provider per request.

---

### 4.4 Security Considerations

- **Gemini API key management**:
  - Stored only in `.env` or secure secret management system.
  - Loaded into process via `GEMINI_API_KEY`.
  - Never logged, never returned in responses.

- **Error messages**:
  - Provider errors must be sanitized before surfacing to clients.
  - For Gemini, error bodies should be logged at debug level (without secrets) and summarized for client (e.g., `503 Service Unavailable` + generic message).

- **Network security**:
  - All calls to Gemini must use HTTPS.
  - For self-hosted Qdrant, follow existing SSL/TLS configuration from `.env`.

- **Rate limiting & abuse**:
  - This phase does not introduce new rate limiting, but design should anticipate that each search request may incur an external API call (Gemini); upstream rate limiting may be introduced later.

---

### 4.5 Performance Considerations

- **Embedding dimensionality**:
  - Default `GEMINI_EMBEDDING_DIM=768` as a balance between quality and performance.
  - Must ensure Qdrant collection vector size matches this dimension when using Gemini.

- **Latency**:
  - Gemini calls add external network latency; consider:
    - Reasonable timeout (3–5 seconds).
    - Potential connection pooling if using an HTTP client session.

- **Throughput**:
  - Favor **batch embedding** where possible if multiple queries are processed at once.
  - Monitor embedding call rate and adjust QPS/limits as needed.

---

### 4.6 Tooling & Stack Choices

- **Language & framework**: Python + FastAPI (unchanged).
- **Embedding providers**:
  - **Ollama** (existing).
  - **Gemini** via REST (or `google-genai` library; final decision at implementation time).
- **HTTP client**:
  - Reuse existing HTTP stack if present, or introduce a simple `requests`-based client for Gemini.
- **Config management**:
  - `.env` & `tamplate.env` remain the source of truth.

---

### 4.7 Testing Strategy

- **Unit tests**:
  - Mock Gemini and Ollama endpoints to test `EmbeddingClient` implementations.
  - Test factory behavior for different `EMBEDDING_PROVIDER` values.

- **Integration tests**:
  - Run `tests/comprehensive_tests.sh` with `EMBEDDING_PROVIDER=ollama` to verify no regression.
  - Later, run the same suite with `EMBEDDING_PROVIDER=gemini` once a Gemini-backed Qdrant collection exists.

- **Smoke tests**:
  - Simple `/health` and basic `/search` calls after deployment with both providers.

---

### 4.8 Deployment Workflow

1. **Pre-production**:
   - Add new env variables to `.env`/secrets (including `EMBEDDING_PROVIDER` and Gemini settings).
   - Deploy with `EMBEDDING_PROVIDER=ollama` to ensure no regression.

2. **Introduce Gemini in DEV**:
   - Ensure a Qdrant collection exists with vector size matching `GEMINI_EMBEDDING_DIM`.
   - Set `EMBEDDING_PROVIDER=gemini` in DEV.
   - Run test suite and smoke tests.

3. **Promote to higher environments**:
   - Gradually roll out `EMBEDDING_PROVIDER=gemini` to staging, then production, validating metrics and error rates.

4. **Rollback plan**:
   - To revert to Ollama, change `EMBEDDING_PROVIDER=ollama` and restart the service; no code changes required.

---

### 4.9 Milestones & Timelines (Rough)

| Milestone ID | Description                                                | Owner     | Est. Effort |
|--------------|------------------------------------------------------------|-----------|-------------|
| M1           | Finalize BMAD spec & env configuration (this document)     | Architect | 0.5–1 day   |
| M2           | Implement `EmbeddingClient` + `OllamaEmbeddingClient`      | Backend   | 1–2 days    |
| M3           | Implement `GeminiEmbeddingClient` + factory integration    | Backend   | 2–3 days    |
| M4           | Testing (unit, integration, performance smoke)             | Backend   | 1–2 days    |
| M5           | Docs updates, runbooks, deployment & rollout               | Backend   | 1 day       |

This BMAD spec defines the scope, design, and concrete tasks for Phase 3: embedding provider abstraction and Google Gemini integration, while preserving the current Ollama-based behavior as the default.
