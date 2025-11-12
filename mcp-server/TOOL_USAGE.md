# Qdrant RAG MCP Server - Tool Usage Guide

Complete guide for LLMs to understand when and how to use each tool effectively.

---

## 🎯 Quick Reference

| Tool | Use When | Input | Output |
|------|----------|-------|--------|
| **search_filenames_fuzzy** | Need to discover available documents | Query string | List of matching filenames |
| **search_with_filename_filter** | Search within ONE specific document | Query + filename | Relevant passages with context |
| **search_multi_query_with_filter** | Multiple topics in ONE document | Multiple queries + filename | Results for each query |
| **search_across_multiple_files** | Same topic across MULTIPLE documents | Query + multiple filenames | Results grouped by file |
| **compare_versions** | Compare TWO versions side-by-side | Query + 2 version filters | Side-by-side comparison |

---

## 📚 Tool 1: search_filenames_fuzzy

### Purpose
Discover what documents are available in the collection. **Always use this first** when you don't know exact filenames.

### When to Use
- ✅ User asks "What files are available about X?"
- ✅ Need to find release notes for a specific version
- ✅ Discovering product documentation
- ✅ Finding all documents matching a pattern
- ❌ Don't use if you already know the exact filename

### Parameters
```python
search_filenames_fuzzy(
    query: str,           # Search term (e.g., "ecos 9.3", "release notes")
    limit: int = None     # Max results (default: from .env DEFAULT_LIMIT)
)
```

### Examples

**Example 1: Find ECOS 9.3 files**
```python
search_filenames_fuzzy("ecos 9.3", limit=5)
```
**Returns**:
```json
{
  "query": "ecos 9.3",
  "total_matches": 3,
  "filenames": [
    {"filename": "ECOS_9.3.6.0_Release_Notes_RevB", "score": 0.95},
    {"filename": "ECOS_9.3.7.0_Release_Notes_RevA", "score": 0.93},
    {"filename": "ECOS_9.3.5.0_Release_Notes_RevC", "score": 0.88}
  ]
}
```

**Example 2: Find all release notes**
```python
search_filenames_fuzzy("release notes", limit=10)
```

**Example 3: Find specific product**
```python
search_filenames_fuzzy("DHCP server documentation")
```

### Best Practices
1. **Start broad**: Use general terms first ("ecos 9.3" not "ECOS_9.3.6.0_Release_Notes_RevB")
2. **Increase limit**: If not enough results, increase `limit` parameter
3. **Use this first**: Always discover filenames before searching content
4. **Fuzzy matching**: Handles typos and variations automatically

---

## 📖 Tool 2: search_with_filename_filter

### Purpose
Search for specific content within a single document. Use after discovering filename with `search_filenames_fuzzy`.

### When to Use
- ✅ User asks "What does ECOS 9.3.6 say about security?"
- ✅ Need specific information from a known document
- ✅ Want context pages around matches
- ✅ Single topic, single document
- ❌ Don't use for multiple documents (use Tool 4 instead)
- ❌ Don't use for multiple topics (use Tool 3 instead)

### Parameters
```python
search_with_filename_filter(
    query: str,                    # What to search for
    filename_filter: str,          # Which document (exact or partial)
    limit: int = None,             # Max results (default: from .env)
    context_window: int = None     # Pages before/after (0-11, default: from .env)
)
```

### Examples

**Example 1: Find security info in ECOS 9.3.6**
```python
# Step 1: Discover filename
search_filenames_fuzzy("ecos 9.3.6")
# Returns: "ECOS_9.3.6.0_Release_Notes_RevB"

# Step 2: Search within that file
search_with_filename_filter(
    query="security vulnerabilities",
    filename_filter="ECOS_9.3.6.0_Release_Notes_RevB",
    limit=2,
    context_window=3
)
```

**Example 2: Find DHCP configuration**
```python
search_with_filename_filter(
    query="DHCP server configuration",
    filename_filter="ECOS_9.3.6.0",  # Partial match OK
    limit=1,
    context_window=5
)
```

**Example 3: Get more context**
```python
search_with_filename_filter(
    query="performance improvements",
    filename_filter="ECOS_9.3.7.0",
    limit=3,
    context_window=10  # More pages for better context
)
```

### Returns
```json
{
  "results": [[
    {
      "filename": "ECOS_9.3.6.0_Release_Notes_RevB",
      "score": 0.89,
      "center_page": 15,
      "combined_page": "... full text of pages 10-20 ...",
      "page_numbers": [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    }
  ]]
}
```

