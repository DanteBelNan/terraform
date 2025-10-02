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
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, Tag, Push Images & Create Deploy Compose File
        env:
          IMAGE_TAG: ${{ github.sha }} 
        run: |
          sudo apt-get install -y jq
          REGISTRY_URL=${{ steps.login-ecr.outputs.registry }}
          
          # Parsear URIs del JSON
          NODE_URI=$(echo $ECR_URLS_JSON | jq -r '."node-repo"')
          NGINX_URI=$(echo $ECR_URLS_JSON | jq -r '."nginx-repo"')
          CLI_URI=$(echo $ECR_URLS_JSON | jq -r '."cli-repo"')
          
          # --- BUILD & PUSH IMAGES ---
          
          # 1. NODE (BACKEND)
          echo "Building Node Image: $NODE_URI"
          docker build -t $NODE_URI:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend
          docker tag $NODE_URI:$IMAGE_TAG $NODE_URI:latest
          docker push $NODE_URI:$IMAGE_TAG
          docker push $NODE_URI:latest

          # 2. NGINX (FRONTEND/PROXY)
          echo "Building Nginx Image: $NGINX_URI"
          docker build -t $NGINX_URI:$IMAGE_TAG -f ./docker/Dockerfile.nginx ./frontend
          docker tag $NGINX_URI:$IMAGE_TAG $NGINX_URI:latest
          docker push $NGINX_URI:$IMAGE_TAG
          docker push $NGINX_URI:latest
          
          # 3. CLI
          echo "Building CLI Image: $CLI_URI"
          docker build -t $CLI_URI:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend
          docker tag $CLI_URI:$IMAGE_TAG $CLI_URI:latest
          docker push $CLI_URI:$IMAGE_TAG
          docker push $CLI_URI:latest
          

          echo "Creating docker-compose.deploy.yml with URIs of ECR"
          
          cat <<EOT > docker-compose.deploy.yml
          version: '3.8'

          services:

            # 1. PostgreSQL Database Service
            db:
              image: postgres:16-alpine
              container_name: postgres_db
              restart: always
              environment:
                POSTGRES_DB: \${POSTGRES_DB}
                POSTGRES_USER: \${POSTGRES_USER}
                POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
              ports:
                - "\${DB_PORT}:5432"
              volumes:
                - postgres_data:/var/lib/postgresql/data

            # 2. Backend Service (Apunta a ECR - SIN build)
            node:
              image: $NODE_URI:latest
              container_name: node_backend
              restart: always
              depends_on:
                - db 
              environment:
                NODE_ENV: \${NODE_ENV}
                PORT: \${APP_PORT}
                SECRET_KEY: \${SECRET_KEY}
                DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
              volumes:
                - /app/node_modules 

            # 3. Nginx Service (Apunta a ECR - SIN build)
            nginx:
              image: $NGINX_URI:latest
              container_name: nginx_proxy
              restart: always
              ports:
                - "8080:80" 
              depends_on:
                - node
                
            # 4. CLI Service (Apunta a ECR - SIN build)
            cli:
              image: $CLI_URI:latest
              container_name: node
              depends_on:
                - db
                - node
              environment:
                DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
                NODE_ENV: \${NODE_ENV}
              volumes:
                - /app/node_modules
              entrypoint: sh 
              command: -c "tail -f /dev/null"

          volumes:
            postgres_data:
          EOT
          
          git config user.name 'github-actions[bot]'
          git config user.email 'github-actions[bot]@users.noreply.github.com'
          git add docker-compose.deploy.yml
          git commit -m "CI: Update docker-compose.deploy.yml with ECR URIs" || true
          git push