# Ollama Server Gateway

> A secure and effortless bridge connecting Cloud Notebooks with locally hosted Ollama models

[![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)

## 🎯 Overview

Ollama Server Gateway solves the fundamental challenges of GenAI learning and experimentation by creating a secure, lightweight connection between cloud notebooks and local Ollama models. No more expensive cloud LLMs, no more slow temporary Colab setups—just fast, reliable, and private GenAI processing.

### Key Features

- 🔐 **Secure Tunneling** - Encrypted SSH tunnels for safe remote access
- 🚀 **Instant Discovery** - Automatic service registration and discovery
- 🔒 **Data Privacy** - All processing happens locally on your machine
- ⚡ **Zero Configuration** - Single command setup and deployment
- 🎓 **Education-First** - Perfect for students and learners
- 💰 **Cost-Free** - No cloud API costs or compute fees

## 📋 Prerequisites

Before running the gateway, ensure you have:

- **Ollama** - [Download and install](https://ollama.com/download) on your local machine
- **SSH Client** - Pre-installed on most Linux/macOS systems
- **curl** - For HTTP requests and API interactions
- **Bash 4.0+** - Standard on most Unix-like systems

## 🚀 Quick Start

### 1. Create a Discovery Endpoint

First, create a JSON endpoint for service discovery using one of these services:

- [npoint.io](https://www.npoint.io/) - Simple JSON storage
- [jsonbin.io](https://jsonbin.io/) - JSON storage with API

Initialize your endpoint with:

```json
{
  "url": ""
}
```

### 2. Download the Script

```bash
# Download the gateway script
wget https://github.com/tusman21/ollama-server-gateway/blob/main/ollama-gateway-connect.sh

# Make it executable
chmod +x ollama-gateway-connect.sh
```

### 3. Start the Gateway

```bash
./ollama-gateway-connect.sh https://api.npoint.io/your-endpoint-id
```

The script will:

- ✅ Check if Ollama is running (starts it if needed)
- ✅ Create a secure SSH tunnel via localhost.run
- ✅ Register the public URL to your discovery endpoint
- ✅ Keep the connection alive

### 4. Example Connection from Google Colab

In your Colab notebook:

```python
import ollama
import requests
import pandas as pd

# PASTE YOUR URL HERE
OLLAMA_HOST = ""
DISCOVERY_URL = "https://api.npoint.io/bd3f03580492bf829ab5"

def discover_ollama_gateway(url):
  response = requests.get(url, timeout=10)
  response.raise_for_status()
  return response.json()

try:
    data = discover_ollama_gateway(DISCOVERY_URL)
    if data['url'] != "initializing":
      OLLAMA_HOST = data['url']
      print(f"Discovered local Ollama at: {OLLAMA_HOST}")
except Exception as e:
    print(f"Error connecting to discovery service: {e}")

client = ollama.Client(host=OLLAMA_HOST)
client.list()
```

## 🛠️ Usage

### Basic Syntax

```bash
./ollama-gateway-connect.sh <discovery_url>
```

### Arguments

| Argument        | Description                               | Required |
| --------------- | ----------------------------------------- | -------- |
| `discovery_url` | Your npoint.io or jsonbin.io endpoint URL | Yes      |

### Example

```bash
./ollama-gateway-connect.sh https://api.npoint.io/abc123def456
```

## 📊 How It Works

1. **Service Detection** - Script checks if Ollama is running locally
2. **Tunnel Creation** - Establishes secure SSH tunnel via localhost.run
3. **URL Broadcasting** - Registers public URL to discovery endpoint
4. **Client Discovery** - Colab notebooks fetch URL from discovery service
5. **Secure Connection** - Encrypted traffic flows through the tunnel

## 🔧 Advanced Configuration

### Custom Ollama Port

If Ollama runs on a different port, modify the script:

```bash
# Change port 11434 to your custom port
ssh -R 80:localhost:YOUR_PORT nokey@localhost.run
```

### Environment Variables

The script automatically sets:

```bash
export OLLAMA_HOST='0.0.0.0'
```

This allows Ollama to accept connections from the tunnel.

## ⚠️ Troubleshooting

### Ollama Won't Start

```bash
# Manually start Ollama
export OLLAMA_HOST='0.0.0.0'
ollama serve
```

Then run the gateway script in a new terminal.

### Tunnel Connection Failed

- Check your internet connection
- Verify SSH is installed: `ssh -V`
- Try restarting the script

### Discovery Service Not Updating

- Verify your endpoint URL is correct
- Check endpoint permissions (must allow POST requests)
- Test with curl manually:
  ```bash
  curl -X POST -H "Content-Type: application/json" \
       -d '{"url":"test"}' YOUR_ENDPOINT_URL
  ```

### Port Already in Use

If port 11434 is busy:

```bash
# Find process using the port
lsof -i :11434

# Kill the process if needed
kill -9 <PID>
```

## 🔒 Security Considerations

- **Tunnel Encryption** - All traffic is encrypted via SSH
- **Local Processing** - Data never leaves your machine
- **Temporary URLs** - localhost.run URLs expire after tunnel closes
- **No Authentication** - Anyone with the URL can access your Ollama instance
  - Only share URLs with trusted parties
  - Consider implementing additional authentication in production
  - Keep the terminal window visible to monitor access

## 🎓 Educational Use Cases

Perfect for:

- **AI/ML Courses** - Students connect to instructor-hosted models
- **Workshops** - Shared model access without cloud costs
- **Homework Assignments** - Run powerful models from any notebook
- **Research Projects** - Access your own models from anywhere

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 🙏 Acknowledgments

- [Ollama](https://ollama.com/) - Local LLM runtime
- [localhost.run](https://localhost.run/) - SSH tunnel service
- [npoint.io](https://npoint.io/) - JSON storage service

## 📞 Support

For issues and questions:

- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting section

---

**Made with ❤️ for the GenAI learning community**
