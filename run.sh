#!/bin/bash

set -e  # Exit on error

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
EOF
        
        echo -e "${GREEN}Template .env file created.${NC}"
        echo "Please edit the .env file with your actual credentials and run the script again."
        exit 1
    fi
    
    # Check if required variables are in .env file
    if ! grep -q "B2_APPLICATION_KEY_ID" .env || ! grep -q "B2_APPLICATION_KEY" .env || ! grep -q "B2_BUCKET_NAME" .env || ! grep -q "EMAIL_SENDER" .env || ! grep -q "EMAIL_PASSWORD" .env || ! grep -q "EMAIL_RECIPIENT" .env; then
        echo -e "${RED}Error: .env file is missing required variables!${NC}"
        echo "Required variables: B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_NAME, EMAIL_SENDER, EMAIL_PASSWORD, EMAIL_RECIPIENT"
        exit 1
    fi
    
    echo -e "${GREEN}.env file check passed.${NC}"
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
    build_image
    run_container
}

# Run main function
main "$@"