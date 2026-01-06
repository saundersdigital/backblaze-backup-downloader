#!/bin/bash

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check if .env file exists and is properly formatted
check_env_file() {
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file not found!${NC}"
        echo "Creating template .env file..."
        
        cat > .env << 'EOF'
B2_APPLICATION_KEY_ID=application-key-id
B2_APPLICATION_KEY=application-key
B2_BUCKET_NAME=bucket-name

EMAIL_SENDER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password_here
EMAIL_RECIPIENT=recipient_email@example.com

APP_TIMEZONE=Australia/Sydney
EOF
        
        echo -e "${GREEN}Template .env file created.${NC}"
        echo "Please edit the .env file with your actual credentials and run the script again."
        exit 1
    fi
    
    # Check if required variables are in .env file
    if ! grep -q "B2_APPLICATION_KEY_ID" .env || ! grep -q "B2_APPLICATION_KEY" .env || ! grep -q "B2_BUCKET_NAME" .env || ! grep -q "EMAIL_SENDER" .env || ! grep -q "EMAIL_PASSWORD" .env || ! grep -q "EMAIL_RECIPIENT" .env || ! grep -q "APP_TIMEZONE" .env; then
        echo -e "${RED}Error: .env file is missing required variables!${NC}"
        echo "Required variables: B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_NAME, EMAIL_SENDER, EMAIL_PASSWORD, EMAIL_RECIPIENT, APP_TIMEZONE"
        exit 1
    fi
    
    echo -e "${GREEN}.env file check passed.${NC}"
}

# Function to check if there is an internet connection
check_internet() {
    echo "Checking internet connection..."
    
    # Try multiple methods to check internet connectivity
    # Method 1: ping a reliable host (Google DNS)
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}Internet connection detected via ping.${NC}"
        return 0
    fi
    
    # Method 2: curl with timeout to check connectivity
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 3 -I https://www.google.com &> /dev/null; then
            echo -e "${GREEN}Internet connection detected via curl.${NC}"
            return 0
        fi
    fi
    
    # Method 3: wget with timeout (fallback if curl not available)
    if command -v wget &> /dev/null; then
        if wget -q --spider --timeout=3 https://www.google.com &> /dev/null; then
            echo -e "${GREEN}Internet connection detected via wget.${NC}"
            return 0
        fi
    fi
    
    # Method 4: Check for network interfaces (if all else fails)
    if [ -n "$(ip route show default 2>/dev/null | grep -v '^[[:space:]]*$')" ]; then
        echo -e "${GREEN}Network interface detected.${NC}"
        echo -e "${YELLOW}Warning: Internet connectivity cannot be fully verified.${NC}"
        echo "The script will continue, but may fail if actual internet connection is not available."
        return 0
    fi
    
    echo -e "${RED}Error: No internet connection detected!${NC}"
    echo "This script requires an internet connection to work with Backblaze B2."
    echo "Please check your network connection and try again."
    exit 1
}

# Function to check if Docker is installed and running
check_docker() {
    echo "Checking Docker installation..."
    
    # Check if Docker command exists
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed!${NC}"
        echo "Please install Docker and ensure it's available in your PATH."
        echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running!${NC}"
        echo "Please start Docker daemon (Docker Desktop or Docker service)."
        exit 1
    fi
    
    # Check Docker version to ensure it's working properly
    echo -e "${GREEN}Docker is installed and running.${NC}"
    echo "Docker version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
}

# Function to build Docker image
build_image() {
    echo "Building Docker image 'b2-downloader'..."
    docker build -t b2-downloader . -q
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker image built successfully.${NC}"
    else
        echo -e "${RED}Failed to build Docker image.${NC}"
        exit 1
    fi
}

# Function to run Docker container
run_container() {
    echo "Running Docker container..."
    
    # Create downloads directory if it doesn't exist
    mkdir -p "$(pwd)/b2_downloads"
    
    docker run --rm \
        --env-file .env \
        -u $(id -u):$(id -g) \
        -v "$(pwd)/b2_downloads":/app/b2_downloads \
        b2-downloader
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Container finished successfully.${NC}"
    else
        echo -e "${RED}Container execution failed.${NC}"
    fi
}

main() {
    echo "=== B2 Downloader Script ==="
    
    check_env_file
    check_internet
    check_docker
    build_image
    run_container
}

# Run main function
main "$@"