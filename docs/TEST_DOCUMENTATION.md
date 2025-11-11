# Comprehensive API Test Suite Documentation

## Overview
This test suite contains **50 comprehensive tests** designed to validate all functionalities of the Qdrant Semantic Search API against production data.

## Test Coverage

### Collections Tested
- **filenames**: 149 documents (ECOS and Orchestrator release note filenames)
- **content**: 14,857 documents (Page-based release note content with metadata)

### Data Analysis
Based on production Qdrant analysis:

#### Filenames Collection Sample (50 files):
```
ECOS_9.4.2.1_Release_Notes_RevA
ECOS_9.3.2.0_Release_Notes_RevC
Orchestrator_Release_Notes_Version_9.4.3_RevF
ECOS_9.5.3.3_Release_Notes_RevC
Orchestrator_Release_Notes_Version_9.2.1_RevC
Orchestrator_Release_Notes_Version_9.1.2_RevC
ECOS_9.3.2.1_Release_Notes_RevB
ECOS_9.4.2.2_Release_Notes_RevA
Orchestrator_Release_Notes_Version_9.1.4_RevD
ECOS_9.3.3.0_Release_Notes_RevA
... (139 more files)
```

#### Content Collection Sample (50 unique filenames):
```
ECOS_9.1.4.2_Release_Notes_RevC
ECOS_9.1.5.0_Release_Notes_RevC
ECOS_9.1.6.0_Release_Notes_RevC
ECOS_9.2.10.0_Release_Notes_RevB
ECOS_9.2.10.2_Release_Notes_RevA
ECOS_9.3.2.0_Release_Notes_RevB
... (200+ more files)
```

## Test Sections

### Section 1: Basic Search Tests (5 tests)
Tests fundamental search functionality with single queries.

**Test Cases:**
1. Search for specific ECOS version (9.3.2.1)
2. Search for specific Orchestrator version (9.1.2)
3. Search content collection with semantic query
4. Test result limiting (limit=1)
5. Test larger result sets (limit=10)

**Expected Behavior:**
- Returns relevant results with similarity scores
- Respects limit parameter
- Works across both collection types

### Section 2: Batch Search Tests (5 tests)
Tests multiple query processing in a single request.

**Test Cases:**
1. 2 queries in one request
2. 3 queries in one request
3. 5 queries in one request
4. Mixed product queries (ECOS + Orchestrator)
5. Batch search on content collection

**Expected Behavior:**
- Returns array of result arrays (one per query)
- Processes all queries efficiently
- Maintains query order in results

### Section 3: Text Matching Filters (10 tests)
Tests metadata filtering with text matching.

**Test Cases:**
1-2. Single text match (ECOS, Orchestrator)
3-4. Version-specific text matching (9.2, 9.3)
5-6. Array text matching (multiple versions, multiple products)
7-8. Specific filename patterns
9-10. Revision filtering (RevA, RevB, RevC)

**Expected Behavior:**
- Filters results to match text patterns
- Supports single and array values
- Uses OR logic for array values

### Section 4: Range Filters (5 tests)
Tests numeric range filtering on page numbers.

**Test Cases:**
1. Pages 1-10 (early content)
2. Pages 10-20 (middle content)
3. Pages >= 50 (late content)
4. Pages <= 5 (introduction)
5. Pages 20-30 (specific range)

**Expected Behavior:**
- Filters by page number ranges
- Supports gte, lte, or both
- Works with content collection only

### Section 5: Combined Filters (5 tests)
Tests multiple filters applied simultaneously.

**Test Cases:**
1. Product + Page range (ECOS + Pages 1-10)
2. Product + Page range (Orchestrator + Pages 1-20)
3. Version + Early pages (9.2 + Pages <= 15)
4. Multiple versions + Page range
5. Revision + Page range (RevA + Pages 1-30)

**Expected Behavior:**
- All filters applied with AND logic
- Results match all filter conditions
- Maintains search relevance

### Section 6: Context Window Tests (5 tests)
Tests page context retrieval for content collection.

**Test Cases:**
1. Context window size 0 (no context)
2. Context window size 2 (small)
3. Context window size 5 (default)
4. Context window size 10 (large)
5. Context window size 1 (minimal)

**Expected Behavior:**
- Returns surrounding pages based on window size
- Window size 0 returns only matched page
- Window size N returns N pages before and after match
- Returns combined page content

### Section 7: Embedding Model Tests (3 tests)
Tests different embedding model configurations.

**Test Cases:**
1. Default model (granite-embedding:30m from .env)
2. Explicit model specification
3. Alternative model (bge-m3)

**Expected Behavior:**
- Uses default from .env when not specified
- Accepts model override in request
- Generates embeddings with specified model

### Section 8: Specific Version Searches (7 tests)
Tests searches for specific product versions.

