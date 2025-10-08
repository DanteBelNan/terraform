#!/bin/bash
set -e

echo "--- 🚀 Starting application deployment ---"

echo "Pulling latest Docker images..."
sudo docker compose -f docker-compose.deploy.yml pull

echo "Starting services..."
sudo docker compose -f docker-compose.deploy.yml up -d

echo "✅ Success! Application has been deployed."