### Best Practices
1. **Partial filenames OK**: "ECOS_9.3.6" matches "ECOS_9.3.6.0_Release_Notes_RevB"
2. **Adjust context**: Use `context_window=10` for more context, `context_window=1` for focused results
3. **Limit wisely**: Start with `limit=1-2`, increase if needed
4. **Read combined_page**: Contains full text with context pages

---

## 🔍 Tool 3: search_multi_query_with_filter

### Purpose
Run multiple searches within the SAME document efficiently. Batch processing for comprehensive analysis.

### When to Use
- ✅ User asks "Analyze ECOS 9.3.6 for security, performance, and bugs"
- ✅ Need multiple aspects of the same document
- ✅ Comprehensive document analysis
- ✅ Multiple topics, single document
- ❌ Don't use for single topic (use Tool 2 instead)
- ❌ Don't use for multiple documents (use Tool 4 instead)

### Parameters
```python
search_multi_query_with_filter(
    queries: list[str],            # Multiple search queries
    filename_filter: str,          # Single document to search
    limit: int = None,             # Max results per query
    context_window: int = None     # Pages before/after
)
```

### Examples

**Example 1: Comprehensive analysis**
```python
search_multi_query_with_filter(
    queries=["security fixes", "performance improvements", "bug fixes"],
    filename_filter="ECOS_9.3.6.0_Release_Notes_RevB",
    limit=2,
    context_window=5
)
```

**Example 2: Feature investigation**
```python
search_multi_query_with_filter(
    queries=["DHCP", "DNS", "routing", "firewall"],
    filename_filter="ECOS_9.3.7.0",
    limit=1,
    context_window=3
)
```

**Example 3: Problem diagnosis**
```python
search_multi_query_with_filter(
    queries=["memory leak", "crash", "timeout", "deadlock"],
    filename_filter="ECOS_9.3.6.0",
    limit=3,
    context_window=5
)
```

### Returns
```json
{
  "results": [
    [/* Results for query 1: "security fixes" */],
    [/* Results for query 2: "performance improvements" */],
    [/* Results for query 3: "bug fixes" */]
  ]
}
```

### Best Practices
1. **Group related queries**: Keep queries thematically related
2. **3-5 queries optimal**: Too many queries = slower response
3. **Same document**: All queries search the same file
4. **Efficient**: Faster than calling Tool 2 multiple times

---

## 🌐 Tool 4: search_across_multiple_files

### Purpose
Search for the SAME topic across MULTIPLE documents. Cross-file comparison.

### When to Use
- ✅ User asks "How is DHCP covered in ECOS 9.3.5, 9.3.6, and 9.3.7?"
- ✅ Track feature across versions
- ✅ Compare documentation across products
- ✅ Single topic, multiple documents
- ❌ Don't use for multiple topics (use Tool 3 instead)
- ❌ Don't use for single document (use Tool 2 instead)

### Parameters
```python
search_across_multiple_files(
    query: str,                    # Single search query
    filename_filters: list[str],   # Multiple documents
    limit: int = None,             # Max results per file
    context_window: int = None     # Pages before/after
)
```

### Examples

**Example 1: Track feature across versions**
```python
search_across_multiple_files(
    query="DHCP security",
    filename_filters=[
        "ECOS_9.3.5.0_Release_Notes",
        "ECOS_9.3.6.0_Release_Notes",
        "ECOS_9.3.7.0_Release_Notes"
    ],
    limit=2,
    context_window=5
)
```

**Example 2: Compare products**
```python
search_across_multiple_files(
    query="firewall configuration",
    filename_filters=[
        "Product_A_Manual",
        "Product_B_Manual",
        "Product_C_Manual"
    ],
    limit=1,
    context_window=3
)
```

**Example 3: Find all mentions**
```python
search_across_multiple_files(
    query="CVE-2023-12345",
    filename_filters=["ECOS_9.3.5", "ECOS_9.3.6", "ECOS_9.3.7"],
    limit=5,
    context_window=2
)
```

### Returns
```json
{
  "query": "DHCP security",
  "results_by_file": {
    "ECOS_9.3.5.0_Release_Notes": [/* Results from 9.3.5 */],
    "ECOS_9.3.6.0_Release_Notes": [/* Results from 9.3.6 */],
    "ECOS_9.3.7.0_Release_Notes": [/* Results from 9.3.7 */]
  }
}
```

