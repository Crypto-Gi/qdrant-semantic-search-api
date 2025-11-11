# Quick Test Reference Guide

## 🚀 Run All Tests
```bash
./comprehensive_tests.sh
```

## 📊 Test Summary

| Section | Tests | Focus Area |
|---------|-------|------------|
| 1. Basic Search | 5 | Single queries, limits |
| 2. Batch Search | 5 | Multiple queries |
| 3. Text Filters | 10 | Metadata text matching |
| 4. Range Filters | 5 | Page number ranges |
| 5. Combined Filters | 5 | Multiple filter types |
| 6. Context Windows | 5 | Page context retrieval |
| 7. Embedding Models | 3 | Model selection |
| 8. Version Searches | 7 | Specific versions |
| 9. Edge Cases | 5 | Boundary conditions |
| 10. Health Check | 1 | API health |
| **TOTAL** | **50** | **Complete coverage** |

## 🎯 Key Test Examples

### Basic Search
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["ECOS 9.3.2.1"],
    "use_production": true,
    "limit": 3
  }'
```

### Filtered Search
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "content",
    "search_queries": ["installation"],
    "filter": {
      "metadata.filename": {"match_text": "ECOS"},
      "metadata.page_number": {"gte": 1, "lte": 10}
    },
    "use_production": true,
    "limit": 3
  }'
```

### Batch Search
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "ECOS 9.3",
      "Orchestrator 9.2",
      "release notes"
    ],
    "use_production": true,
    "limit": 3
  }'
```

### Context Window
```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "content",
    "search_queries": ["configuration"],
    "use_production": true,
    "limit": 2,
    "context_window_size": 10
  }'
```

## 📈 Production Data Stats

### Filenames Collection
- **Points**: 149
- **Dimensions**: 384
- **Products**: ECOS, Orchestrator
- **Versions**: 9.1.x - 9.6.x

### Content Collection
- **Points**: 14,857
- **Dimensions**: 1024
- **Products**: ECOS, Orchestrator
- **Versions**: 9.1.x - 9.6.x
- **Pages**: 1-100+ per document

## ✅ Success Indicators

All tests passing means:
- ✅ Search functionality working
- ✅ Filters applied correctly
- ✅ Context windows retrieving properly
- ✅ Batch queries processing
- ✅ Embedding models functional
- ✅ Edge cases handled
- ✅ Production data accessible
- ✅ No crashes or errors

## 🔍 Individual Test Execution

Run specific test by copying command from test output:
```bash
# Example from test output
curl -s -X POST http://localhost:8001/search \
  -H 'Content-Type: application/json' \
  -d '{"collection_name": "filenames", "search_queries": ["ECOS 9.3.2.1"], "use_production": true, "limit": 3}'
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Start API: `docker compose up -d` |
| Qdrant offline | Check production Qdrant access |
| Ollama offline | Verify Ollama at 192.168.254.22:11434 |
| Empty results | Check collection has data |
| Wrong model | Ensure granite-embedding:30m available |

## 📝 Test Coverage

### API Features Tested
- [x] Basic semantic search
- [x] Batch query processing
- [x] Text filtering (single & array)
- [x] Range filtering (gte, lte)
- [x] Combined filters (AND logic)
- [x] Context window retrieval
- [x] Embedding model selection
- [x] Production/development modes
- [x] Result limiting
- [x] Health check endpoint
- [x] Edge case handling
- [x] Error resilience

### Collections Tested
- [x] filenames (simple structure)
- [x] content (page-based structure)

### Data Tested
- [x] ECOS versions (9.1 - 9.6)
- [x] Orchestrator versions (9.1 - 9.5)
- [x] Multiple revisions (RevA, RevB, RevC, etc.)
- [x] Page ranges (1-100+)
- [x] 200+ unique filenames
- [x] 14,857+ content pages

## 🎓 Learning from Tests

### Filter Syntax
```json
{
  "metadata.filename": {
    "match_text": "ECOS"              // Single value
  }
}

{
  "metadata.filename": {
    "match_text": ["ECOS", "Orch"]    // Array (OR logic)
  }
}

{
  "metadata.page_number": {
    "gte": 1,                          // Greater than or equal
    "lte": 10                          // Less than or equal
  }
}
```

### Response Structure
```json
{
  "results": [
    [
      {
        "filename": "ECOS_9.3.2.1_Release_Notes_RevA.pdf",
        "score": 0.9078,
        "content": "...",
        "metadata": {...}
      }
    ]
  ]
}
```

## 📞 Support

For issues or questions:
1. Check TEST_DOCUMENTATION.md for details
2. Review test output for specific failures
3. Verify prerequisites (API, Qdrant, Ollama)
4. Check logs: `docker compose logs search_api`
