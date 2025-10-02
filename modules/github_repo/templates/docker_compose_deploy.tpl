version: '3.8'

services:

  # 1. PostgreSQL Database Service
  db:
    image: postgres:16-alpine
    container_name: postgres_db
    restart: always
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${DB_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # 2. Backend Service (Uses ECR - No build)
  node:
    # ECR URI inyectado por Terraform
    image: ${node_uri}:latest
    container_name: node_backend
    restart: always
    depends_on:
      - db 
    environment:
      NODE_ENV: ${NODE_ENV}
      PORT: ${APP_PORT}
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    volumes:
      - /app/node_modules 

  # 3. Nginx Service (Uses ECR - No build)
  nginx:
    image: ${nginx_uri}:latest
    container_name: nginx_proxy
    restart: always
    ports:
      - "8080:80" 
    depends_on:
      - node
      
  # 4. CLI Service (Uses ECR - No build)
  cli:
    image: ${cli_uri}:latest
    container_name: node
    depends_on:
      - db
      - node
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      NODE_ENV: ${NODE_ENV}
    volumes:
      - /app/node_modules
    entrypoint: sh 
    command: -c "tail -f /dev/null"

volumes:
  postgres_data: