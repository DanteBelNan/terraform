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
          # Captura la URL del login de ECR
          REGISTRY_URL=${{ steps.login-ecr.outputs.registry }}

          # Usa las variables inyectadas por Terraform y GitHub Actions
          ECR_REPO_NAME=${{ env.ECR_REPOSITORY }}
          
          echo "ECR Target: $REGISTRY_URL/$ECR_REPO_NAME"

          # 1. Compila la imagen (asume que el Dockerfile está en ./docker/Dockerfile.node y el contexto en ./backend)
          # Asegúrate de que las rutas relativas sean correctas para tu plantilla
          docker build -t $REGISTRY_URL/$ECR_REPO_NAME:$IMAGE_TAG -f ./docker/Dockerfile.node ./backend

          # 2. Etiqueta como 'latest'
          docker tag $REGISTRY_URL/$ECR_REPO_NAME:$IMAGE_TAG $REGISTRY_URL/$ECR_REPO_NAME:latest

          # 3. Empuja al ECR
          docker push $REGISTRY_URL/$ECR_REPO_NAME:$IMAGE_TAG
          docker push $REGISTRY_URL/$ECR_REPO_NAME:latest