"""
Unit tests for embedding provider abstraction.

Tests the EmbeddingClient interface, factory, and both Ollama and Gemini implementations.
"""

import pytest
import os
from unittest.mock import Mock, patch, MagicMock
from app.embeddings import (
    EmbeddingClient,
    EmbeddingProviderFactory,
    OllamaEmbeddingClient,
    GeminiEmbeddingClient,
)
from app.embeddings.base import EmbeddingProviderError


class TestEmbeddingProviderFactory:
    """Test the embedding provider factory."""

    def test_factory_creates_ollama_by_default(self, monkeypatch):
        """Factory should create Ollama client when EMBEDDING_PROVIDER is unset or 'ollama'."""
        monkeypatch.setenv("EMBEDDING_PROVIDER", "ollama")
        monkeypatch.setenv("OLLAMA_HOST", "http://localhost:11434")
        monkeypatch.setenv("DEFAULT_EMBEDDING_MODEL", "test-model")

        client = EmbeddingProviderFactory.from_env()
        assert isinstance(client, OllamaEmbeddingClient)

    def test_factory_creates_gemini_when_configured(self, monkeypatch):
        """Factory should create Gemini client when EMBEDDING_PROVIDER=gemini."""
        monkeypatch.setenv("EMBEDDING_PROVIDER", "gemini")
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("GEMINI_EMBEDDING_MODEL", "gemini-embedding-001")
        monkeypatch.setenv("GEMINI_EMBEDDING_TASK_TYPE", "RETRIEVAL_QUERY")
        monkeypatch.setenv("GEMINI_EMBEDDING_DIM", "768")

        client = EmbeddingProviderFactory.from_env()
        assert isinstance(client, GeminiEmbeddingClient)

    def test_factory_raises_on_unknown_provider(self, monkeypatch):
        """Factory should raise ValueError for unknown provider."""
        monkeypatch.setenv("EMBEDDING_PROVIDER", "unknown_provider")

        with pytest.raises(ValueError, match="Unknown EMBEDDING_PROVIDER"):
            EmbeddingProviderFactory.from_env()

    def test_factory_raises_on_missing_ollama_config(self, monkeypatch):
        """Factory should raise ValueError if Ollama config is missing."""
        monkeypatch.setenv("EMBEDDING_PROVIDER", "ollama")
        monkeypatch.delenv("OLLAMA_HOST", raising=False)
        monkeypatch.delenv("DEFAULT_EMBEDDING_MODEL", raising=False)

        with pytest.raises(ValueError, match="OLLAMA_HOST is required"):
            EmbeddingProviderFactory.from_env()

    def test_factory_raises_on_missing_gemini_api_key(self, monkeypatch):
        """Factory should raise ValueError if Gemini API key is missing."""
        monkeypatch.setenv("EMBEDDING_PROVIDER", "gemini")
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)

        with pytest.raises(ValueError, match="GEMINI_API_KEY is required"):
            EmbeddingProviderFactory.from_env()


class TestOllamaEmbeddingClient:
    """Test the Ollama embedding client."""

    @patch("app.embeddings.ollama_client.OllamaClient")
    def test_embed_one_success(self, mock_ollama_class):
        """embed_one should return embedding vector from Ollama."""
        mock_client = Mock()
        mock_client.embeddings.return_value = {"embedding": [0.1, 0.2, 0.3]}
        mock_ollama_class.return_value = mock_client

        client = OllamaEmbeddingClient(host="http://localhost:11434", model="test-model")
        result = client.embed_one("test query")

        assert result == [0.1, 0.2, 0.3]
        mock_client.embeddings.assert_called_once_with(model="test-model", prompt="test query")

    @patch("app.embeddings.ollama_client.OllamaClient")
    def test_embed_multiple_success(self, mock_ollama_class):
        """embed should return list of embedding vectors."""
        mock_client = Mock()
        mock_client.embeddings.side_effect = [
            {"embedding": [0.1, 0.2]},
            {"embedding": [0.3, 0.4]},
        ]
        mock_ollama_class.return_value = mock_client

        client = OllamaEmbeddingClient(host="http://localhost:11434", model="test-model")
        result = client.embed(["query1", "query2"])

        assert result == [[0.1, 0.2], [0.3, 0.4]]
        assert mock_client.embeddings.call_count == 2

    @patch("app.embeddings.ollama_client.OllamaClient")
    def test_embed_one_raises_on_empty_text(self, mock_ollama_class):
        """embed_one should raise ValueError for empty text."""
        client = OllamaEmbeddingClient(host="http://localhost:11434", model="test-model")

        with pytest.raises(ValueError, match="text cannot be empty"):
            client.embed_one("")

    @patch("app.embeddings.ollama_client.OllamaClient")
    def test_embed_raises_on_empty_list(self, mock_ollama_class):
        """embed should raise ValueError for empty list."""
        client = OllamaEmbeddingClient(host="http://localhost:11434", model="test-model")

        with pytest.raises(ValueError, match="texts list cannot be empty"):
            client.embed([])

    @patch("app.embeddings.ollama_client.OllamaClient")
    def test_embed_one_raises_on_ollama_error(self, mock_ollama_class):
        """embed_one should raise EmbeddingProviderError on Ollama failure."""
        mock_client = Mock()
        mock_client.embeddings.side_effect = Exception("Ollama connection failed")
        mock_ollama_class.return_value = mock_client

        client = OllamaEmbeddingClient(host="http://localhost:11434", model="test-model")

        with pytest.raises(EmbeddingProviderError, match="Ollama embedding failed"):
            client.embed_one("test")


