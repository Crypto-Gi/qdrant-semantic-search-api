# Qdrant RAG MCP Server - Installation Guide

Complete installation instructions for Windsurf IDE with three deployment options.

---

## 📋 Prerequisites

Before installing, ensure you have:

1. **Windsurf IDE** installed
2. **Qdrant RAG API** running (default: `http://localhost:8001`)
3. One of the following (depending on deployment method):
   - **uv** (for uvx method) - Recommended
   - **Python 3.11+** and **pip** (for fastmcp method)
   - **Docker** (for Docker method)

---

## 🚀 Quick Start (Recommended: uvx)

### Step 1: Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Step 2: Clone Repository

```bash
git clone https://github.com/Crypto-Gi/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api/mcp-server
```

### Step 3: Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

**Minimum required in `.env`**:
```bash
API_URL=http://localhost:8001
QDRANT_COLLECTION=content
DEFAULT_LIMIT=1
DEFAULT_CONTEXT_WINDOW=5
```

### Step 4: Add to Windsurf

Open Windsurf settings and edit `mcp_config.json`:

**Location**: 
- Linux/Mac: `~/.codeium/windsurf/mcp_config.json`
- Windows: `%USERPROFILE%\.codeium\windsurf\mcp_config.json`

**Add this configuration**:

```json
{
  "mcpServers": {
    "qdrant-rag": {
      "command": "uvx",
      "args": [
        "--from",
        "fastmcp",
        "fastmcp",
        "run",
        "/FULL/PATH/TO/qdrant-semantic-search-api/mcp-server/server.py"
      ],
      "disabled": false,
      "env": {
        "API_URL": "http://localhost:8001",
        "QDRANT_COLLECTION": "content",
        "EMBEDDING_MODEL": "bge-m3",
        "DEFAULT_LIMIT": "1",
        "DEFAULT_CONTEXT_WINDOW": "5",
        "USE_PRODUCTION": "true"
      }
    }
  }
}
```

**Replace `/FULL/PATH/TO/`** with your actual clone location:
- Linux/Mac: `/home/username/qdrant-semantic-search-api/mcp-server/server.py`
- Windows: `C:\\Users\\username\\qdrant-semantic-search-api\\mcp-server\\server.py`

### Step 5: Restart Windsurf

Close and reopen Windsurf IDE.

### Step 6: Verify Installation

In Windsurf, ask:
```
What MCP tools are available?
```

You should see 5 Qdrant RAG tools listed.

---

## 🐍 Option 2: FastMCP CLI

### Step 1: Install Dependencies

```bash
pip install fastmcp httpx python-dotenv
```

### Step 2: Clone Repository

```bash
git clone https://github.com/Crypto-Gi/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api/mcp-server
```

### Step 3: Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

### Step 4: Add to Windsurf

Edit `mcp_config.json`:

```json
{
  "mcpServers": {
    "qdrant-rag": {
      "command": "fastmcp",
      "args": [
        "run",
        "/FULL/PATH/TO/qdrant-semantic-search-api/mcp-server/server.py"
      ],
      "disabled": false,
      "env": {
        "API_URL": "http://localhost:8001",
        "QDRANT_COLLECTION": "content",
        "EMBEDDING_MODEL": "bge-m3",
        "DEFAULT_LIMIT": "1",
        "DEFAULT_CONTEXT_WINDOW": "5"
      }
    }
  }
}
```

### Step 5: Restart Windsurf

---

## 🐳 Option 3: Docker

### Step 1: Clone Repository

```bash
git clone https://github.com/Crypto-Gi/qdrant-semantic-search-api.git
cd qdrant-semantic-search-api/mcp-server
```

### Step 2: Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

**Important for Docker**: Set API_URL to use host networking:
```bash
API_URL=http://host.docker.internal:8001  # Mac/Windows
# OR
API_URL=http://172.17.0.1:8001  # Linux
```

### Step 3: Build Docker Image

```bash
docker build -t qdrant-mcp-server .
```

### Step 4: Add to Windsurf

Edit `mcp_config.json`:

```json
{
  "mcpServers": {
    "qdrant-rag": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "--env-file",
        "/FULL/PATH/TO/qdrant-semantic-search-api/mcp-server/.env",
        "qdrant-mcp-server"
      ],
      "disabled": false
    }
  }
}
```

### Step 5: Restart Windsurf

---

## 🔧 Configuration Reference

### Environment Variables

All configuration is done via `.env` file or `mcp_config.json` env section.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `API_URL` | ✅ Yes | `http://localhost:8001` | Your Qdrant RAG API endpoint |
| `API_KEY` | ❌ No | - | Optional API authentication |
| `QDRANT_COLLECTION` | ✅ Yes | `content` | Qdrant collection name |
| `QDRANT_HOST` | ❌ No | - | Override Qdrant host (optional) |
| `QDRANT_API_KEY` | ❌ No | - | Qdrant Cloud API key (optional) |
| `OLLAMA_URL` | ❌ No | - | Override Ollama URL (optional) |
| `OLLAMA_API_KEY` | ❌ No | - | Ollama Cloud API key (optional) |
| `EMBEDDING_MODEL` | ✅ Yes | `bge-m3` | Embedding model name |
| `EMBEDDING_DIMENSIONS` | ✅ Yes | `1024` | Embedding vector dimensions |
| `DEFAULT_LIMIT` | ✅ Yes | `1` | Default results per query |
| `DEFAULT_CONTEXT_WINDOW` | ✅ Yes | `5` | Default pages before/after match |
| `USE_PRODUCTION` | ✅ Yes | `true` | Use production Qdrant instance |

