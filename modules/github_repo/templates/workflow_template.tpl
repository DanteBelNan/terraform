name: Multi-Image Build & Push to ECR

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  ECR_URLS_JSON: '${ecr_urls_json}'
  AWS_REGION: '${aws_region}'
  APP_NAME: '${app_name}'

jobs:
  build_and_push:
    name: Docker Build, Tag, and Push
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: $${{ secrets.AWS_ACCESS_KEY_ID }} 
          aws-secret-access-key: $${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: $${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, Tag, and Push Images
        env:
          IMAGE_TAG: $${{ github.sha }} 
        run: |
          # 1. Prepare Variables and JQ
          sudo apt-get install -y jq
          REGISTRY_URL=$${{ steps.login-ecr.outputs.registry }}
          
          # Parse URIs from JSON
          NODE_URI=$(echo $ECR_URLS_JSON | jq -r '."node-repo"')
          NGINX_URI=$(echo $ECR_URLS_JSON | jq -r '."nginx-repo"')
          CLI_URI=$(echo $ECR_URLS_JSON | jq -r '."cli-repo"')
          
          # --- BUILD & PUSH IMAGES ---
          
          echo "Building Node Image: $NODE_URI"
          docker build -t $NODE_URI:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend
          docker tag $NODE_URI:$IMAGE_TAG $NODE_URI:latest
          docker push $NODE_URI:$IMAGE_TAG
          docker push $NODE_URI:latest

          echo "Building Nginx Image: $NGINX_URI"
          docker build -t $NGINX_URI:$IMAGE_TAG -f ./docker/Dockerfile.nginx ./frontend
          docker tag $NGINX_URI:$IMAGE_TAG $NGINX_URI:latest
          docker push $NGINX_URI:$IMAGE_TAG
          docker push $NGINX_URI:latest
          
          echo "Building CLI Image: $CLI_URI"
          docker build -t $CLI_URI:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend
          docker tag $CLI_URI:$IMAGE_TAG $CLI_URI:latest
          docker push $CLI_URI:$IMAGE_TAG
          docker push $CLI_URI:latest