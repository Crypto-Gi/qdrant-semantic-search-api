# MCP Server for Qdrant RAG Application

**Status**: ✅ Ready to Deploy  
**Version**: 1.0.0

---

## 📖 Overview

This MCP (Model Context Protocol) server enables Large Language Models to interact with our Qdrant-based RAG system for searching and analyzing release note documentation.

### What is MCP?

MCP is a protocol that allows LLMs (like Claude, GPT, Gemini) to use external tools and data sources. Think of it as an API specifically designed for AI agents.

### What This Server Does

**Phase 1**: 5 core tools for LLMs to:
1. **Discover** - Find relevant release note files
2. **Retrieve** - Get content from specific documents with context
3. **Batch** - Run multiple queries efficiently
4. **Compare** - Analyze differences across versions
5. **Cross-search** - Search same topic across multiple files

**Phase 2**: Additional tool for version discovery:
6. **List Versions** - Discover all available product versions

---

## 🎯 Use Cases

### Example 1: Find and Read Release Notes
**User**: "What security fixes are in ECOS 9.3.7?"

**LLM Workflow**:
1. Calls `search_filenames_fuzzy("ecos 9.3.7")`
2. Gets: `"ECOS_9.3.7.0_Release_Notes_RevB"`
3. Calls `search_with_filename_filter("security fixes", "ECOS_9.3.7.0_Release_Notes_RevB")`
4. Returns security fix details with page context

### Example 2: Comprehensive Analysis
**User**: "Analyze ECOS 9.3.7 for security, performance, and bugs"

**LLM Workflow**:
1. Calls `search_filenames_fuzzy("ecos 9.3.7")`
2. Calls `search_multi_query_with_filter(["security", "performance", "bugs"], "ECOS_9.3.7.0_Release_Notes_RevB")`
3. Returns all three analyses in one call

### Example 3: Version Comparison
**User**: "How did DHCP security evolve from 9.3.6 to 9.3.7?"

**LLM Workflow**:
1. Calls `compare_versions("DHCP security", "ECOS_9.3.6.0_Release_Notes_RevB", "ECOS_9.3.7.0_Release_Notes_RevB")`
2. Returns side-by-side comparison

---

## 📁 Project Structure

```
mcp-server/
├── README.md                    # This file
├── DESIGN.md                    # Comprehensive design document
├── API_TESTING_GUIDE.md         # Testing methodology
├── test_results/                # API test outputs (gitignored)
│   ├── tool1_test1.json
│   ├── tool2_test1.json
│   └── ...
├── src/                         # Source code (to be created)
│   ├── server.py               # Main MCP server
│   ├── tools/                  # Tool implementations
│   │   ├── __init__.py
│   │   ├── filename_search.py
│   │   ├── filtered_search.py
│   │   ├── multi_query.py
│   │   ├── cross_file.py
│   │   └── compare.py
│   ├── config.py               # Configuration
│   └── utils.py                # Helper functions
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Docker image
└── docker-compose.yml          # Docker compose config
```

---

## 🛠️ Tools

### Tool 1: `search_filenames_fuzzy`
**Purpose**: Find release note files using fuzzy text matching

**Parameters**:
- `query` (string, required): Search term
- `collection_name` (string, optional): Qdrant collection (default: "content")
- `limit` (integer, optional): Max results (default: 10, range: 1-100)

**Example**:
```python
search_filenames_fuzzy(
    query="ecos 9.3",
    limit=5
)
```

---

### Tool 2: `search_with_filename_filter`
**Purpose**: Search within a specific release note file with context

**Parameters**:
- `query` (string, required): What to search for
- `filename` (string, required): Exact filename from Tool 1
- `collection_name` (string, optional): Default "content"
- `limit` (integer, optional): Max results (default: 3)
- `context_window_size` (integer, optional): Pages before/after (default: 5)

**Example**:
```python
search_with_filename_filter(
    query="security fixes",
    filename="ECOS_9.3.7.0_Release_Notes_RevB",
    limit=3,
    context_window_size=5
)
```

---

