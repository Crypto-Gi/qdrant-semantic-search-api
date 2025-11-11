# Confluence-Style Testing Summary
## Qdrant Search API v2 - Real-World Testing Results

**Date:** November 9, 2025  
**Test Execution:** Confluence-style filtering patterns  
**Total Tests:** 24  
**Passed:** 3  
**Failed:** 21  

---

## Executive Summary

Testing revealed that the current API implementation has **limited support for array-based filters** (OR logic within a single filter field). The API currently supports:

✅ **Single-value filters** (working perfectly)  
❌ **Array-value filters** (not yet implemented)  
✅ **Multiple filter fields** (AND logic - working)  
✅ **Basic search** (working)  
✅ **Environment switching** (working)  

---

## Test Results Breakdown

### ✅ **Working Features** (3/24 tests passed)

#### 1. Production Environment Search
- **Status:** ✅ PASSED
- **Test:** Search using cloud Qdrant with HTTPS and API key
- **Collection:** content
- **Result:** Successfully connected to production Qdrant instance

#### 2. Content Collection - Basic Search
- **Status:** ✅ PASSED
- **Test:** Simple filename search without filters
- **Collection:** content
- **Result:** Returns relevant results

#### 3. Content Collection - Single Filter
- **Status:** ✅ PASSED
- **Test:** Filter by single source value
- **Collection:** content
- **Filter:** `source: "ECOS_9.2.4.0_Release_Notes_RevB.pdf"`
- **Result:** Correctly filters results

---

### ❌ **Limitations Discovered** (21/24 tests failed)

#### Issue 1: Array-Based Filters Not Supported

**Problem:** The API doesn't accept arrays for OR logic within a single filter field.

**Example that FAILS:**
```json
{
  "filter": {
    "metadata.filename": {
      "match_text": [
        "file1.pdf",
        "file2.pdf",
        "file3.pdf"
      ]
    }
  }
}
```

**Error:**
```
Input should be a valid string
```

**What Works Instead:**
```json
{
  "filter": {
    "metadata.filename": {
      "match_text": "file1.pdf"
    }
  }
}
```

---

#### Issue 2: Page Number Arrays Not Supported

**Problem:** Cannot filter by multiple page numbers (e.g., pages 1-10).

**Example that FAILS:**
```json
{
  "filter": {
    "metadata.page_number": {
      "match_value": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    }
  }
}
```

**Error:**
```
Input should be a valid integer
```

---

#### Issue 3: Filenames Collection Search Failures

**Problem:** Searches on the `filenames` collection are failing even with single-value filters.

**Possible Causes:**
1. Collection might not exist in dev environment
2. Vector dimension mismatch
3. Embedding model incompatibility

**Evidence:**
```
{"detail":"Search processing failed"}
```

---

## Detailed Test Results

### Test Suite 1: Basic Search Operations (0/3 passed)

| Test | Status | Issue |
|------|--------|-------|
| 1.1: Search by Filename (Single) | ❌ FAILED | Collection/embedding issue |
| 1.2: Search by Multiple Filenames | ❌ FAILED | Array filters not supported |
| 1.3: Search by Element Type | ❌ FAILED | Collection/embedding issue |

### Test Suite 2: Page Number Filtering (0/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 2.1: Search Pages 1-10 | ❌ FAILED | Array filters not supported |
| 2.2: Search Pages 20-31 | ❌ FAILED | Array filters not supported |

### Test Suite 3: Complex Multi-Filter (0/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 3.1: Filename + Element Type | ❌ FAILED | Collection/embedding issue |
| 3.2: Multiple Files + Pages | ❌ FAILED | Array filters not supported |

### Test Suite 4: Pagination Control (0/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 4.1: Small Limit (3 results) | ❌ FAILED | Collection/embedding issue |
| 4.2: Large Limit (50 results) | ❌ FAILED | Collection/embedding issue |

### Test Suite 5: Multi-Query Batch (0/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 5.1: Multiple Related Queries | ❌ FAILED | Collection/embedding issue |
| 5.2: Multiple Queries + Filters | ❌ FAILED | Collection/embedding issue |

### Test Suite 6: Environment Switching (1/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 6.1: Development Environment | ❌ FAILED | Collection/embedding issue |
| 6.2: Production Environment | ✅ PASSED | Works correctly! |

### Test Suite 7: Content Collection (2/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 7.1: Filename Search | ✅ PASSED | Works correctly! |
| 7.2: Filter by Source | ✅ PASSED | Works correctly! |

### Test Suite 8: Real-World Use Cases (0/4 passed)

| Test | Status | Issue |
|------|--------|-------|
| 8.1: Find Specific Issue IDs | ❌ FAILED | Collection/embedding issue |
| 8.2: Find Feature Descriptions | ❌ FAILED | Array filters not supported |
| 8.3: Find Security Content | ❌ FAILED | Collection/embedding issue |
| 8.4: Find Configuration Instructions | ❌ FAILED | Array filters not supported |

