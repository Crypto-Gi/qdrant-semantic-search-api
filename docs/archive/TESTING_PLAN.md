# Qdrant Search API v2 - Comprehensive Testing Plan
## Based on Vector Store Analysis and n8n Confluence Node Filtering

**Date:** November 9, 2025  
**Purpose:** Test all API endpoints with real-world filtering scenarios based on actual Qdrant collections

---

## 1. Vector Store Analysis

### Available Collections

| Collection Name | Vector Dimensions | Embedding Model | Purpose |
|----------------|-------------------|-----------------|---------|
| `content` | 384 | granite-embedding:30m | Filename-only content |
| `filenames` | 384 | granite-embedding:30m | Full document content with metadata |
| `filename-granite-embedding30m` | 384 | granite-embedding:30m | Alternative filename collection |
| `releasenotes-bge-m3` | 1024 | bge-m3 | Release notes with BGE-M3 embeddings |

### Metadata Structure

#### Content Collection
```json
{
  "pagecontent": "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
  "source": "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
  "metadata": {
    "hash": "268264f9a2c6e8b5"
  }
}
```

#### Filenames Collection
```json
{
  "pagecontent": "[Full page text content]",
  "metadata": {
    "filename": "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
    "page_number": 22,
    "element_type": "Table",
    "md5_hash": "dda0bb74a297edee2af60e78d75d6f17"
  }
}
```

### Available Filter Fields

**Content Collection:**
- `metadata.hash` (string)
- `source` (string)

**Filenames Collection:**
- `metadata.filename` (string)
- `metadata.page_number` (integer)
- `metadata.element_type` (string)
- `metadata.md5_hash` (string)

---

## 2. Test Scenarios Based on n8n Confluence Node

### Scenario Categories

1. **Basic Search** (like Get Pages in Space)
2. **Filtered Search** (like filtering by space keys)
3. **Hierarchical Search** (like Get Page Hierarchy)
4. **Pagination** (like limit parameter)
5. **Multi-Query Search** (batch processing)
6. **Environment Switching** (dev/prod)
7. **Custom Connection Parameters**

---

## 3. Detailed Test Cases

### Test Suite 1: Basic Search Operations

#### Test 1.1: Search by Filename (Single Match)
**Scenario:** Find all content from a specific release notes file  
**Collection:** `filenames`  
**Embedding Model:** `granite-embedding:30m`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["ECOS 9.2.4.0 release notes"],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns pages from ECOS_9.2.4.0_Release_Notes_RevB.pdf only

---

