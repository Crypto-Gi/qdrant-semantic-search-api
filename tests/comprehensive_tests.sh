#!/bin/bash

# ============================================================================
# COMPREHENSIVE API TEST SUITE - 50 Tests
# Testing Qdrant Semantic Search API with Production Data
# Embedding Models: granite-embedding:30m (384d) for filenames, bge-m3 (1024d) for content
# ============================================================================

API_URL="http://localhost:8001"
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TEST_NUM=0

# Function to run test
run_test() {
    TEST_NUM=$((TEST_NUM + 1))
    local test_name="$1"
    local curl_cmd="$2"
    local expected_pattern="$3"
    
    echo -e "\n${YELLOW}Test #${TEST_NUM}: ${test_name}${NC}"
    echo "Command: $curl_cmd"
    
    result=$(eval "$curl_cmd" 2>&1)
    
    if echo "$result" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "Response: $result"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo "============================================================================"
echo "STARTING COMPREHENSIVE API TEST SUITE"
echo "============================================================================"

# ============================================================================
# SECTION 1: BASIC SEARCH TESTS (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 1: BASIC SEARCH TESTS ===${NC}"

run_test "Basic search - ECOS 9.3.2.1" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS 9.3.2.1\"], \"use_production\": true, \"limit\": 3}'" \
    "ECOS_9.3.2.1"

run_test "Basic search - Orchestrator 9.1.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"Orchestrator 9.1.2\"], \"use_production\": true, \"limit\": 3}'" \
    "Orchestrator"

run_test "Basic search - Content collection" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"installation requirements\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 3}'" \
    "filename"

run_test "Search with limit=1" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS\"], \"use_production\": true, \"limit\": 1}'" \
    "score"

run_test "Search with limit=10" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"release notes\"], \"use_production\": true, \"limit\": 10}'" \
    "results"

# ============================================================================
# SECTION 2: BATCH SEARCH TESTS (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 2: BATCH SEARCH TESTS ===${NC}"

run_test "Batch search - 2 queries" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS 9.3\", \"Orchestrator 9.2\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Batch search - 3 queries" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS 9.1\", \"ECOS 9.2\", \"ECOS 9.3\"], \"use_production\": true, \"limit\": 2}'" \
    "results"

run_test "Batch search - 5 queries" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"version 9.1\", \"version 9.2\", \"version 9.3\", \"version 9.4\", \"version 9.5\"], \"use_production\": true, \"limit\": 2}'" \
    "results"

run_test "Batch search - Different products" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS latest\", \"Orchestrator latest\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Batch search - Content collection" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"installation\", \"configuration\", \"troubleshooting\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2}'" \
    "results"

# ============================================================================
# SECTION 3: FILTERING TESTS - TEXT MATCHING (10 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 3: TEXT MATCHING FILTERS ===${NC}"

run_test "Filter - Single text match (ECOS)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"installation\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS\"}}, \"use_production\": true, \"limit\": 3}'" \
    "ECOS"

run_test "Filter - Single text match (Orchestrator)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"configuration\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator\"}}, \"use_production\": true, \"limit\": 3}'" \
    "Orchestrator"

run_test "Filter - Text match with version 9.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"features\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"9.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "9.2"

run_test "Filter - Text match with version 9.3" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"updates\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"9.3\"}}, \"use_production\": true, \"limit\": 3}'" \
    "9.3"

run_test "Filter - Array text match (multiple versions)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"release\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": [\"9.1\", \"9.2\", \"9.3\"]}}, \"use_production\": true, \"limit\": 5}'" \
    "results"

run_test "Filter - Array text match (ECOS and Orchestrator)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"documentation\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": [\"ECOS\", \"Orchestrator\"]}}, \"use_production\": true, \"limit\": 5}'" \
    "results"

run_test "Filter - Specific filename ECOS_9.2.10" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"changes\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS_9.2.10\"}}, \"use_production\": true, \"limit\": 3}'" \
    "ECOS_9.2.10"

run_test "Filter - Specific filename Orchestrator_9.1" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"improvements\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator.*9.1\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Filter - RevA versions only" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"notes\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"RevA\"}}, \"use_production\": true, \"limit\": 3}'" \
    "RevA"

run_test "Filter - RevB and RevC versions" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"updates\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": [\"RevB\", \"RevC\"]}}, \"use_production\": true, \"limit\": 5}'" \
    "results"

# ============================================================================
# SECTION 4: RANGE FILTERS (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 4: RANGE FILTERS ===${NC}"

run_test "Range filter - Pages 1-10" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"introduction\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.page_number\": {\"gte\": 1, \"lte\": 10}}, \"use_production\": true, \"limit\": 3}'" \
    "page_number"

run_test "Range filter - Pages 10-20" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"configuration\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.page_number\": {\"gte\": 10, \"lte\": 20}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Range filter - Pages >= 50" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"appendix\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.page_number\": {\"gte\": 50}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Range filter - Pages <= 5 (early pages)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"overview\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.page_number\": {\"lte\": 5}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Range filter - Middle pages 20-30" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"features\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.page_number\": {\"gte\": 20, \"lte\": 30}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

# ============================================================================
# SECTION 5: COMBINED FILTERS (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 5: COMBINED FILTERS ===${NC}"

run_test "Combined - ECOS + Pages 1-10" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"installation\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS\"}, \"metadata.page_number\": {\"gte\": 1, \"lte\": 10}}, \"use_production\": true, \"limit\": 3}'" \
    "ECOS"

run_test "Combined - Orchestrator + Pages 1-20" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"setup\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator\"}, \"metadata.page_number\": {\"gte\": 1, \"lte\": 20}}, \"use_production\": true, \"limit\": 3}'" \
    "Orchestrator"

run_test "Combined - Version 9.2 + Early pages" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"requirements\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"9.2\"}, \"metadata.page_number\": {\"lte\": 15}}, \"use_production\": true, \"limit\": 3}'" \
    "9.2"

run_test "Combined - Multiple versions + Page range" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"features\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": [\"9.1\", \"9.2\"]}, \"metadata.page_number\": {\"gte\": 5, \"lte\": 25}}, \"use_production\": true, \"limit\": 5}'" \
    "results"

run_test "Combined - RevA + Specific pages" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"changes\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"RevA\"}, \"metadata.page_number\": {\"gte\": 1, \"lte\": 30}}, \"use_production\": true, \"limit\": 3}'" \
    "RevA"

# ============================================================================
# SECTION 6: CONTEXT WINDOW TESTS (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 6: CONTEXT WINDOW TESTS ===${NC}"

run_test "Context window - Size 0 (no context)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"installation\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2, \"context_window_size\": 0}'" \
    "page_numbers"

run_test "Context window - Size 2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"configuration\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2, \"context_window_size\": 2}'" \
    "page_numbers"

run_test "Context window - Size 5 (default)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"features\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2, \"context_window_size\": 5}'" \
    "page_numbers"

run_test "Context window - Size 10 (large)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"troubleshooting\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2, \"context_window_size\": 10}'" \
    "page_numbers"

run_test "Context window - Size 1 (minimal)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"overview\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 2, \"context_window_size\": 1}'" \
    "page_numbers"

# ============================================================================
# SECTION 7: EMBEDDING MODEL TESTS (3 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 7: EMBEDDING MODEL TESTS ===${NC}"

run_test "Default embedding model (granite-embedding:30m)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS 9.3\"], \"use_production\": true, \"limit\": 3}'" \
    "score"

run_test "Explicit embedding model - granite-embedding:30m" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"Orchestrator 9.2\"], \"embedding_model\": \"granite-embedding:30m\", \"use_production\": true, \"limit\": 3}'" \
    "score"

run_test "Content collection with bge-m3" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"release notes\"], \"embedding_model\": \"bge-m3\", \"use_production\": true, \"limit\": 3}'" \
    "score"

# ============================================================================
# SECTION 8: SPECIFIC VERSION SEARCHES (7 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 8: SPECIFIC VERSION SEARCHES ===${NC}"

run_test "Search - ECOS 9.1.4.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"ECOS 9.1.4.2 features\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS_9.1.4.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - ECOS 9.2.10" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"ECOS 9.2.10 changes\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS_9.2.10\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - ECOS 9.3.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"ECOS 9.3.2 updates\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"ECOS_9.3.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - Orchestrator 9.1.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"Orchestrator 9.1.2 features\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator.*9.1.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - Orchestrator 9.2.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"Orchestrator 9.2.2 improvements\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator.*9.2.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - Orchestrator 9.3.1" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"Orchestrator 9.3.1 release\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator.*9.3.1\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Search - Orchestrator 9.4.2" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"content\", \"search_queries\": [\"Orchestrator 9.4.2 notes\"], \"embedding_model\": \"bge-m3\", \"filter\": {\"metadata.filename\": {\"match_text\": \"Orchestrator.*9.4.2\"}}, \"use_production\": true, \"limit\": 3}'" \
    "results"

# ============================================================================
# SECTION 9: EDGE CASES AND ERROR HANDLING (5 tests)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 9: EDGE CASES ===${NC}"

run_test "Empty query string" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Very long query" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS release notes version 9.3.2.1 with all the latest features and improvements and bug fixes\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Special characters in query" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"ECOS_9.3.2.1_Release_Notes_RevA\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

run_test "Limit = 50 (large result set)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"release\"], \"use_production\": true, \"limit\": 50}'" \
    "results"

run_test "No results expected (gibberish query)" \
    "curl -s -X POST $API_URL/search -H 'Content-Type: application/json' -d '{\"collection_name\": \"filenames\", \"search_queries\": [\"xyzabc123nonexistent\"], \"use_production\": true, \"limit\": 3}'" \
    "results"

# ============================================================================
# SECTION 10: HEALTH CHECK (1 test)
# ============================================================================
echo -e "\n${YELLOW}=== SECTION 10: HEALTH CHECK ===${NC}"

run_test "Health check endpoint" \
    "curl -s -X GET $API_URL/health" \
    "status"

# ============================================================================
# FINAL RESULTS
# ============================================================================
echo ""
echo "============================================================================"
echo "TEST SUITE COMPLETED"
echo "============================================================================"
echo -e "Total Tests: ${TEST_NUM}"
echo -e "${GREEN}Passed: ${PASS_COUNT}${NC}"
echo -e "${RED}Failed: ${FAIL_COUNT}${NC}"
echo "============================================================================"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED ⚠️${NC}"
    exit 1
fi