### Tool 3: `search_multi_query_with_filter`
**Purpose**: Run multiple queries on the same file efficiently

**Parameters**:
- `queries` (array[string], required): Multiple search queries
- `filename` (string, required): Target file
- `collection_name` (string, optional): Default "content"
- `limit` (integer, optional): Max results per query (default: 3)
- `context_window_size` (integer, optional): Default 5

**Example**:
```python
search_multi_query_with_filter(
    queries=["security", "performance", "bugs"],
    filename="ECOS_9.3.7.0_Release_Notes_RevB",
    limit=2
)
```

---

### Tool 4: `search_across_multiple_files`
**Purpose**: Search same query across multiple versions

**Parameters**:
- `query` (string, required): Single search query
- `filenames` (array[string], required): List of files to search
- `collection_name` (string, optional): Default "content"
- `limit` (integer, optional): Max results per file (default: 3)
- `context_window_size` (integer, optional): Default 5

**Example**:
```python
search_across_multiple_files(
    query="DHCP security",
    filenames=[
        "ECOS_9.3.7.0_Release_Notes_RevB",
        "ECOS_9.3.6.0_Release_Notes_RevB",
        "ECOS_9.3.5.0_Release_Notes_RevA"
    ]
)
```

---

### Tool 5: `compare_versions`
**Purpose**: Side-by-side comparison of topic across two versions

**Parameters**:
- `query` (string, required): Topic to compare
- `version1_filename` (string, required): First version
- `version2_filename` (string, required): Second version
- `collection_name` (string, optional): Default "content"
- `limit` (integer, optional): Max results per version (default: 3)

**Example**:
```python
compare_versions(
    query="DHCP security",
    version1_filename="ECOS_9.3.6.0_Release_Notes_RevB",
    version2_filename="ECOS_9.3.7.0_Release_Notes_RevB"
)
```

---

### Tool 6: `get_available_versions` (Phase 2)
**Purpose**: Discover all available release note versions in the system

**Parameters**:
- `product` (string, optional): Filter by product name (e.g., "ECOS", "Orchestrator")
- `collection_name` (string, optional): Default "content"
- `limit` (integer, optional): Max results (default: 100, range: 1-1000)

**Example**:
```python
get_available_versions(
    product="ECOS"
)
# Returns organized list of all ECOS versions

get_available_versions()
# Returns all products and versions
```

**Implementation**:
- Uses existing `/search/filenames` endpoint
- Parses metadata.filename to extract product/version
- No new API endpoint required

---

## 🚀 Getting Started

### Phase 1: API Testing (Current)

Before implementing the MCP server, we test all API endpoints:

1. **Read the testing guide**:
   ```bash
   cat API_TESTING_GUIDE.md
   ```

2. **Run test curl commands**:
   ```bash
   # Example: Test filename search
   curl -X POST "http://localhost:8001/search/filenames" \
     -H "Content-Type: application/json" \
     -d '{"query": "ecos 9.3", "limit": 5, "use_production": true}' \
     | jq '.' > test_results/tool1_test1.json
   ```

3. **Analyze responses**:
   - Document actual response structure
   - Identify redundant data
   - Plan sanitization strategy

4. **Design tools based on reality**:
   - No assumptions
   - No guesswork
   - Only verified behavior

### Phase 2: Implementation (Next)

Once API testing is complete:

1. Install dependencies
2. Implement MCP server with FastMCP
3. Create tool handlers
4. Add response sanitization
5. Test with Claude Desktop
6. Deploy with Docker

---

## 📚 Documentation

- **[DESIGN.md](./DESIGN.md)** - Comprehensive design document
  - Project overview and objectives
  - Architecture and data flow
  - Detailed tool specifications
  - Implementation plan (3 phases)
  - Testing strategy
  - Future enhancements

- **[API_TESTING_GUIDE.md](./API_TESTING_GUIDE.md)** - Testing methodology
  - Test-driven tool design process
  - Curl commands for each tool
  - Response analysis templates
  - Sanitization strategies
  - Documentation templates

---

## 🎯 Design Principles

### 1. Test-Driven Design
**Always test API endpoints with curl before implementing tools**

