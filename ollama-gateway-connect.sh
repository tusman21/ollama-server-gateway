#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Logging Functions ---
log_info() { printf "${BLUE}INFO: %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}SUCCESS: %s${NC}\n" "$1"; }
log_warn() { printf "${YELLOW}WARN: %s${NC}\n" "$1"; }
log_error() { printf "${RED}ERROR: %s${NC}\n" "$1"; exit 1; }

# --- Cleanup ---
OLLAMA_PID=""
cleanup() {
    echo ""
    log_info "Cleaning up..."
    if [ -n "$OLLAMA_PID" ]; then
        kill $OLLAMA_PID > /dev/null 2>&1
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
    log_error "Missing Topic. Usage: $0 <unique-topic-name>"
fi
TOPIC="$1"

# --- Dependency Checks ---
command -v curl >/dev/null 2>&1 || log_error "curl is not installed."
command -v ssh >/dev/null 2>&1 || log_error "ssh is not installed."

# --- 2. Ollama Service Check ---
log_info "Checking Ollama status..."

if curl --silent --fail http://localhost:11434/ > /dev/null 2>&1; then
    log_success "Ollama is running."
else
    log_warn "Ollama not detected. Starting..."
    export OLLAMA_HOST='0.0.0.0'
    
    log_info "Starting Ollama..."
    echo -e "${DIM}--- Ollama Logs ---${NC}"
    
    ollama serve 2>&1 | while IFS= read -r line; do
        echo -e "${DIM}[Ollama] $line${NC}"
    done &
    
    OLLAMA_PID=$!
    sleep 5
    
    if ! curl --silent --fail http://localhost:11434/ > /dev/null 2>&1; then
        log_error "Failed to start Ollama."
    fi
    log_success "Ollama is running."
fi

echo ""

# --- 3. Start Tunnel ---
log_info "Opening secure tunnel..."
log_warn "Waiting for public URL..."

ssh -T -R 80:localhost:11434 nokey@localhost.run 2>&1 | while IFS= read -r line; do
    
    clean_line=$(echo "$line" | tr -d '\r')

    # (Uncomment for additional logs) Print every line from the ssh command
    # if [ -n "$clean_line" ]; then
    #     echo "SSH: $clean_line"
    # fi

    if [[ $clean_line == *"https://"* ]]; then
        # Extract URL
        TUNNEL_URL=$(echo "$clean_line" | grep -oP 'https://[a-zA-Z0-9.-]*\.life')

        if [ -n "$TUNNEL_URL" ]; then
            log_info "Attempting to register tunnel URL: $TUNNEL_URL"
            
            if curl --silent --show-error --fail -d "$TUNNEL_URL" "https://ntfy.sh/$TOPIC"; then
                log_success "Gateway live!"
                echo ""
                log_warn "Press Ctrl+C to stop."
                echo ""
            else
                log_error "Failed to register tunnel URL with ntfy.sh"
            fi
        fi
    fi
done