### Priority Hierarchy

```
LLM Override (in tool call)
    ↓
mcp_config.json env section
    ↓
.env file
    ↓
Hardcoded defaults
```

---

## 🧪 Testing Your Installation

### Test 1: Check Server Status

In Windsurf, ask:
```
What MCP servers are running?
```

Expected: `qdrant-rag` should be listed and active.

### Test 2: List Available Tools

Ask:
```
What tools does the qdrant-rag MCP server provide?
```

Expected: 5 tools listed:
1. `search_filenames_fuzzy`
2. `search_with_filename_filter`
3. `search_multi_query_with_filter`
4. `search_across_multiple_files`
5. `compare_versions`

### Test 3: Run a Simple Search

Ask:
```
Use qdrant-rag to search for files about "ECOS 9.3"
```

Expected: List of matching filenames.

### Test 4: Search Within a Document

Ask:
```
Search for "security vulnerabilities" in ECOS 9.3.6.0 release notes
```

Expected: Relevant passages with page context.

---

## 🐛 Troubleshooting

### Server Not Starting

**Symptom**: `qdrant-rag` not listed in MCP servers

**Solutions**:
1. Check Windsurf logs: `View > Output > MCP`
2. Verify path in `mcp_config.json` is absolute and correct
3. Ensure `uv`/`fastmcp`/`docker` is installed and in PATH
4. Restart Windsurf completely

### Tools Not Appearing

**Symptom**: Server running but no tools available

**Solutions**:
1. Check `server.py` syntax: `python server.py`
2. Verify dependencies: `pip list | grep fastmcp`
3. Check logs for import errors
4. Ensure `config.py` is in same directory as `server.py`

### Connection Errors

**Symptom**: "Connection refused" or "API unreachable"

**Solutions**:
1. Verify API is running: `curl http://localhost:8001/docs`
2. Check `API_URL` in config matches your API endpoint
3. For Docker: Use `host.docker.internal` (Mac/Win) or `172.17.0.1` (Linux)
4. Check firewall settings

### Authentication Errors

**Symptom**: "Unauthorized" or "403 Forbidden"

**Solutions**:
1. If API requires auth, set `API_KEY` in `.env`
2. Verify API key format: `Bearer <token>`
3. Check API key hasn't expired
4. Test API key with curl: `curl -H "Authorization: Bearer <key>" http://localhost:8001/docs`

### Empty Results

**Symptom**: Tools work but return no results

**Solutions**:
1. Verify `QDRANT_COLLECTION` matches your collection name
2. Check collection has data: Use Qdrant dashboard
3. Verify embedding model matches indexed data
4. Check `USE_PRODUCTION=true` if using production instance

---

## 📊 Complete Example Configuration

### Full `mcp_config.json` with All Options

```json
{
  "mcpServers": {
    "qdrant-rag": {
      "command": "uvx",
      "args": [
        "--from",
        "fastmcp",
        "fastmcp",
        "run",
        "/home/username/qdrant-semantic-search-api/mcp-server/server.py"
      ],
      "disabled": false,
      "disabledTools": [],
      "env": {
        "API_URL": "http://localhost:8001",
        "API_KEY": "",
        "QDRANT_COLLECTION": "content",
        "QDRANT_HOST": "",
        "QDRANT_API_KEY": "",
        "OLLAMA_URL": "",
        "OLLAMA_API_KEY": "",
        "EMBEDDING_MODEL": "bge-m3",
        "EMBEDDING_DIMENSIONS": "1024",
        "DEFAULT_LIMIT": "1",
        "DEFAULT_CONTEXT_WINDOW": "5",
        "USE_PRODUCTION": "true"
      }
    }
  }
}
```

### Minimal Configuration (Recommended)

```json
{
  "mcpServers": {
    "qdrant-rag": {
      "command": "uvx",
      "args": [
        "--from",
        "fastmcp",
        "fastmcp",
        "run",
        "/home/username/qdrant-semantic-search-api/mcp-server/server.py"
      ],
      "disabled": false,
      "env": {
        "API_URL": "http://localhost:8001",
        "QDRANT_COLLECTION": "content",
        "DEFAULT_LIMIT": "1",
        "DEFAULT_CONTEXT_WINDOW": "5"
      }
    }
  }
}
```

---

## 🔄 Updating

### Update to Latest Version

```bash
cd qdrant-semantic-search-api
git pull origin master

# If using Docker, rebuild:
cd mcp-server
docker build -t qdrant-mcp-server .

# Restart Windsurf
```

---

## 🆘 Getting Help

1. **Check logs**: Windsurf > View > Output > MCP
2. **Test API directly**: `curl http://localhost:8001/docs`
3. **Verify config**: Check `mcp_config.json` syntax
4. **Review docs**: See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed info
5. **GitHub Issues**: https://github.com/Crypto-Gi/qdrant-semantic-search-api/issues

---

## 📝 Next Steps

After installation:

1. Read [TOOL_USAGE.md](TOOL_USAGE.md) for tool usage instructions
2. Review [DEPLOYMENT.md](DEPLOYMENT.md) for advanced configuration
3. Check [README.md](README.md) for architecture overview
4. See [DESIGN.md](DESIGN.md) for technical details

---

**Installation Complete!** 🎉

Your Qdrant RAG MCP server is now ready to use in Windsurf.