### Best Practices
1. **Same query**: Use identical query for all files
2. **Related files**: Search files that should contain similar info
3. **Version tracking**: Great for tracking changes across versions
4. **Grouped results**: Results organized by filename for easy comparison

---

## ⚖️ Tool 5: compare_versions

### Purpose
Specialized tool for comparing TWO versions side-by-side. Evolution tracking.

### When to Use
- ✅ User asks "How did DHCP change from 9.3.6 to 9.3.7?"
- ✅ Version comparison (before/after)
- ✅ Evolution analysis
- ✅ Regression checking
- ❌ Don't use for more than 2 versions (use Tool 4 instead)
- ❌ Don't use for single version (use Tool 2 instead)

### Parameters
```python
compare_versions(
    query: str,                    # What to compare
    version1_filter: str,          # First version
    version2_filter: str,          # Second version
    limit: int = None,             # Max results per version
    context_window: int = None     # Pages before/after
)
```

### Examples

**Example 1: Compare DHCP security**
```python
compare_versions(
    query="DHCP security improvements",
    version1_filter="ECOS_9.3.6.0_Release_Notes",
    version2_filter="ECOS_9.3.7.0_Release_Notes",
    limit=2,
    context_window=5
)
```

**Example 2: Track bug fix**
```python
compare_versions(
    query="memory leak fix",
    version1_filter="ECOS_9.3.5",
    version2_filter="ECOS_9.3.6",
    limit=1,
    context_window=3
)
```

**Example 3: Feature evolution**
```python
compare_versions(
    query="routing protocol",
    version1_filter="Product_v1.0",
    version2_filter="Product_v2.0",
    limit=3,
    context_window=7
)
```

### Returns
```json
{
  "query": "DHCP security improvements",
  "version1": {
    "filename": "ECOS_9.3.6.0_Release_Notes_RevB",
    "results": [/* Results from version 1 */]
  },
  "version2": {
    "filename": "ECOS_9.3.7.0_Release_Notes_RevA",
    "results": [/* Results from version 2 */]
  }
}
```

### Best Practices
1. **Two versions only**: Designed for before/after comparison
2. **Same query**: Use identical query for both versions
3. **Adjacent versions**: Works best for consecutive versions
4. **Side-by-side**: Results structured for easy comparison

---

## 🎓 Decision Tree: Which Tool to Use?

```
START: User asks a question
    ↓
Do you know the exact filename?
    ├─ NO → Use Tool 1 (search_filenames_fuzzy)
    │        Then proceed with filename
    ↓
    └─ YES
        ↓
How many documents?
    ├─ ONE document
    │   ↓
    │   How many topics?
    │   ├─ ONE topic → Use Tool 2 (search_with_filename_filter)
    │   └─ MULTIPLE topics → Use Tool 3 (search_multi_query_with_filter)
    │
    └─ MULTIPLE documents
        ↓
        How many documents?
        ├─ TWO documents (version comparison) → Use Tool 5 (compare_versions)
        └─ MORE than two → Use Tool 4 (search_across_multiple_files)
```

---

## 💡 Common Workflows

### Workflow 1: Explore and Search
```
User: "What security issues are in ECOS 9.3.6?"

Step 1: Discover files
→ search_filenames_fuzzy("ecos 9.3.6")
→ Get: "ECOS_9.3.6.0_Release_Notes_RevB"

Step 2: Search for security
→ search_with_filename_filter(
    query="security issues",
    filename_filter="ECOS_9.3.6.0_Release_Notes_RevB"
  )
→ Get: Relevant security passages
```

### Workflow 2: Comprehensive Analysis
```
User: "Analyze ECOS 9.3.7 for security, performance, and bugs"

Step 1: Discover file
→ search_filenames_fuzzy("ecos 9.3.7")
→ Get: "ECOS_9.3.7.0_Release_Notes_RevA"

Step 2: Multi-query search
→ search_multi_query_with_filter(
    queries=["security", "performance", "bugs"],
    filename_filter="ECOS_9.3.7.0_Release_Notes_RevA"
  )
→ Get: Results for all three topics
```

### Workflow 3: Version Comparison
```
User: "How did DHCP evolve from 9.3.6 to 9.3.7?"

Step 1: Compare versions
→ compare_versions(
    query="DHCP",
    version1_filter="ECOS_9.3.6.0",
    version2_filter="ECOS_9.3.7.0"
  )
→ Get: Side-by-side DHCP information
```

