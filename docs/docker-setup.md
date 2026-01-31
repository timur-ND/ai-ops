# Docker Setup for MCP Servers

This guide explains how to run MCP servers using Docker containers.

## Prerequisites

- Docker installed and running
- Docker Compose (optional, but recommended)
- Access to Grafana and VictoriaLogs instances

## Quick Start with Docker Compose

### 1. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with your credentials
nano .env
```

Example `.env` file:
```bash
GRAFANA_URL=https://grafana.pud.ink
GRAFANA_TOKEN=glsa_your_grafana_token_here

VICTORIALOGS_URL=https://victorialogs.pud.ink
VICTORIALOGS_TOKEN=your_victorialogs_token_here
VICTORIALOGS_ACCOUNT_ID=0
```

### 2. Start MCP Servers

```bash
# Start all MCP servers
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Stop MCP Servers

```bash
# Stop all servers
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Manual Docker Run

### Grafana MCP Server

```bash
docker run --rm -i \
  --network host \
  -e GRAFANA_URL=https://grafana.pud.ink \
  -e GRAFANA_TOKEN=glsa_your_token_here \
  ghcr.io/grafana/mcp-grafana:latest
```

### VictoriaLogs MCP Server

```bash
docker run --rm -i \
  --network host \
  -e VICTORIALOGS_ADDR=https://victorialogs.pud.ink \
  -e VICTORIALOGS_ACCOUNT_ID=0 \
  -e VICTORIALOGS_TOKEN=your_token_here \
  ghcr.io/victoriametrics-community/mcp-victorialogs:latest
```

## Integration with AI Tools

### VS Code

Create `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "grafana": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "GRAFANA_URL=${env:GRAFANA_URL}",
        "-e",
        "GRAFANA_TOKEN=${env:GRAFANA_TOKEN}",
        "ghcr.io/grafana/mcp-grafana:latest"
      ]
    },
    "victorialogs": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "VICTORIALOGS_ADDR=${env:VICTORIALOGS_URL}",
        "-e",
        "VICTORIALOGS_ACCOUNT_ID=${env:VICTORIALOGS_ACCOUNT_ID}",
        "-e",
        "VICTORIALOGS_TOKEN=${env:VICTORIALOGS_TOKEN}",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
      ]
    }
  }
}
```

Load environment variables in VS Code:
```bash
# Add to ~/.zshrc or ~/.bashrc
export GRAFANA_URL=https://grafana.pud.ink
export GRAFANA_TOKEN=glsa_your_token_here
export VICTORIALOGS_URL=https://victorialogs.pud.ink
export VICTORIALOGS_TOKEN=your_token_here
export VICTORIALOGS_ACCOUNT_ID=0
```

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "grafana": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "GRAFANA_URL=https://grafana.pud.ink",
        "-e",
        "GRAFANA_TOKEN=glsa_your_token_here",
        "ghcr.io/grafana/mcp-grafana:latest"
      ]
    },
    "victorialogs": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network",
        "host",
        "-e",
        "VICTORIALOGS_ADDR=https://victorialogs.pud.ink",
        "-e",
        "VICTORIALOGS_ACCOUNT_ID=0",
        "-e",
        "VICTORIALOGS_TOKEN=your_token_here",
        "ghcr.io/victoriametrics-community/mcp-victorialogs:latest"
      ]
    }
  }
}
```

## Updating Images

```bash
# Pull latest images
docker pull ghcr.io/grafana/mcp-grafana:latest
docker pull ghcr.io/victoriametrics-community/mcp-victorialogs:latest

# Or with docker-compose
docker-compose pull

# Restart services to use new images
docker-compose down && docker-compose up -d
```

## Troubleshooting

### Container Won't Start

```bash
# Check Docker is running
docker ps

# Check logs
docker logs mcp-grafana
docker logs mcp-victorialogs

# Check environment variables
docker inspect mcp-grafana | grep -A 10 Env
```

### Network Issues

```bash
# Using --network host allows containers to access localhost services
# If you need custom network:
docker network create mcp-network

# Then in docker-compose.yml:
networks:
  default:
    external:
      name: mcp-network
```

### Permission Errors

```bash
# If Docker socket permission denied
sudo chmod 666 /var/run/docker.sock

# Or add user to docker group
sudo usermod -aG docker $USER
# Then logout and login again
```

### Testing Connectivity

```bash
# Test Grafana connection from within container
docker run --rm -it --network host alpine sh
apk add curl
curl -H "Authorization: Bearer YOUR_TOKEN" https://grafana.pud.ink/api/health

# Test VictoriaLogs
curl https://victorialogs.pud.ink/health
```

## Advanced Configuration

### Using Docker Secrets

For production, use Docker secrets instead of environment variables:

```bash
# Create secrets
echo "glsa_your_token" | docker secret create grafana_token -
echo "victorialogs_token" | docker secret create victorialogs_token -

# Use in docker-compose.yml
services:
  mcp-grafana:
    secrets:
      - grafana_token
    environment:
      - GRAFANA_TOKEN=/run/secrets/grafana_token

secrets:
  grafana_token:
    external: true
```

### Resource Limits

Add to `docker-compose.yml`:

```yaml
services:
  mcp-grafana:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Health Checks

```yaml
services:
  mcp-grafana:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## References

- [Grafana MCP Server](https://github.com/grafana/mcp-grafana)
- [VictoriaLogs MCP Server](https://github.com/VictoriaMetrics-Community/mcp-victorialogs)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
