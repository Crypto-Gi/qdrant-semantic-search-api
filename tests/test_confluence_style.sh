#!/bin/bash

# Comprehensive Array Filter Testing Script
# Tests the new array filter support (match_text and match_value with arrays)
# Based on Real Qdrant Data Structure

BASE_URL="http://localhost:8000"
PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -E '(DEV|PROD)_(FILENAMES|CONTENT)_EMBEDDING_MODEL' | xargs)
fi

# Set embedding models from .env or use defaults
DEV_FILENAMES_MODEL="${DEV_FILENAMES_EMBEDDING_MODEL:-granite-embedding:30m}"
DEV_CONTENT_MODEL="${DEV_CONTENT_EMBEDDING_MODEL:-bge-m3}"
PROD_FILENAMES_MODEL="${PROD_FILENAMES_EMBEDDING_MODEL:-granite-embedding:30m}"
PROD_CONTENT_MODEL="${PROD_CONTENT_EMBEDDING_MODEL:-bge-m3}"

echo "========================================="
echo "Qdrant Search API - Array Filter Testing"
echo "Based on Real Vector Store Structure"
echo "========================================="
echo ""
echo "Embedding Models Configuration:"
echo "  DEV Filenames: $DEV_FILENAMES_MODEL"
echo "  DEV Content: $DEV_CONTENT_MODEL"
echo "  PROD Filenames: $PROD_FILENAMES_MODEL"
echo "  PROD Content: $PROD_CONTENT_MODEL"
echo ""

