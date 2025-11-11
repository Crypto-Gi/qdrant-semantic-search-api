#!/bin/bash

# Comprehensive API Testing Script for Task 9
# Testing all scenarios for the Qdrant Search API v2

BASE_URL="http://localhost:8000"
PASSED=0
FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Qdrant Search API v2 - Comprehensive Testing"
echo "========================================="
echo ""

# Test function
test_api() {
    local test_name="$1"
    local endpoint="$2"
    local method="$3"
    local data="$4"
    local expected_status="$5"
    
    echo -n "Testing: $test_name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (Status: $status_code)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $status_code)"
        echo "Response: $body"
        ((FAILED++))
        return 1
    fi
}

echo "========================================="
echo "Task 9.1: Environment Variable Loading Tests"
echo "========================================="
echo ""

# Test 9.1.1: Health check (verifies environment loading)
test_api "9.1.1 Health Check" "/health" "GET" "" "200"

echo ""
echo "========================================="
echo "Task 9.2: Connection Pool Management Tests"
echo "========================================="
echo ""

# Test 9.2.1: Development pool initialization (default)
test_api "9.2.1 Dev Pool - Basic Search" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test query"],
  "embedding_model": "granite-embedding:30m",
  "limit": 2
}' "200"

# Test 9.2.2: Production pool initialization
test_api "9.2.2 Prod Pool - Basic Search" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test query"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "limit": 2
}' "200"

# Test 9.2.3: Custom client creation
test_api "9.2.3 Custom Client - Override URL" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test query"],
  "embedding_model": "granite-embedding:30m",
  "qdrant_url": "http://192.168.254.22:6333",
  "limit": 2
}' "200"

echo ""
echo "========================================="
echo "Task 9.3: Configuration Priority Tests"
echo "========================================="
echo ""

# Test 9.3.1: Request parameters override environment
test_api "9.3.1 Request Params Override" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["priority test"],
  "embedding_model": "granite-embedding:30m",
  "qdrant_url": "http://192.168.254.22:6333",
  "qdrant_verify_ssl": false,
  "limit": 1
}' "200"

# Test 9.3.2: Environment-specific variables (dev)
test_api "9.3.2 Dev Environment Variables" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["dev env test"],
  "embedding_model": "granite-embedding:30m",
  "use_production": false,
  "limit": 1
}' "200"

# Test 9.3.3: Environment-specific variables (prod)
test_api "9.3.3 Prod Environment Variables" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["prod env test"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "limit": 1
}' "200"

echo ""
echo "========================================="
echo "Task 9.4: Validation Logic Tests"
echo "========================================="
echo ""

# Test 9.4.1: Conflict detection (use_production + custom params)
test_api "9.4.1 Conflict Detection" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["conflict test"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "qdrant_url": "http://custom.qdrant.com:6333",
  "limit": 1
}' "400"

# Test 9.4.2: Valid development request
test_api "9.4.2 Valid Dev Request" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["valid dev"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "200"

# Test 9.4.3: Valid production request
test_api "9.4.3 Valid Prod Request" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["valid prod"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "limit": 1
}' "200"

echo ""
echo "========================================="
echo "Task 9.5: API Functionality Preservation Tests"
echo "========================================="
echo ""

# Test 9.5.1: /search with existing parameters only
test_api "9.5.1 Search - Existing Params" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["machine learning", "artificial intelligence"],
  "embedding_model": "granite-embedding:30m",
  "limit": 3
}' "200"

# Test 9.5.2: /search with use_production flag
test_api "9.5.2 Search - With use_production" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["neural networks"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "limit": 2
}' "200"

# Test 9.5.3: /search with custom Qdrant parameters
test_api "9.5.3 Search - Custom Qdrant Params" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["deep learning"],
  "embedding_model": "granite-embedding:30m",
  "qdrant_url": "http://192.168.254.22:6333",
  "limit": 2
}' "200"

# Test 9.5.4: /search with filters
test_api "9.5.4 Search - With Filters" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["python programming"],
  "embedding_model": "granite-embedding:30m",
  "filter": {
    "metadata.category": {
      "match_text": "technology"
    }
  },
  "limit": 2
}' "200"

# Test 9.5.5: /search with multiple queries
test_api "9.5.5 Search - Multiple Queries" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["query1", "query2", "query3"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "200"

echo ""
echo "========================================="
echo "Task 9.6: Backward Compatibility Tests"
echo "========================================="
echo ""

# Test 9.6.1: Basic search without new parameters
test_api "9.6.1 Backward Compat - Basic" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["backward compat test"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "200"

# Test 9.6.2: All existing parameters work
test_api "9.6.2 Backward Compat - All Params" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test"],
  "filter": {
    "metadata.type": {
      "match_text": "document"
    }
  },
  "embedding_model": "granite-embedding:30m",
  "limit": 5
}' "200"

echo ""
echo "========================================="
echo "Task 9.7: Secure Logging Tests"
echo "========================================="
echo ""

# Test 9.7.1: Request with API key (check logs don't expose it)
test_api "9.7.1 Secure Logging - With API Key" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["secure logging test"],
  "embedding_model": "granite-embedding:30m",
  "use_production": true,
  "limit": 1
}' "200"

# Test 9.7.2: Custom API key in request (invalid key should fail with 500)
test_api "9.7.2 Secure Logging - Custom API Key" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["custom key test"],
  "embedding_model": "granite-embedding:30m",
  "qdrant_url": "https://30dab1ce-a0d4-4c4d-a5e5-ac5aa471dfd4.us-east-1-1.aws.cloud.qdrant.io:6333",
  "qdrant_api_key": "test-api-key-should-not-be-logged",
  "qdrant_verify_ssl": true,
  "limit": 1
}' "500"

echo ""
echo "========================================="
echo "Additional Tests: Different Embedding Models"
echo "========================================="
echo ""

# Test with granite-embedding model (for filenames collection)
test_api "Extra 1: Granite Embedding Model" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test with granite"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "200"

# Test with bge-m3 model (for content collection)
test_api "Extra 2: BGE-M3 Embedding Model" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test with bge"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "200"

echo ""
echo "========================================="
echo "Additional Tests: Edge Cases"
echo "========================================="
echo ""

# Test with empty query
test_api "Edge 1: Empty Query Array" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": [],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "422"

# Test with missing required field
test_api "Edge 2: Missing Collection Name" "/search" "POST" '{
  "search_queries": ["test"],
  "embedding_model": "granite-embedding:30m",
  "limit": 1
}' "422"

# Test with invalid limit
test_api "Edge 3: Invalid Limit (0)" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test"],
  "embedding_model": "granite-embedding:30m",
  "limit": 0
}' "422"

# Test with very large limit
test_api "Edge 4: Large Limit" "/search" "POST" '{
  "collection_name": "content",
  "search_queries": ["test"],
  "embedding_model": "granite-embedding:30m",
  "limit": 100
}' "200"

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
