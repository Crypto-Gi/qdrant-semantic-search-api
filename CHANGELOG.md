# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-12

### Added
- Context window retrieval for RAG queries (configurable via `CONTEXT_WINDOW_SIZE`)
- Support for `match_value` filters with KEYWORD index on `metadata.filename`
- Comprehensive test suite (`tests/comprehensive_tests.sh`) with 50 tests
- Environment variable `CONTEXT_WINDOW_SIZE` for configuring page context (default: 5)
- Production Qdrant configuration with HTTPS and API key authentication
- Dual environment support (DEV/PROD) via `use_production` flag

### Fixed
- RAG query failures on content collection with filters
- Empty `combined_page` in search results
- Context retrieval using correct filter types (MatchValue for KEYWORD index)
- Embedding model selection per collection (bge-m3 for content, granite-embedding:30m for filenames)

### Changed
- Qdrant index type for `metadata.filename` from TEXT to KEYWORD
- Filter implementation to use `match_value` for exact filename matching
- Context retrieval to use `MatchValue` with KEYWORD index
- Updated `.env` configuration with clearer documentation

### Removed
- Archived old test scripts to `archive/old_tests/`
- Removed redundant test files and debugging scripts

### Technical Details
- **Collections**: 
  - `filenames`: 384 dimensions (granite-embedding:30m)
  - `content`: 1024 dimensions (bge-m3)
- **Index Type**: KEYWORD on `metadata.filename` for exact matching
- **Context Window**: Retrieves N pages before/after matched page (default: 11 total pages)
- **Filter Support**: `match_value` for exact matching (requires KEYWORD index)

## [0.1.0] - Initial Release

### Added
- Basic semantic search API with FastAPI
- Qdrant vector database integration
- Ollama embedding model support
- Docker containerization
- Basic filter support
