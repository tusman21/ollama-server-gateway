#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Logging Functions ---
log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}
log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}
log_warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}
log_error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# --- Cleanup ---
# This function will run when the script exits (e.g., on Ctrl+C)
OLLAMA_PID=""
cleanup() {
    echo "" # Newline on exit
    log_info "Cleaning up and shutting down..."
    if [ -n "$OLLAMA_PID" ]; then
        # If we started ollama, kill the background process
        kill $OLLAMA_PID > /dev/null 2>&1
        log_info "Stopped background Ollama process."
    fi
    log_info "Tunnel closed. Goodbye!"
}

# Register the cleanup function to run on script exit
trap cleanup EXIT

# --- Banner ---
clear
echo -e "${GREEN}======================================================${NC}" >&2
echo -e "${GREEN}                Ollama Server Gateway                 ${NC}" >&2
echo -e "${GREEN}======================================================${NC}" >&2
echo ""

# --- 1. Argument Check ---
if [ -z "$1" ]; then
    log_error "Missing discovery URL."
    echo "Usage: $0 <your_npoint_io_or_jsonbin_url>"
    exit 1
fi

DISCOVERY_URL="$1"
log_info "Using discovery URL: $DISCOVERY_URL"

# --- Dependency Checks ---
if ! command -v curl &> /dev/null; then
    log_error "curl is not installed. Please install it to continue."
fi

if ! command -v ssh &> /dev/null; then
    log_error "ssh is not installed. Please install it to continue."
fi

# --- 2. Ollama Service Check ---
log_info "Checking if Ollama is running at http://localhost:11434..."

# Use curl to check if the Ollama API is responsive
if curl --silent --fail http://localhost:11434/ > /dev/null 2>&1; then
    log_success "Ollama is already running."
else
    log_warn "Ollama not detected. Attempting to start it..."
    
    # Set OLLAMA_HOST for all platforms
    export OLLAMA_HOST='0.0.0.0'
    log_info "Set export OLLAMA_HOST=0.0.0.0"
    
    # Start ollama serve in the background
    # Redirect its stdout/stderr to /dev/null so it doesn't clutter our output
    ollama serve > /dev/null 2>&1 &
    
    # Save the Process ID (PID) of the background command
    OLLAMA_PID=$!
    
    log_info "Started Ollama in the background (PID: $OLLAMA_PID)."
    log_info "Waiting for Ollama to initialize..."
    
    # Give it 5 seconds to start up
    sleep 5
    
    # Check again
    if ! curl --silent --fail http://localhost:11434/ > /dev/null 2>&1; then
        log_error "Failed to start Ollama. Please start it manually and re-run the script."
    fi
    
    log_success "Ollama started successfully."
fi

echo "" # Spacing

# --- 3. Start Tunnel ---
log_info "Starting secure tunnel for Ollama (http://localhost:11434)..."
log_warn "Waiting for public URL... (This may take a moment)"

# 1. Start localhost.run tunnel.
# 2. Redirect stderr (where the URL is printed) to stdout.
# 3. Pipe the output line by line to the while loop.
ssh -R 80:localhost:11434 nokey@localhost.run 2>&1 | while read -r line; do
    # 4. Print every line from the ssh command
    # echo "SSH: $line"

    # 5. Look for the line containing the https URL
    if [[ $line == *"https://"* ]]; then
        
        # 6. Extract the URL
        # Use grep with -o (only-matching) and a regex to find the URL
        TUNNEL_URL=$(echo "$line" | grep -oP 'https://[a-zA-Z0-9.-]*\.life')

        if [ -n "$TUNNEL_URL" ]; then
            log_success "Public URL found: $TUNNEL_URL"
            
            # 6. Post the new URL to the discovery service
            log_info "Broadcasting URL to discovery service..."
            
            curl_response=$(curl --silent -X POST -H "Content-Type: application/json" \
                 -d "{\"url\":\"$TUNNEL_URL\"}" "$DISCOVERY_URL")
            
            log_success "Broadcast complete."
            echo "" # Add spacing
            echo "" # Add spacing
            log_warn "Leave this terminal open to keep the tunnel alive."
            log_warn "Press Ctrl+C to shut down."
            echo "" # Add spacing
        fi
    fi
    
    # Optional: uncomment to see all ssh output (can be noisy)
    # echo -e "${DIM}SSH: $line${NC}"
done