# Test function
test_search() {
    local test_name="$1"
    local data="$2"
    local check_pattern="$3"
    
    echo -n "Testing: $test_name... "
    
    response=$(curl -s -X POST "$BASE_URL/search" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    if echo "$response" | grep -q "$check_pattern"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Response: $response" | head -5
        ((FAILED++))
        return 1
    fi
}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 1: Basic Search (Dev Environment)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 1.1: Search by Filename (Single Match) - DEV
test_search "1.1: DEV - Single Filename Filter" '{
  "collection_name": "filenames",
  "search_queries": ["ECOS 9.2.4.0 release notes"],
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 1.2: Search by Multiple Filenames (OR Logic) - DEV - ARRAY FILTER
test_search "1.2: DEV - Multiple Filenames (Array Filter)" '{
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
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 1.3: Search by Element Type (Table Only) - DEV
test_search "1.3: DEV - Element Type Filter" '{
  "collection_name": "filenames",
  "search_queries": ["issue resolution"],
  "filter": {
    "metadata.element_type": {
      "match_text": "Table"
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 2: Page Number Filtering (Dev)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 2.1: Search Specific Page Range (1-10) - ARRAY FILTER
test_search "2.1: DEV - Pages 1-10 (Array Filter)" '{
  "collection_name": "filenames",
  "search_queries": ["introduction overview"],
  "filter": {
    "metadata.page_number": {
      "match_value": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 2.2: Search Late Pages (20-25) - ARRAY FILTER
test_search "2.2: DEV - Pages 20-25 (Array Filter)" '{
  "collection_name": "filenames",
  "search_queries": ["resolved issues"],
  "filter": {
    "metadata.page_number": {
      "match_value": [20, 21, 22, 23, 24, 25]
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 3: Complex Multi-Filter (Dev)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 3.1: Filename + Element Type (AND Logic) - DEV
test_search "3.1: DEV - Filename + Element Type (AND)" '{
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
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 3.2: Multiple Files + Specific Pages - ARRAY FILTERS
test_search "3.2: DEV - Multiple Files + Pages (Array Filters)" '{
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
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 4: Production Environment${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 4.1: Production - Content Collection with granite (384 dims)
test_search "4.1: PROD - Content Collection (granite)" '{
  "collection_name": "content",
  "search_queries": ["ECOS release"],
    "embedding_model": "'$PROD_CONTENT_MODEL'",
  "use_production": true,
  "limit": 5
}' '"results"'

# Test 4.2: Production - Filenames Collection with bge-m3
test_search "4.2: PROD - Filenames Collection (bge-m3)" '{
  "collection_name": "filenames",
  "search_queries": ["VPN configuration"],
    "embedding_model": "'$PROD_FILENAMES_MODEL'",
  "use_production": true,
  "limit": 5
}' '"results"'

# Test 4.3: Production - Filter by Source (content collection)
test_search "4.3: PROD - Content Filter by Source" '{
  "collection_name": "content",
  "search_queries": ["release notes"],
  "filter": {
    "source": {
      "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
    }
  },
    "embedding_model": "'$PROD_CONTENT_MODEL'",
  "use_production": true,
  "limit": 5
}' '"results"'

# Test 4.4: Production - Multiple Filenames Array Filter
test_search "4.4: PROD - Multiple Filenames (Array)" '{
  "collection_name": "filenames",
  "search_queries": ["BGP OSPF routing"],
  "filter": {
    "metadata.filename": {
      "match_text": [
        "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
        "Orchestrator_Release_Notes_Version_9.3.3_RevA.pdf"
      ]
    }
  },
    "embedding_model": "'$PROD_FILENAMES_MODEL'",
  "use_production": true,
  "limit": 10
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 5: Multi-Query Batch${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 5.1: Multiple Related Queries - DEV
test_search "5.1: DEV - Multiple Queries (3)" '{
  "collection_name": "filenames",
  "search_queries": [
    "BGP configuration",
    "OSPF routing",
    "IPSec tunnels"
  ],
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 3
}' '"results"'

# Test 5.2: Multiple Queries with Array Filters - DEV
test_search "5.2: DEV - Multiple Queries + Array Filters" '{
  "collection_name": "filenames",
  "search_queries": [
    "new features",
    "resolved issues",
    "upgrade considerations"
  ],
  "filter": {
    "metadata.filename": {
      "match_text": [
        "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
        "ECOS_9.1.4.2_Release_Notes_RevC.pdf"
      ]
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 6: Edge Cases${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 6.1: Non-Existent Filename
test_search "6.1: DEV - Non-Existent Filename" '{
  "collection_name": "filenames",
  "search_queries": ["test query"],
  "filter": {
    "metadata.filename": {
      "match_text": "NonExistentFile.pdf"
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 6.2: Invalid Page Numbers (Array)
test_search "6.2: DEV - Invalid Page Numbers (Array)" '{
  "collection_name": "filenames",
  "search_queries": ["test query"],
  "filter": {
    "metadata.page_number": {
      "match_value": [999, 1000, 1001]
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 6.3: Empty Array Filter (should handle gracefully)
test_search "6.3: DEV - Single Element Type Array" '{
  "collection_name": "filenames",
  "search_queries": ["configuration"],
  "filter": {
    "metadata.element_type": {
      "match_text": ["Table"]
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 7: Backward Compatibility${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 7.1: Old-style single value filters (backward compat)
test_search "7.1: DEV - Backward Compat (Single Values)" '{
  "collection_name": "filenames",
  "search_queries": ["IPSec configuration"],
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
    },
    "metadata.element_type": {
      "match_text": "Table"
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 7.2: Mixed single and array filters
test_search "7.2: DEV - Mixed Single + Array Filters" '{
  "collection_name": "filenames",
  "search_queries": ["routing protocols"],
  "filter": {
    "metadata.filename": {
      "match_text": [
        "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
        "ECOS_9.1.4.2_Release_Notes_RevC.pdf"
      ]
    },
    "metadata.element_type": {
      "match_text": "Table"
    }
  },
    "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 8: Release Notes Collection (releasenotes-bge-m3)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 8.1: Basic search on releasenotes-bge-m3
test_search "8.1: DEV - Release Notes Basic Search" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["BGP routing issues"],
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 8.2: Filter by specific filename
test_search "8.2: DEV - Release Notes Single Filename" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["security vulnerability"],
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS_9.3.2.3_Release_Notes_RevC.pdf"
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 8.3: Filter by multiple filenames (Array)
test_search "8.3: DEV - Release Notes Multiple Files (Array)" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["appliance reboot issues"],
  "filter": {
    "metadata.filename": {
      "match_text": [
        "ECOS_9.3.2.3_Release_Notes_RevC.pdf",
        "ECOS_9.4.2.6_Release_Notes_RevA.pdf"
      ]
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 8.4: Filter by element type (Table)
test_search "8.4: DEV - Release Notes Element Type Table" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["resolved issues"],
  "filter": {
    "metadata.element_type": {
      "match_text": "Table"
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 8.5: Filter by element type (Image)
test_search "8.5: DEV - Release Notes Element Type Image" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["appliance configuration"],
  "filter": {
    "metadata.element_type": {
      "match_text": "Image"
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 8.6: Filter by page range (Array)
test_search "8.6: DEV - Release Notes Page Range" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["issue resolution"],
  "filter": {
    "metadata.page_number": {
      "match_value": [40, 41, 42, 43, 44, 45]
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 8.7: Complex multi-filter
test_search "8.7: DEV - Release Notes Complex Filter" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["BGP OSPF routing"],
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS_9.3.2.3_Release_Notes_RevC.pdf"
    },
    "metadata.element_type": {
      "match_text": "Table"
    },
    "metadata.page_number": {
      "match_value": [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50]
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 8.8: Multiple queries batch
test_search "8.8: DEV - Release Notes Multi-Query" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": [
    "VPN tunnel issues",
    "firewall configuration",
    "upgrade problems"
  ],
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 3
}' '"results"'

# Test 8.9: Array filter with multiple element types
test_search "8.9: DEV - Release Notes Multiple Element Types" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["security patches"],
  "filter": {
    "metadata.element_type": {
      "match_text": ["Table", "Image"]
    }
  },
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 8.10: Context window size override
test_search "8.10: DEV - Release Notes Custom Context Window" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": ["memory leak"],
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 5,
  "context_window_size": 2
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 9: Content Collection Tests${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 9.1: Basic content search
test_search "9.1: DEV - Content Basic Search" '{
  "collection_name": "content",
  "search_queries": ["ECOS features"],
  "embedding_model": "'$DEV_CONTENT_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 9.2: Content filter by filename
test_search "9.2: DEV - Content Filter by Filename" '{
  "collection_name": "content",
  "search_queries": ["configuration guide"],
  "filter": {
    "metadata.filename": {
      "match_text": "ECOS_9.2.4.0_Release_Notes_RevB.pdf"
    }
  },
  "embedding_model": "'$DEV_CONTENT_MODEL'",
  "use_production": false,
  "limit": 5
}' '"results"'

# Test 9.3: Content with context window
test_search "9.3: DEV - Content Custom Context" '{
  "collection_name": "content",
  "search_queries": ["network topology"],
  "embedding_model": "'$DEV_CONTENT_MODEL'",
  "use_production": false,
  "limit": 3,
  "context_window_size": 3
}' '"results"'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Suite 10: Performance Tests${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 10.1: Large Multi-Query Batch (Filenames)
test_search "10.1: DEV - Filenames Large Batch (10 queries)" '{
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
  "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 2
}' '"results"'

# Test 10.2: Highly Filtered Query with Arrays
test_search "10.2: DEV - Complex Array Filters" '{
  "collection_name": "filenames",
  "search_queries": ["configuration"],
  "filter": {
    "metadata.filename": {
      "match_text": [
        "ECOS_9.2.4.0_Release_Notes_RevB.pdf",
        "ECOS_9.1.4.2_Release_Notes_RevC.pdf",
        "ECOS_9.1.0.0_Release_Notes_RevA.pdf"
      ]
    },
    "metadata.element_type": {
      "match_text": "Table"
    },
    "metadata.page_number": {
      "match_value": [1, 2, 3, 4, 5, 10, 15, 20]
    }
  },
  "embedding_model": "'$DEV_FILENAMES_MODEL'",
  "use_production": false,
  "limit": 10
}' '"results"'

# Test 10.3: Release Notes Large Batch
test_search "10.3: DEV - Release Notes Large Batch (8 queries)" '{
  "collection_name": "releasenotes-bge-m3",
  "search_queries": [
    "BGP issues",
    "OSPF problems",
    "VPN tunnel",
    "firewall rules",
    "security patches",
    "upgrade issues",
    "memory leak",
    "appliance reboot"
  ],
  "embedding_model": "bge-m3",
  "use_production": false,
  "limit": 2
}' '"results"'

# Test 10.4: Content Large Batch
test_search "10.4: DEV - Content Large Batch (5 queries)" '{
  "collection_name": "content",
  "search_queries": [
    "network configuration",
    "security features",
    "performance optimization",
    "troubleshooting guide",
    "installation steps"
  ],
  "embedding_model": "'$DEV_CONTENT_MODEL'",
  "use_production": false,
  "limit": 2
}' '"results"'

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
