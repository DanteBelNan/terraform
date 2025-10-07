// modules/github_repo/templates/jenkinsfile.tpl

// Define the overall structure of the pipeline
pipeline {
    agent any
    
    // Global environment variables
    environment {
        AWS_CRED_ID = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'
        
        AWS_REGION = '${aws_region}'             
        APP_NAME = '${app_name}'                     
        APP_INSTANCE_ID = '${app_instance_id}'       
        
        DEPLOY_SCRIPT = """
            #!/bin/bash
            
            # --- 1. SETUP ---
            aws configure set default.region $${AWS_REGION}
            
            GITHUB_OWNER="${github_owner}" 
            
            REPO_DIR="/home/ubuntu/$${APP_NAME}"
            
            echo "--- 1. Initiating Deployment via SSM ---"
            
            # --- 2. AWS ECR Authentication ---
            LOGIN_URL=\$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$${AWS_REGION}.amazonaws.com
            AUTH_TOKEN=\$(aws ecr get-login-password --region $${AWS_REGION})

            echo "Authenticating to ECR: \$LOGIN_URL"
            docker login --username AWS --password \$AUTH_TOKEN \$LOGIN_URL
            
            if [ \$? -ne 0 ]; then
              echo "❌ ERROR: ECR Authentication failed."
              exit 1
            fi

            # --- 3. Clone or Update Repository ---
            GITHUB_AUTH_URL="https://${github_owner}:$"'{GITHUB_TOKEN}'"@github.com/${github_owner}/$${APP_NAME}"

            if [ ! -d "\$REPO_DIR" ]; then
              echo "Cloning repository $${APP_NAME} into \$REPO_DIR..."
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
                withCredentials([string(credentialsId: "$${GITHUB_TOKEN_ID}", variable: 'GITHUB_TOKEN')]) {
                    
                    withAWS(credentials: "$${AWS_CRED_ID}") {
                        
                        echo "Targeting Instance ID: \$${APP_INSTANCE_ID}"
                        
                        sh """
                            aws ssm send-command \\
                                --instance-ids \$${APP_INSTANCE_ID} \\
                                --document-name "AWS-RunShellScript" \\
                                --parameters commands="\$${DEPLOY_SCRIPT}" \\
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