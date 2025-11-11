#!/bin/bash

# Test script for range filter functionality
# Tests gte and lte operators

echo "========================================"
echo "Testing Range Filter Functionality"
echo "========================================"
echo ""

# Test 1: gte only
echo "Test 1: gte only (year >= 2020)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "gte": 2020
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 2: lte only
echo "Test 2: lte only (year <= 2024)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "lte": 2024
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 3: Both gte and lte
echo "Test 3: Both gte and lte (2020 <= year <= 2024)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "gte": 2020,
        "lte": 2024
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 4: Range with float values
echo "Test 4: Range with float values (score >= 0.8)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.score": {
        "gte": 0.8,
        "lte": 1.0
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 5: Multiple range filters
echo "Test 5: Multiple range filters (year and score)"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.year": {
        "gte": 2022
      },
      "metadata.score": {
        "gte": 0.7
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

echo "========================================"
echo "Range Filter Tests Complete"
echo "========================================"