#### Test 1.2: Search by Multiple Filenames (OR Logic)
**Scenario:** Find content from multiple release notes files  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["BGP configuration"],
    "filter": {
      "metadata.filename": {
        "match_text": [
          "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
          "ECOS_9.1.4.2_Release_Notes_RevC.pdf",
          "ECOS_9.1.0.0_Release_Notes_RevA.pdf"
        ]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 20
  }'
```

**Expected:** Returns results from any of the three specified files

---

#### Test 1.3: Search by Element Type (Table Content Only)
**Scenario:** Find only table content (like filtering by content type)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["issue resolution"],
    "filter": {
      "metadata.element_type": {
        "match_text": "Table"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 15
  }'
```

**Expected:** Returns only table elements

---

### Test Suite 2: Page Number Filtering (Hierarchical-like)

#### Test 2.1: Search Specific Page Range
**Scenario:** Find content from pages 1-10 (like depth control)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["introduction overview"],
    "filter": {
      "metadata.page_number": {
        "match_value": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns results only from pages 1-10

---

#### Test 2.2: Search Late Pages (Deep Content)
**Scenario:** Find content from pages 20+ (like deep hierarchy)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["resolved issues"],
    "filter": {
      "metadata.page_number": {
        "match_value": [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 20
  }'
```

**Expected:** Returns results only from pages 20-31

---

### Test Suite 3: Complex Multi-Filter Scenarios

#### Test 3.1: Filename + Element Type (AND Logic)
**Scenario:** Find tables in a specific document  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["feature description"],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      },
      "metadata.element_type": {
        "match_text": "Table"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns only tables from the specified file

---

#### Test 3.2: Multiple Files + Specific Pages (Complex OR + AND)
**Scenario:** Find content from specific pages across multiple files  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["security features"],
    "filter": {
      "metadata.filename": {
        "match_text": [
          "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
          "ECOS_9.1.4.2_Release_Notes_RevC.pdf"
        ]
      },
      "metadata.page_number": {
        "match_value": [1, 2, 3, 4, 5]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 15
  }'
```

**Expected:** Returns results from pages 1-5 of either specified file

---

### Test Suite 4: Pagination and Limit Control

#### Test 4.1: Small Limit (Quick Results)
**Scenario:** Get top 3 results (like n8n limit parameter)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["IPSec configuration"],
    "embedding_model": "granite-embedding:30m",
    "limit": 3
  }'
```

**Expected:** Returns exactly 3 results

---

#### Test 4.2: Large Limit (Comprehensive Results)
**Scenario:** Get many results (like fetching all pages)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["OSPF routing"],
    "embedding_model": "granite-embedding:30m",
    "limit": 50
  }'
```

**Expected:** Returns up to 50 results

---

### Test Suite 5: Multi-Query Batch Processing

#### Test 5.1: Multiple Related Queries
**Scenario:** Search for multiple related topics (like searching multiple spaces)  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "BGP configuration",
      "OSPF routing",
      "IPSec tunnels"
    ],
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Returns 3 separate result arrays, one for each query

---

#### Test 5.2: Multiple Queries with Filters
**Scenario:** Search multiple topics in specific files  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "new features",
      "resolved issues",
      "upgrade considerations"
    ],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Returns 3 result arrays, all filtered to the specified file

---

### Test Suite 6: Environment Switching (Dev/Prod)

#### Test 6.1: Development Environment Search
**Scenario:** Search using local Qdrant instance  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["VPN configuration"],
    "use_production": false,
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Uses DEV_QDRANT_URL (http://192.168.254.22:6333)

---

#### Test 6.2: Production Environment Search
**Scenario:** Search using cloud Qdrant instance  
**Collection:** `content`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "content",
    "search_queries": ["ECOS release"],
    "use_production": true,
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Uses PROD_QDRANT_URL (cloud instance with HTTPS and API key)

---

### Test Suite 7: Content Collection Tests

#### Test 7.1: Simple Filename Search
**Scenario:** Search in content collection (filename-only)  
**Collection:** `content`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "content",
    "search_queries": ["ECOS 9.2.4.0"],
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns filename matches

---

#### Test 7.2: Filter by Source
**Scenario:** Filter by source field  
**Collection:** `content`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "content",
    "search_queries": ["release notes"],
    "filter": {
      "source": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Returns results from specified source

---

### Test Suite 8: Real-World Use Cases

#### Test 8.1: Find All Issues in Release Notes
**Scenario:** Search for issue resolutions across all release notes  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["ID: 66614", "ID: 65648", "ID: 57761"],
    "filter": {
      "metadata.element_type": {
        "match_text": "Table"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns issue details from tables

---

#### Test 8.2: Find Feature Descriptions
**Scenario:** Search for feature descriptions across versions  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "Branch NAT",
      "Multi-Region Subnet Sharing",
      "IPSec Service Chaining"
    ],
    "filter": {
      "metadata.filename": {
        "match_text": [
          "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
          "ECOS_9.1.4.2_Release_Notes_RevC.pdf"
        ]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 5
  }'
```

**Expected:** Returns feature descriptions from specified files

---

#### Test 8.3: Find Security-Related Content
**Scenario:** Search for security features and CVEs  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "CVE security vulnerability",
      "certificate authentication",
      "CSRF protection"
    ],
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns security-related content

---

#### Test 8.4: Find Configuration Examples
**Scenario:** Search for configuration instructions  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "configuration steps",
      "setup instructions",
      "how to configure"
    ],
    "filter": {
      "metadata.page_number": {
        "match_value": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 15
  }'
```

**Expected:** Returns configuration content from early pages

---

### Test Suite 9: Edge Cases and Error Handling

#### Test 9.1: Non-Existent Filename Filter
**Scenario:** Filter by filename that doesn't exist  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["test query"],
    "filter": {
      "metadata.filename": {
        "match_text": "NonExistentFile.pdf"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns empty results array

---

#### Test 9.2: Invalid Page Number Range
**Scenario:** Filter by page numbers that don't exist  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["test query"],
    "filter": {
      "metadata.page_number": {
        "match_value": [999, 1000, 1001]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns empty results array

---

#### Test 9.3: Empty Filter Results
**Scenario:** Combination of filters that yields no results  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["BGP configuration"],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      },
      "metadata.page_number": {
        "match_value": [999]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Returns empty results array

---

### Test Suite 10: Performance and Optimization

#### Test 10.1: Large Multi-Query Batch
**Scenario:** Process many queries at once  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": [
      "BGP",
      "OSPF",
      "IPSec",
      "VPN",
      "routing",
      "firewall",
      "security",
      "configuration",
      "troubleshooting",
      "performance"
    ],
    "embedding_model": "granite-embedding:30m",
    "limit": 3
  }'
```

**Expected:** Returns 10 result arrays efficiently

---

#### Test 10.2: Filter Optimization
**Scenario:** Use filters to reduce search space  
**Collection:** `filenames`

```bash
curl -X POST http://localhost:8000/search \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["configuration"],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      },
      "metadata.element_type": {
        "match_text": "Table"
      },
      "metadata.page_number": {
        "match_value": [1, 2, 3, 4, 5]
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }'
```

**Expected:** Fast response due to narrow filter scope

---

## 4. Test Execution Script

```bash
#!/bin/bash

# Comprehensive Testing Script
# Based on n8n Confluence Node Filtering Patterns

BASE_URL="http://localhost:8000"
PASSED=0
FAILED=0

echo "========================================="
echo "Qdrant Search API - Confluence-Style Testing"
echo "========================================="

# Test Suite 1: Basic Search
echo ""
echo "Test Suite 1: Basic Search Operations"
echo "-------------------------------------"

# Test 1.1
echo -n "Test 1.1: Search by Filename (Single Match)... "
response=$(curl -s -X POST "$BASE_URL/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "filenames",
    "search_queries": ["ECOS 9.2.4.0 release notes"],
    "filter": {
      "metadata.filename": {
        "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
      }
    },
    "embedding_model": "granite-embedding:30m",
    "limit": 10
  }')

if echo "$response" | grep -q '"results"'; then
  echo "✓ PASSED"
  ((PASSED++))
else
  echo "✗ FAILED"
  ((FAILED++))
fi

# Add more tests here...

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"
```

---

## 5. Expected Outcomes

### Success Criteria

1. ✅ All basic searches return relevant results
2. ✅ Filters correctly narrow down results
3. ✅ Multi-query batches process efficiently
4. ✅ Environment switching works correctly
5. ✅ Edge cases handled gracefully
6. ✅ Performance meets expectations

### Performance Benchmarks

- Single query: < 500ms
- Multi-query (3 queries): < 1000ms
- Filtered query: < 400ms
- Large limit (50): < 800ms

---

## 6. Integration with n8n Workflow

### Example n8n Workflow

```json
{
  "nodes": [
    {
      "name": "Search Release Notes",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://localhost:8000/search",
        "method": "POST",
        "bodyParameters": {
          "collection_name": "filenames",
          "search_queries": ["{{ $json.searchTerm }}"],
          "filter": {
            "metadata.filename": {
              "match_text": "{{ $json.filename }}"
            }
          },
          "embedding_model": "granite-embedding:30m",
          "limit": 10
        }
      }
    }
  ]
}
```

---

## 7. Conclusion

This testing plan provides comprehensive coverage of the Qdrant Search API with real-world scenarios based on:

1. **Actual vector store structure** - Tests use real collections and metadata fields
2. **n8n Confluence node patterns** - Filtering mimics space/page filtering
3. **Practical use cases** - Tests reflect real document search scenarios
4. **Edge cases** - Handles errors and empty results gracefully

**Next Steps:**
1. Execute automated test script
2. Validate all test cases
3. Document any issues found
4. Optimize based on performance results

---

**Testing Plan Created:** November 9, 2025  
**Status:** Ready for Execution  
**Collections Tested:** content, filenames  
**Total Test Cases:** 30+
