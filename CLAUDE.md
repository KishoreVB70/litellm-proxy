# CLAUDE.md - AI Assistant Guide for litellm-proxy

## Repository Overview

This repository contains a **LiteLLM Proxy** configuration for providing unified access to Anthropic's Claude models. LiteLLM is an open-source proxy that provides a unified interface for multiple AI model providers, standardizing API calls across different LLM services.

**Repository Owner**: KishoreVB70
**Purpose**: Deploy a containerized LiteLLM proxy that exposes Claude models through a unified API interface
**Primary Use Case**: Simplify access to multiple Claude model versions through a single endpoint

## Repository Structure

```
litellm-proxy/
├── .gitignore           # Git ignore patterns (excludes .env files)
├── Dockerfile           # Container image definition
├── config.yaml          # LiteLLM proxy configuration
└── CLAUDE.md            # This file - AI assistant guide
```

### File Descriptions

#### `Dockerfile`
- **Base Image**: `ghcr.io/berriai/litellm:main-stable`
- **Working Directory**: `/app`
- **Exposed Port**: 4000/tcp
- **Configuration**: Copies `config.yaml` into the container
- **Entry Point**: Runs LiteLLM with `--port 4000 --config config.yaml`

#### `config.yaml`
The primary configuration file that defines:
- **Model List**: Configured Claude models with their LiteLLM parameters
- **General Settings**: Master key for authentication
- **LiteLLM Settings**: Request timeout, logging preferences

## Current Configuration

### Configured Models

1. **claude-sonnet-4-5-20250929**
   - Provider: Anthropic
   - API Key Source: Environment variable `ANTHROPIC_API_KEY`
   - Latest Claude Sonnet 4.5 model

2. **claude-sonnet-4-20250514**
   - Provider: Anthropic
   - API Key Source: Environment variable `ANTHROPIC_API_KEY`
   - Claude Sonnet 4 model

### Settings

- **Request Timeout**: 600 seconds (10 minutes)
- **Verbose Logging**: Disabled
- **JSON Logs**: Enabled
- **Authentication**: Requires `LITELLM_MASTER_KEY` environment variable

## Environment Variables

The following environment variables are **required** for operation:

### `ANTHROPIC_API_KEY`
- **Purpose**: Authenticate with Anthropic's API
- **Required**: Yes
- **Format**: `sk-ant-...` (Anthropic API key format)
- **Where to Get**: https://console.anthropic.com/

### `LITELLM_MASTER_KEY`
- **Purpose**: Secure the proxy endpoint
- **Required**: Yes
- **Format**: Any secure string (recommend UUID or similar)
- **Usage**: Include as `Authorization: Bearer <LITELLM_MASTER_KEY>` in API requests

## Development Workflow

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd litellm-proxy
   ```

2. **Create environment file**
   ```bash
   # Create .env file (already gitignored)
   cat > .env << EOF
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   LITELLM_MASTER_KEY=your-secure-master-key
   EOF
   ```

3. **Build the Docker image**
   ```bash
   docker build -t litellm-proxy:local .
   ```

4. **Run the container**
   ```bash
   docker run -p 4000:4000 \
     --env-file .env \
     litellm-proxy:local
   ```

5. **Test the proxy**
   ```bash
   curl http://localhost:4000/health

   # Make a chat completion request
   curl http://localhost:4000/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
     -d '{
       "model": "claude-sonnet-4-5-20250929",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'
   ```

### Git Workflow

**Main Branch**: `main` (implied from remote configuration)
**Feature Branches**: Follow pattern `claude/claude-md-<session-id>`
**Current Branch**: `claude/claude-md-mhyei7y2fotmtbtd-016YYgouk69ypLmqYD6NWp9w`

#### Committing Changes

```bash
# Stage changes
git add <files>

# Commit with descriptive message
git commit -m "feat: add new model configuration"
# or
git commit -m "fix: correct timeout value"
# or
git commit -m "refactor: update configuration structure"

# Push to remote
git push -u origin <branch-name>
```

**Commit Message Conventions**:
- `feat:` - New features or model additions
- `fix:` - Bug fixes or corrections
- `refactor:` - Code restructuring without behavior change
- `chore:` - Maintenance tasks (dependencies, gitignore, etc.)
- `docs:` - Documentation updates

## Common Modification Tasks

### Adding a New Model

To add a new Claude model to the configuration:

1. **Edit `config.yaml`**
   ```yaml
   model_list:
     # ... existing models ...
     - model_name: claude-opus-4-20250514
       litellm_params:
         model: anthropic/claude-opus-4-20250514
         api_key: os.environ/ANTHROPIC_API_KEY
   ```

2. **Rebuild and test**
   ```bash
   docker build -t litellm-proxy:local .
   docker run -p 4000:4000 --env-file .env litellm-proxy:local
   ```

### Adding a Different Provider

To add models from other providers (OpenAI, Cohere, etc.):

1. **Update `config.yaml`**
   ```yaml
   model_list:
     # ... existing models ...
     - model_name: gpt-4-turbo
       litellm_params:
         model: openai/gpt-4-turbo
         api_key: os.environ/OPENAI_API_KEY
   ```

2. **Update `.env`** with the new API key
   ```bash
   OPENAI_API_KEY=sk-...
   ```

### Modifying Timeout Settings

Edit `config.yaml`:

```yaml
litellm_settings:
  request_timeout: 900  # Change from 600 to 900 seconds
  set_verbose: False
  json_logs: true