**Test Cases:**
1. ECOS 9.1.4.2
2. ECOS 9.2.10
3. ECOS 9.3.2
4. Orchestrator 9.1.2
5. Orchestrator 9.2.2
6. Orchestrator 9.3.1
7. Orchestrator 9.4.2

**Expected Behavior:**
- Returns version-specific results
- Filters correctly by version number
- Maintains semantic relevance

### Section 9: Edge Cases (5 tests)
Tests boundary conditions and error handling.

**Test Cases:**
1. Empty query string
2. Very long query (50+ words)
3. Special characters in query
4. Large result set (limit=50)
5. No results expected (gibberish query)

**Expected Behavior:**
- Handles edge cases gracefully
- No crashes or errors
- Returns appropriate responses

### Section 10: Health Check (1 test)
Tests API health endpoint.

**Test Cases:**
1. Health check endpoint

**Expected Behavior:**
- Returns status: "ok" or "degraded"
- Shows service status (qdrant, ollama)

## Running the Tests

### Prerequisites
1. API server running on `http://localhost:8001`
2. Production Qdrant accessible
3. Ollama service running with granite-embedding:30m model

### Execute Test Suite
```bash
cd /home/mir/projects/qdrant-semantic-search-api
chmod +x comprehensive_tests.sh
./comprehensive_tests.sh
```

### Expected Output
```
============================================================================
STARTING COMPREHENSIVE API TEST SUITE
============================================================================

=== SECTION 1: BASIC SEARCH TESTS ===

Test #1: Basic search - ECOS 9.3.2.1
Command: curl -s -X POST ...
✓ PASS

Test #2: Basic search - Orchestrator 9.1.2
Command: curl -s -X POST ...
✓ PASS

...

============================================================================
TEST SUITE COMPLETED
============================================================================
Total Tests: 50
Passed: 50
Failed: 0
============================================================================
🎉 ALL TESTS PASSED! 🎉
```

## Test Data Summary

### Production Collections Analysis

#### Filenames Collection
- **Total Points**: 149
- **Vector Size**: 384 dimensions
- **Distance Metric**: Cosine
- **Structure**: Simple (source, pagecontent, metadata.hash)
- **Products**: ECOS and Orchestrator
- **Version Range**: 9.1.x to 9.6.x

#### Content Collection
- **Total Points**: 14,857
- **Vector Size**: 1024 dimensions
- **Distance Metric**: Cosine
- **Structure**: Page-based (metadata.filename, metadata.page_number, pagecontent)
- **Products**: ECOS and Orchestrator
- **Version Range**: 9.1.x to 9.6.x
- **Page Range**: 1 to 100+ pages per document

### Sample Queries Used
1. Version-specific: "ECOS 9.3.2.1", "Orchestrator 9.1.2"
2. Semantic: "installation requirements", "configuration", "troubleshooting"
3. Generic: "release notes", "features", "updates", "changes"
4. Technical: "installation", "setup", "overview", "appendix"

## Success Criteria

### All Tests Must:
1. Return valid JSON responses
2. Include expected fields (results, score, filename, etc.)
3. Respect filter conditions
4. Handle edge cases without errors
5. Complete within reasonable time (<5 seconds per test)

### Performance Benchmarks
- Single query: < 2 seconds
- Batch query (5 queries): < 5 seconds
- Filtered query: < 3 seconds
- Context window query: < 4 seconds

## Troubleshooting

### Common Issues

#### Test Failures
1. **API not running**: Ensure `docker compose up -d` is running
2. **Qdrant offline**: Check production Qdrant connectivity
3. **Ollama offline**: Verify Ollama service at http://192.168.254.22:11434
4. **Wrong embedding model**: Ensure granite-embedding:30m is available

#### Expected Failures
- Alternative embedding model test may fail if bge-m3 not installed
- Empty query test may return empty results (expected behavior)
- Gibberish query test should return empty or low-score results

## Maintenance

### Updating Tests
1. Add new test cases to appropriate section
2. Update TEST_NUM counter
3. Follow naming convention: "Section - Description"
4. Include expected pattern for validation

### Adding New Sections
1. Create new section header
2. Group related tests (5-10 tests per section)
3. Document in this file
4. Update total count in summary

## API Endpoints Tested

### POST /search
- **Purpose**: Semantic search with optional filtering
- **Parameters**: 
  - collection_name (required)
  - search_queries (required, array)
  - filter (optional, dict)
  - embedding_model (optional, string)
  - limit (optional, int, default=5)
  - context_window_size (optional, int, default=5)
  - use_production (optional, bool, default=false)
- **Response**: JSON with results array

### GET /health
- **Purpose**: Check API and service health
- **Parameters**: None
- **Response**: JSON with status and services

## Conclusion

This comprehensive test suite validates:
✅ All core search functionality
✅ Filtering capabilities (text, range, combined)
✅ Context window retrieval
✅ Batch query processing
✅ Embedding model flexibility
✅ Edge case handling
✅ Production data compatibility

**Total Coverage**: 50 tests across 10 functional areas with real production data.
