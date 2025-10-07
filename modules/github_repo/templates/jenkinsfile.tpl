// Define the overall structure of the pipeline
pipeline {
    agent any
    
    // Global environment variables (read from Jenkins Credential IDs)
    environment {
        // IDs of the credentials created in Jenkins Manager
        AWS_CRED_ID = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'

        // AWS Region for SSM command (Terraform Injected)
        AWS_REGION = '${aws_region}' 
        
        // Target Application Configuration (Terraform Injected)
        APP_NAME = '${app_name}'
        
        # 🚨 IMPORTANT: Instance ID of your application server (Terraform Injected)
        APP_INSTANCE_ID = '${app_instance_id}' 
        
        // The deployment script to be executed on the target instance via SSM
        DEPLOY_SCRIPT = """
            #!/bin/bash
            
            # --- 1. SETUP ---
            # Set the AWS Credentials and Region for the AWS CLI session
            aws configure set default.region \${AWS_REGION}
            
            # --- Variables inherited from Jenkins Env ---
            # APP_NAME, AWS_REGION, GITHUB_TOKEN (injected via withCredentials)
            
            GITHUB_OWNER="${github_owner}" 
            REPO_DIR="/home/ubuntu/\$APP_NAME"
            
            echo "--- 1. Initiating Deployment via SSM ---"
            
            # --- 2. AWS ECR Authentication ---
            # Get ECR login details using the instance's IAM role permissions
            LOGIN_URL=\$(aws sts get-caller-identity --query Account --output text).dkr.ecr.\${AWS_REGION}.amazonaws.com
            AUTH_TOKEN=\$(aws ecr get-login-password --region \${AWS_REGION})

            echo "Authenticating to ECR: \$LOGIN_URL"
            docker login --username AWS --password \${AUTH_TOKEN} \${LOGIN_URL}
            
            if [ \$? -ne 0 ]; then
              echo "❌ ERROR: ECR Authentication failed."
              exit 1
            fi

            # --- 3. Clone or Update Repository ---
            # GITHUB_TOKEN is passed securely as an environment variable by Jenkins
            GITHUB_AUTH_URL="https://\${GITHUB_OWNER}:\${GITHUB_TOKEN}@github.com/\${GITHUB_OWNER}/\${APP_NAME}"

            if [ ! -d "\$REPO_DIR" ]; then
              echo "Cloning repository \${APP_NAME} into \$REPO_DIR..."
              sudo -u ubuntu git clone "\$GITHUB_AUTH_URL" "\$REPO_DIR" 
            else
              echo "Repository exists. Fetching latest changes..."
              cd "\$REPO_DIR" || exit
              sudo -u ubuntu git remote set-url origin "\$GITHUB_AUTH_URL"
              sudo -u ubuntu git pull
            fi

            # --- 4. Docker Compose Deployment ---
            echo "Executing Docker Compose Pull and Up..."
            cd "\$REPO_DIR" || exit

            # Run the deployment using the local docker-compose.deploy.yml file
            sudo docker compose -f docker-compose.deploy.yml pull
            sudo docker compose -f docker-compose.deploy.yml up -d

            if [ \$? -eq 0 ]; then
              echo "✅ SUCCESS: Application deployed to Compute Server."
            else
              echo "❌ FAILURE: Docker Compose deployment failed."
              exit 1
            fi
        """
    }

    stages {
        stage('Initialize & Build ECR Images') {
            steps {
                echo "Skipping ECR Build: Relying on GitHub Actions to push images to ECR."
            }
        }
        
        stage('Deployment via AWS SSM') {
            steps {
                // 1. Get the GitHub PAT from Jenkins credentials and inject it into the pipeline environment
                // This makes the token available as the GITHUB_TOKEN environment variable in the script
                withCredentials([string(credentialsId: "${GITHUB_TOKEN_ID}", variable: 'GITHUB_TOKEN')]) {
                    
                    // 2. Get the AWS keys from Jenkins credentials and set them for the AWS CLI
                    withAWS(credentials: "${AWS_CRED_ID}") {
                        
                        echo "Targeting Instance ID: \${APP_INSTANCE_ID}"
                        
                        // 3. Execute the deployment script via AWS Systems Manager (SSM)
                        sh """
                            aws ssm send-command \\
                                --instance-ids \${APP_INSTANCE_ID} \\
                                --document-name "AWS-RunShellScript" \\
                                --parameters commands="\${DEPLOY_SCRIPT}" \\
                                --comment "CD Deploy: Triggered by Jenkins Pipeline Build \${BUILD_NUMBER}"
                        """
                        
                        echo "SSM Command Sent. Check AWS console for status."
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline finished successfully. Application is deployed.'
        }
        failure {
            echo 'Pipeline failed. Check the SSM command output in AWS.'
        }
    }
}