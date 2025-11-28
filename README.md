# Ollama Server Gateway

> A secure and effortless bridge connecting Cloud Notebooks with locally hosted Ollama models

[![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)

## 🎯 Overview

Ollama Server Gateway solves the fundamental challenges of GenAI learning and experimentation by creating a secure, lightweight connection between cloud notebooks and local Ollama models. No more expensive cloud LLMs, no more slow temporary Colab setups—just fast, reliable, and private GenAI processing.

### Key Features

- 🔐 **Secure Tunneling** - Encrypted SSH tunnels for safe remote access
- 🚀 **Instant Discovery** - Automatic service registration and discovery via ntfy.sh
- 🔒 **Data Privacy** - All processing happens locally on your machine
- ⚡ **Zero Configuration** - Single command setup and deployment
- 🎓 **Education-First** - Perfect for students and learners
- 💰 **Cost-Free** - No cloud API costs, compute fees, or external service dependencies

## 📋 Prerequisites

Before running the gateway, ensure you have:

- **Ollama** - [Download and install](https://ollama.com/download) on your local machine
- **SSH Client** - Pre-installed on most Linux/macOS systems
- **curl** - For HTTP requests and API interactions
- **Bash 4.0+** - Standard on most Unix-like systems

## 🚀 Quick Start

### 1. Choose a Topic Name

Pick a unique topic name for your gateway. This acts as your discovery channel:

- **Simple option**: Use your email or username (e.g., `john.doe@example.com` or `johndoe123`)
- **Secure option**: Generate a random UUID for better security
  - Generate a UUID here: [UUID Generator](https://www.uuidgenerator.net/)
  - Example: `a3d5f7c2-9b4e-4a1c-8f2d-6e9b3c1a5d7f`

⚠️ **Security Note**: Anyone who knows your topic name can discover your gateway URL. Use a UUID for sensitive use cases.

### 2. Download the Script

```bash
curl -L -o ollama-gateway-connect.sh https://raw.githubusercontent.com/tusman21/ollama-server-gateway/refs/heads/main/ollama-gateway-connect.sh
```

### 3. Make it executable

```bash
chmod +x ollama-gateway-connect.sh
```

### 4. Start the Gateway

```bash
./ollama-gateway-connect.sh your-unique-topic-name
```

The script will:

- ✅ Check if Ollama is running (starts it if needed)
- ✅ Create a secure SSH tunnel via localhost.run
- ✅ Register the public URL to ntfy.sh using your topic
- ✅ Keep the connection alive

### 5. Example Connection from Google Colab

In your Colab notebook:

```python
from ollama import Client
import requests

OLLAMA_HOST = ""

# Replace with the same topic you used in the bash script
TOPIC = "your-unique-topic-name"
DISCOVERY_URL = f"https://ntfy.sh/{TOPIC}/json?poll=1&since=latest";

def discover_ollama_gateway(url):
  response = requests.get(url, timeout=10)
  response.raise_for_status()
  return response.json()

try:
    data = discover_ollama_gateway(DISCOVERY_URL)
    if data.get('message'):
      OLLAMA_HOST = data.get('message')
      print(f"Successfully discovered local Ollama at: {OLLAMA_HOST}")
except Exception as e:
    print(f"Error connecting to discovery service: {e}")

client = Client(host=OLLAMA_HOST)
```

## 🛠️ Usage

### Basic Syntax

```bash
./ollama-gateway-connect.sh <unique-topic-name>
```

### Arguments

| Argument     | Description                                          | Required |
| ------------ | ---------------------------------------------------- | -------- |
| `topic-name` | Your unique topic name or UUID for service discovery | Yes      |

### Examples

```bash
# Using email/username (simple but less secure)
./ollama-gateway-connect.sh john.doe@example.com

# Using UUID (recommended for security)
./ollama-gateway-connect.sh a3d5f7c2-9b4e-4a1c-8f2d-6e9b3c1a5d7f
```

## 📊 How It Works

1. **Service Detection** - Script checks if Ollama is running locally
2. **Tunnel Creation** - Establishes secure SSH tunnel via localhost.run
3. **URL Broadcasting** - Publishes public URL to ntfy.sh topic
4. **Client Discovery** - Colab notebooks fetch URL from ntfy.sh
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

### 1. Ollama Won't Start

If Ollama fails to start automatically, manually start it with ports open:

```bash
# Stop any existing Ollama processes
pkill ollama

# Start Ollama with correct configuration
export OLLAMA_HOST='0.0.0.0'
ollama serve
```

Then run the gateway script in a new terminal.

### 2. Ollama Running But Colab Cannot Access

If Ollama is running but Colab can't connect, the ports may not be configured correctly:

```bash
# Stop the current Ollama instance
pkill ollama

# Let the gateway script start Ollama with the correct configuration
./ollama-gateway-connect.sh your-topic-name
```

The script will automatically start Ollama with the proper port settings.

### 3. Tunnel Disconnected

If the tunnel connection drops:

1. Stop the gateway script with `Ctrl+C`
2. Restart the gateway script:
   ```bash
   ./ollama-gateway-connect.sh your-topic-name
   ```
3. Re-run the connection block in your Colab notebook to fetch the new URL

## 🔒 Security Considerations

- **Tunnel Encryption** - All traffic is encrypted via SSH
- **Local Processing** - Data never leaves your machine
- **Temporary URLs** - localhost.run URLs expire after tunnel closes
- **Topic Privacy** - Anyone with your topic name can discover your gateway URL
  - Use a UUID instead of predictable names for sensitive work
  - Consider your topic name as a shared secret
  - Generate secure UUIDs at: [UUID Generator](https://www.uuidgenerator.net/)
- **No Authentication** - Anyone with the URL can access your Ollama instance
  - Only share topic names with trusted parties
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
- [ntfy.sh](https://ntfy.sh/) - Simple notification and messaging service

## 📞 Support

For issues and questions:

- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting section

---

**Made with ❤️ for the GenAI learning community**