class TestGeminiEmbeddingClient:
    """Test the Gemini embedding client."""

    def test_init_raises_on_empty_api_key(self):
        """__init__ should raise ValueError if API key is empty."""
        with pytest.raises(ValueError, match="api_key cannot be empty"):
            GeminiEmbeddingClient(api_key="")

    def test_init_warns_on_non_recommended_dimension(self, caplog):
        """__init__ should log warning for non-recommended dimensions."""
        client = GeminiEmbeddingClient(
            api_key="test-key",
            output_dimensionality=999,  # Not recommended
        )
        assert "not a recommended value" in caplog.text

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_one_success(self, mock_post):
        """embed_one should return embedding vector from Gemini."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "embedding": {"values": [0.1, 0.2, 0.3]}
        }
        mock_post.return_value = mock_response

        client = GeminiEmbeddingClient(api_key="test-key", output_dimensionality=768)
        result = client.embed_one("test query")

        assert result == [0.1, 0.2, 0.3]
        
        # Verify API call
        call_args = mock_post.call_args
        assert "gemini-embedding-001:embedContent" in call_args[0][0]
        assert call_args[1]["headers"]["x-goog-api-key"] == "test-key"
        assert call_args[1]["json"]["content"]["parts"][0]["text"] == "test query"
        assert call_args[1]["json"]["task_type"] == "RETRIEVAL_QUERY"
        assert call_args[1]["json"]["output_dimensionality"] == 768

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_multiple_success(self, mock_post):
        """embed should return list of embedding vectors from Gemini batch API."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "embeddings": [
                {"values": [0.1, 0.2]},
                {"values": [0.3, 0.4]},
            ]
        }
        mock_post.return_value = mock_response

        client = GeminiEmbeddingClient(api_key="test-key", output_dimensionality=768)
        result = client.embed(["query1", "query2"])

        assert result == [[0.1, 0.2], [0.3, 0.4]]
        
        # Verify batch API call
        call_args = mock_post.call_args
        assert "batchEmbedContents" in call_args[0][0]
        assert len(call_args[1]["json"]["requests"]) == 2

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_one_raises_on_api_error(self, mock_post):
        """embed_one should raise EmbeddingProviderError on non-200 response."""
        mock_response = Mock()
        mock_response.status_code = 403
        mock_response.json.return_value = {"error": {"message": "Invalid API key"}}
        mock_post.return_value = mock_response

        client = GeminiEmbeddingClient(api_key="test-key")

        with pytest.raises(EmbeddingProviderError, match="Gemini API returned 403"):
            client.embed_one("test")

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_one_raises_on_timeout(self, mock_post):
        """embed_one should raise EmbeddingProviderError on timeout."""
        import requests
        mock_post.side_effect = requests.exceptions.Timeout("Request timed out")

        client = GeminiEmbeddingClient(api_key="test-key", timeout=1)

        with pytest.raises(EmbeddingProviderError, match="timed out"):
            client.embed_one("test")

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_raises_on_empty_list(self, mock_post):
        """embed should raise ValueError for empty list."""
        client = GeminiEmbeddingClient(api_key="test-key")

        with pytest.raises(ValueError, match="texts list cannot be empty"):
            client.embed([])

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_one_raises_on_empty_text(self, mock_post):
        """embed_one should raise ValueError for empty text."""
        client = GeminiEmbeddingClient(api_key="test-key")

        with pytest.raises(ValueError, match="text cannot be empty"):
            client.embed_one("")

    @patch("app.embeddings.gemini_client.requests.post")
    def test_embed_raises_on_mismatched_response_count(self, mock_post):
        """embed should raise EmbeddingProviderError if response count doesn't match input."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "embeddings": [{"values": [0.1, 0.2]}]  # Only 1 embedding
        }
        mock_post.return_value = mock_response

        client = GeminiEmbeddingClient(api_key="test-key")

        with pytest.raises(EmbeddingProviderError, match="returned 1 embeddings for 2 texts"):
            client.embed(["query1", "query2"])  # 2 queries

    @patch("app.embeddings.gemini_client.requests.post")
    def test_error_sanitization(self, mock_post):
        """_sanitize_error should extract error message from Gemini response."""
        mock_response = Mock()
        mock_response.status_code = 400
        mock_response.json.return_value = {
            "error": {"message": "Invalid request format"}
        }
        mock_response.text = "Full error text"
        mock_post.return_value = mock_response

        client = GeminiEmbeddingClient(api_key="test-key")

        with pytest.raises(EmbeddingProviderError, match="Invalid request format"):
            client.embed_one("test")