```

### Enabling Verbose Logging

For debugging, enable verbose logging:

```yaml
litellm_settings:
  request_timeout: 600
  set_verbose: True  # Change to True
  json_logs: true
```

## Deployment

### Docker Deployment

**Standard deployment**:
```bash
docker build -t litellm-proxy:latest .
docker run -d \
  --name litellm-proxy \
  -p 4000:4000 \
  -e ANTHROPIC_API_KEY=<your-key> \
  -e LITELLM_MASTER_KEY=<your-master-key> \
  litellm-proxy:latest
```

### Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  litellm-proxy:
    build: .
    ports:
      - "4000:4000"
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Then deploy:
```bash
docker-compose up -d
```

### Production Considerations

1. **Use Secrets Management**: Don't hardcode API keys
2. **Enable HTTPS**: Use a reverse proxy (nginx, Traefik, Caddy)
3. **Monitor Logs**: Enable JSON logs for structured logging
4. **Set Resource Limits**: Configure Docker memory/CPU limits
5. **Health Checks**: Monitor the `/health` endpoint
6. **Rate Limiting**: Consider implementing rate limiting at proxy level

## Key Conventions for AI Assistants

### When Modifying Configuration

1. **Always validate YAML syntax** before committing
2. **Test configuration** by building and running the Docker image
3. **Document changes** in commit messages
4. **Never commit secrets** - ensure `.env` is in `.gitignore`
5. **Preserve environment variable references** - use `os.environ/VAR_NAME` format

### When Adding Models

1. **Follow naming conventions**: Use official model names from provider
2. **Match provider prefix**: `anthropic/`, `openai/`, `cohere/`, etc.
3. **Use environment variables** for API keys
4. **Test model availability** before committing

### When Updating Dockerfile

1. **Don't change base image** without thorough testing
2. **Keep WORKDIR at `/app`** for consistency
3. **Ensure config file is copied** correctly
4. **Maintain port exposure** at 4000/tcp
5. **Test build locally** before pushing

### Code Quality Standards

1. **YAML Formatting**:
   - Use 2-space indentation
   - No tabs, spaces only
   - Clear key-value structure

2. **Documentation**:
   - Update CLAUDE.md when making structural changes
   - Add comments to config.yaml for complex settings

3. **Security**:
   - Never commit API keys or secrets
   - Always use environment variables for sensitive data
   - Keep .env in .gitignore

## Testing

### Manual Testing Checklist

- [ ] Docker image builds successfully
- [ ] Container starts without errors
- [ ] Health endpoint responds: `curl http://localhost:4000/health`
- [ ] Models endpoint returns configured models: `curl http://localhost:4000/models`
- [ ] Chat completion works for each configured model
- [ ] Authentication requires valid master key
- [ ] Invalid requests return appropriate errors

### Test Commands

```bash
# Health check
curl http://localhost:4000/health

# List models
curl http://localhost:4000/models \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"

# Test chat completion
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "messages": [{"role": "user", "content": "Say hello!"}],
    "max_tokens": 100
  }'
```

## Troubleshooting

### Common Issues

**Container won't start**:
- Check environment variables are set
- Verify config.yaml syntax
- Check Docker logs: `docker logs <container-id>`

**Authentication errors**:
- Verify `LITELLM_MASTER_KEY` is set correctly
- Ensure Authorization header format: `Bearer <key>`

**Model not found**:
- Check model name matches configuration
- Verify model is listed in config.yaml
- Confirm API key has access to the model

**Timeout errors**:
- Increase `request_timeout` in config.yaml
- Check network connectivity to provider APIs

## Additional Resources

- **LiteLLM Documentation**: https://docs.litellm.ai/
- **LiteLLM GitHub**: https://github.com/BerriAI/litellm
- **Anthropic API Documentation**: https://docs.anthropic.com/
- **Docker Documentation**: https://docs.docker.com/

## Quick Reference

### File Locations
- Configuration: `/home/user/litellm-proxy/config.yaml`
- Dockerfile: `/home/user/litellm-proxy/Dockerfile`
- Git ignore: `/home/user/litellm-proxy/.gitignore`

### Important Endpoints
- Health: `http://localhost:4000/health`
- Models: `http://localhost:4000/models`
- Chat: `http://localhost:4000/v1/chat/completions`
- Completions: `http://localhost:4000/v1/completions`

### Port Configuration
- Container Port: 4000/tcp
- Host Port: 4000 (default, configurable)

---

**Last Updated**: 2025-11-14
**Maintained By**: AI Assistant
**Version**: 1.0.0
