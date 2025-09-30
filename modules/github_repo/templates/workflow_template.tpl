# modules/github_repo/templates/workflow_template.tpl

name: Build & Push Backend Image to ECR

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  # Valores inyectados por Terraform
  ECR_REPOSITORY: "${split("/", ecr_repo_uri)[1]}" # Solo el nombre del repo sin la cuenta/región
  ECR_REGISTRY_URI: "${ecr_repo_uri}"
  AWS_REGION: "${aws_region}"                 

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

      - name: Build, Tag, and Push Docker Image
        env:
          IMAGE_TAG: ${{ github.sha }} 
        run: |
          REGISTRY_URL=${{ steps.login-ecr.outputs.registry }}

          echo "ECR Target: $REGISTRY_URL/$ECR_REPOSITORY"

          # 1. Compila la imagen 
          docker build -t $REGISTRY_URL/$ECR_REPOSITORY:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend

          # 2. Etiqueta como 'latest'
          docker tag $REGISTRY_URL/$ECR_REPOSITORY:$IMAGE_TAG $REGISTRY_URL/$ECR_REPOSITORY:latest

          # 3. Empuja al ECR
          docker push $REGISTRY_URL/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $REGISTRY_URL/$ECR_REPOSITORY:latest