### 2. Observe Reality
**Base tool schemas on actual API responses, not assumptions**

### 3. No Guesswork
**Verify every field, data type, and structure**

### 4. Sanitize Outputs
**Remove redundant data, optimize for LLM consumption**

### 5. LLM-Friendly
**Design for token efficiency and parsing ease**

---

## 🔄 Development Workflow

```
1. Test API Endpoint
   ↓
2. Save Response
   ↓
3. Analyze Structure
   ↓
4. Document Findings
   ↓
5. Design Tool
   ↓
6. Implement Tool
   ↓
7. Test with LLM
   ↓
8. Refine & Document
```

---

## 📊 Current Status

### ✅ Completed
- [x] Project structure created
- [x] Design document written
- [x] Testing guide created
- [x] Memory saved for design principles

### 🚧 In Progress
- [ ] API endpoint testing
- [ ] Response documentation
- [ ] Tool implementation

### 📅 Planned
- [ ] Docker deployment
- [ ] User documentation
- [ ] TOON format integration (Phase 2)
- [ ] SSE transport (Phase 2)

---

## 🤝 Contributing

### Before Implementing a Tool

1. Read `API_TESTING_GUIDE.md`
2. Run all test curl commands for that tool
3. Save responses to `test_results/`
4. Document actual response structure
5. Design sanitization strategy
6. Get review before coding

### Code Style

- Follow PEP 8 for Python
- Add type hints
- Write docstrings
- Include examples
- Add error handling

---

## 📝 Notes

### Why JSON First, TOON Later?

**Phase 1 (Current)**: Use sanitized JSON
- Simpler to implement
- Easier to debug
- Standard format
- Good baseline

**Phase 2 (Future)**: Migrate to TOON
- 50% token reduction
- Better LLM comprehension
- Production optimization
- Cost savings

### Why No New API Endpoints?

We use existing FastAPI endpoints to:
- Minimize changes to production API
- Reduce testing overhead
- Maintain backward compatibility
- Simplify deployment

---

## 🚀 Quick Start

### Choose Your Deployment Method:

1. **uvx** (Recommended) - Like npx for Python
2. **FastMCP CLI** - Direct Python execution  
3. **Docker** - Isolated container

**See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup instructions!**

### 30-Second Setup (uvx):

```bash
# 1. Clone repo
git clone https://github.com/Crypto-Gi/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api/mcp-server

# 2. Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Configure
cp .env.example .env
# Edit .env with your API_URL

# 4. Add to Windsurf/Claude Desktop mcp_config.json
# Use: /path/to/qdrant-semantic-search-api/mcp-server/server.py
# (See DEPLOYMENT.md for full config)

# 5. Restart your AI assistant
```

---

## 📁 Files

### Core Files
- `server.py` - Main MCP server with 5 tools
- `config.py` - Configuration management
- `requirements.txt` - Python dependencies
- `.env.example` - Configuration template

### Deployment Files
- `Dockerfile` - Docker image definition
- `docker-compose.yml` - Docker orchestration

### Documentation
- `INSTALL.md` - **Installation guide for Windsurf**
- `TOOL_USAGE.md` - **Tool usage guide for LLMs**
- `DEPLOYMENT.md` - Deployment options and configuration
- `DESIGN.md` - Architecture and design details
- `README.md` - This file

---

## 🔗 Related Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - **Start here for setup!**
- [DESIGN.md](DESIGN.md) - Architecture and design
- [API Test Results](test_results/) - API testing documentation
- [FastAPI Server](../app/main.py) - Backend API
- [API Documentation](http://localhost:8001/docs) - Interactive API docs
- [FastMCP Documentation](https://github.com/jlowin/fastmcp) - MCP framework
- [MCP Protocol](https://modelcontextprotocol.io) - Protocol specification

---

## 📧 Support

- **Setup Issues**: See [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
- **Design Questions**: Check [DESIGN.md](DESIGN.md)
- **API Issues**: See [test_results/](test_results/) for API testing docs

---

**Last Updated**: November 12, 2025  
**Status**: ✅ Production Ready - All 3 deployment options available!