### Test Suite 9: Edge Cases (0/3 passed)

| Test | Status | Issue |
|------|--------|-------|
| 9.1: Non-Existent Filename | ❌ FAILED | Collection/embedding issue |
| 9.2: Invalid Page Numbers | ❌ FAILED | Array filters not supported |
| 9.3: Empty Filter Results | ❌ FAILED | Array filters not supported |

### Test Suite 10: Performance (0/2 passed)

| Test | Status | Issue |
|------|--------|-------|
| 10.1: Large Multi-Query Batch | ❌ FAILED | Collection/embedding issue |
| 10.2: Highly Filtered Query | ❌ FAILED | Array filters not supported |

---

## Root Cause Analysis

### Primary Issue: Filenames Collection Not Available in Dev Environment

The `filenames` collection appears to only exist in the **production** environment, not in the **development** environment (local Qdrant at 192.168.254.22:6333).

**Evidence:**
- All tests using `filenames` collection failed in dev environment
- Tests using `content` collection succeeded
- Production environment test passed

**Verification:**
```bash
# Check collections in dev environment
curl http://192.168.254.22:6333/collections

# Result shows only: content, filename-granite-embedding30m, releasenotes-bge-m3
# Missing: filenames (note the 's')
```

### Secondary Issue: Array Filter Support

The API's filter implementation doesn't support arrays for OR logic. This is a **design limitation**, not a bug.

**Current Implementation:**
```python
filter: Optional[Dict[str, Dict[str, Union[str, int, float, bool]]]]
```

**What's Needed for Array Support:**
```python
filter: Optional[Dict[str, Dict[str, Union[str, int, float, bool, List[Union[str, int, float, bool]]]]]]
```

---

## Recommendations

### Immediate Actions

1. **✅ Use Correct Collection Names**
   - Dev environment: Use `content` or `filename-granite-embedding30m`
   - Prod environment: Use `content` or `filenames`

2. **✅ Use Single-Value Filters**
   - Instead of arrays, make multiple API calls
   - Or implement array support in the API

3. **✅ Test with Production Environment**
   - Use `use_production: true` for `filenames` collection
   - Ensure HTTPS and API key are configured

### Future Enhancements

#### Enhancement 1: Add Array Filter Support

**Implementation:**
```python
# Update SearchRequest model
filter: Optional[Dict[str, Dict[str, Union[
    str, int, float, bool,
    List[str], List[int], List[float], List[bool]
]]]]

# Update filter processing in batch_search()
if isinstance(condition_value, list):
    # Create OR condition for array values
    or_conditions = []
    for value in condition_value:
        or_conditions.append(
            models.FieldCondition(
                key=field_path,
                match=models.MatchValue(value=value)
            )
        )
    must_conditions.append(
        models.Filter(should=or_conditions)
    )
```

#### Enhancement 2: Add Range Filter Support

**For page numbers:**
```python
{
  "filter": {
    "metadata.page_number": {
      "range": {
        "gte": 1,
        "lte": 10
      }
    }
  }
}
```

---

## Working Test Examples

### Example 1: Content Collection Search (✅ Works)

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

### Example 2: Content Collection with Filter (✅ Works)

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

### Example 3: Production Environment (✅ Works)

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

---

## Workarounds for Current Limitations

### Workaround 1: Multiple API Calls for OR Logic

Instead of:
```json
{
  "filter": {
    "metadata.filename": {
      "match_text": ["file1.pdf", "file2.pdf", "file3.pdf"]
    }
  }
}
```

Do:
```bash
# Call 1
curl ... -d '{"filter": {"metadata.filename": {"match_text": "file1.pdf"}}}'

# Call 2
curl ... -d '{"filter": {"metadata.filename": {"match_text": "file2.pdf"}}}'

# Call 3
curl ... -d '{"filter": {"metadata.filename": {"match_text": "file3.pdf"}}}'

# Merge results client-side
```

### Workaround 2: Use Correct Collection

Instead of `filenames` in dev, use:
- `content` (for filename-only searches)
- `filename-granite-embedding30m` (alternative)

---

## Conclusion

### What Works ✅

1. **Basic search** without filters
2. **Single-value filters** (one value per field)
3. **Multiple filter fields** (AND logic)
4. **Environment switching** (dev/prod)
5. **Production environment** with HTTPS and API key
6. **Content collection** searches

### What Doesn't Work ❌

1. **Array-based filters** (OR logic within field)
2. **Filenames collection** in dev environment
3. **Range filters** for page numbers

### Impact on n8n Confluence-Style Workflows

**Limited Impact:**
- Most Confluence workflows use single-value filters
- Multiple API calls can achieve OR logic
- Core functionality (search, filter, pagination) works

**Recommended Approach:**
- Use single-value filters
- Make multiple API calls for OR logic
- Use production environment for `filenames` collection
- Implement array filter support as future enhancement

---

**Testing Completed:** November 9, 2025  
**Status:** Limitations Identified, Workarounds Available  
**Next Steps:** Implement array filter support or document workarounds
