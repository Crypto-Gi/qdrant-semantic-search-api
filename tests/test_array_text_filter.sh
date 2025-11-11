#!/bin/bash

# Test script for array text filter functionality
# Tests match_text with single values and arrays

echo "========================================="
echo "Testing Array Text Filter Functionality"
echo "========================================="
echo ""

# Test 1: Single text value (backward compatibility)
echo "Test 1: Single text value (backward compatibility)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": "technology"
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 2: Array with 1 value
echo "Test 2: Array with 1 value"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["technology"]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 3: Array with 3 values
echo "Test 3: Array with 3 values"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["devops", "infrastructure", "cloud"]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 4: Array with 5 values
echo "Test 4: Array with 5 values"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["devops", "infrastructure", "cloud", "security", "networking"]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

echo "========================================="
echo "Array Text Filter Tests Complete"
echo "========================================="
