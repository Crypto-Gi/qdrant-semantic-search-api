#!/bin/bash

# Test script for array value filter functionality
# Tests match_value with single values and arrays

echo "=========================================="
echo "Testing Array Value Filter Functionality"
echo "=========================================="
echo ""

# Test 1: Single integer value (backward compatibility)
echo "Test 1: Single integer value (backward compatibility)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "match_value": 2023
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 2: Single string value (backward compatibility)
echo "Test 2: Single string value (backward compatibility)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.status": {
        "match_value": "published"
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 3: Single boolean value (backward compatibility)
echo "Test 3: Single boolean value (backward compatibility)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.published": {
        "match_value": true
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 4: Array of integers
echo "Test 4: Array of integers"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "match_value": [2022, 2023, 2024]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 5: Array of strings
echo "Test 5: Array of strings"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.status": {
        "match_value": ["published", "draft", "archived"]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 6: Array of mixed types
echo "Test 6: Array of mixed types"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.priority": {
        "match_value": [1, "high", true]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

echo "=========================================="
echo "Array Value Filter Tests Complete"
echo "=========================================="
