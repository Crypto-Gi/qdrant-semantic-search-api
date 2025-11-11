#!/bin/bash

# Test script for combined filter functionality
# Tests combinations of different filter types

echo "=========================================="
echo "Testing Combined Filter Functionality"
echo "=========================================="
echo ""

# Test 1: Array text filter + single value filter
echo "Test 1: Array text filter + single value filter"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["devops", "infrastructure", "cloud"]
      },
      "metadata.published": {
        "match_value": true
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 2: Array value filter + range filter
echo "Test 2: Array value filter + range filter"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.status": {
        "match_value": ["published", "archived"]
      },
      "metadata.year": {
        "gte": 2020,
        "lte": 2024
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 3: Multiple array filters
echo "Test 3: Multiple array filters"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["devops", "cloud"]
      },
      "metadata.year": {
        "match_value": [2022, 2023, 2024]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 4: All filter types combined
echo "Test 4: All filter types combined"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["test query"],
    "filter": {
      "metadata.category": {
        "match_text": ["devops", "infrastructure"]
      },
      "metadata.year": {
        "gte": 2022,
        "lte": 2024
      },
      "metadata.published": {
        "match_value": true
      },
      "metadata.priority": {
        "match_value": [1, 2, 3]
      }
    },
    "limit": 3
  }' | jq '.'
echo ""
echo ""

# Test 5: Complex real-world scenario
echo "Test 5: Complex real-world scenario"
echo "---------------------------------------------------"
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_name": "test_collection",
    "search_queries": ["kubernetes deployment strategies"],
    "filter": {
      "metadata.doc_type": {
        "match_text": ["best_practices", "implementation_guide", "tutorial"]
      },
      "metadata.publication_year": {
        "gte": 2022
      },
      "metadata.verified": {
        "match_value": true
      },
      "metadata.rating": {
        "gte": 4.0
      }
    },
    "limit": 5
  }' | jq '.'
echo ""
echo ""

echo "=========================================="
echo "Combined Filter Tests Complete"
echo "=========================================="