### Workflow 4: Cross-Version Tracking
```
User: "How is firewall covered in ECOS 9.3.5, 9.3.6, and 9.3.7?"

Step 1: Search across files
→ search_across_multiple_files(
    query="firewall",
    filename_filters=["ECOS_9.3.5", "ECOS_9.3.6", "ECOS_9.3.7"]
  )
→ Get: Firewall info from all three versions
```

---

## ⚙️ Parameter Guidelines

### limit Parameter

| Use Case | Recommended Limit | Reason |
|----------|------------------|---------|
| Quick answer | `1-2` | Focused, fast results |
| Comprehensive | `3-5` | More coverage |
| Exhaustive | `5-10` | Complete information |
| Discovery | `10-20` | Find all mentions |

**Default**: Uses `.env DEFAULT_LIMIT` (typically 1)

### context_window Parameter

| Use Case | Recommended Window | Total Pages | Reason |
|----------|-------------------|-------------|---------|
| Focused snippet | `1-2` | 3-5 pages | Just the match |
| Normal context | `3-5` | 7-11 pages | Good context |
| Full context | `7-10` | 15-21 pages | Maximum context |
| Maximum | `11` | 23 pages | API limit |

**Default**: Uses `.env DEFAULT_CONTEXT_WINDOW` (typically 5)

**Formula**: Total pages = (window × 2) + 1 center page

---

## 🚫 Common Mistakes to Avoid

### ❌ Mistake 1: Not discovering filenames first
```python
# WRONG: Guessing filename
search_with_filename_filter("security", "ecos_9_3_6")

# RIGHT: Discover first
search_filenames_fuzzy("ecos 9.3.6")
# Then use exact filename returned
```

### ❌ Mistake 2: Using wrong tool for multiple documents
```python
# WRONG: Calling Tool 2 multiple times
search_with_filename_filter("DHCP", "ECOS_9.3.5")
search_with_filename_filter("DHCP", "ECOS_9.3.6")
search_with_filename_filter("DHCP", "ECOS_9.3.7")

# RIGHT: Use Tool 4 once
search_across_multiple_files(
    "DHCP",
    ["ECOS_9.3.5", "ECOS_9.3.6", "ECOS_9.3.7"]
)
```

### ❌ Mistake 3: Using wrong tool for multiple topics
```python
# WRONG: Calling Tool 2 multiple times
search_with_filename_filter("security", "ECOS_9.3.6")
search_with_filename_filter("performance", "ECOS_9.3.6")
search_with_filename_filter("bugs", "ECOS_9.3.6")

# RIGHT: Use Tool 3 once
search_multi_query_with_filter(
    ["security", "performance", "bugs"],
    "ECOS_9.3.6"
)
```

### ❌ Mistake 4: Excessive context window
```python
# WRONG: Always using max context
search_with_filename_filter("bug", "ECOS_9.3.6", context_window=11)

# RIGHT: Use appropriate context
search_with_filename_filter("bug", "ECOS_9.3.6", context_window=3)
```

---

## 📊 Performance Tips

1. **Start with Tool 1**: Always discover filenames first
2. **Batch queries**: Use Tool 3 for multiple topics in same file
3. **Batch files**: Use Tool 4 for same topic across files
4. **Adjust limits**: Start small (1-2), increase if needed
5. **Context wisely**: More context = more tokens, slower response
6. **Partial filenames**: "ECOS_9.3.6" matches full filename
7. **Fuzzy search**: Handles typos and variations

---

## 🎯 Summary

| Scenario | Tool | Example |
|----------|------|---------|
| **Find files** | Tool 1 | "What ECOS 9.3 files exist?" |
| **One topic, one file** | Tool 2 | "Security in ECOS 9.3.6?" |
| **Multiple topics, one file** | Tool 3 | "Security, performance, bugs in 9.3.6?" |
| **One topic, many files** | Tool 4 | "DHCP in 9.3.5, 9.3.6, 9.3.7?" |
| **Compare two versions** | Tool 5 | "DHCP changes from 9.3.6 to 9.3.7?" |

---

**Remember**: 
- 🔍 **Discover first** (Tool 1)
- 📖 **Search smart** (Tools 2-5)
- ⚙️ **Adjust parameters** (limit, context_window)
- 🎯 **Choose right tool** (Use decision tree)

Happy searching! 🚀
