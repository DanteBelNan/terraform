// modules/github_repo/templates/jenkinsfile.tpl

pipeline {
    agent any
    
    // Global environment variables. DEPLOY_SCRIPT was removed from here.
    environment {
        AWS_CRED_ID     = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'
        
        // These variables are injected by Terraform
        AWS_REGION      = '${aws_region}'             
        APP_NAME        = '${app_name}'                     
        APP_INSTANCE_ID = '${app_instance_id}'       
    }

    stages {
        stage('Initialize') {
            steps {
                echo "Skipping ECR Build: Relying on GitHub Actions to push images to ECR."
            }
        }
        
        stage('Deployment via AWS SSM') {
            steps {
                // Get the credentials. GITHUB_TOKEN only exists within this block.
                withCredentials([string(credentialsId: GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                     
                    withAWS(credentials: AWS_CRED_ID) {
                        
                        // --- DEFINE THE SCRIPT HERE ---
                        // We use triple single quotes (''') so Groovy doesn't interpret the '$' from the shell script.
                        // We safely inject the GITHUB_TOKEN.
                        def deployScript = '''
                            #!/bin/bash
                            set -e # Exit the script if a command fails

                            # --- 1. SETUP ---
                            # Variables from the Jenkins 'environment' block are available in the shell
                            aws configure set default.region $AWS_REGION
                            
                            GITHUB_OWNER="${github_owner}" 
                            REPO_DIR="/home/ubuntu/$APP_NAME"
                            
                            echo "--- 1. Initiating Deployment via SSM ---"
                            
                            # --- 2. AWS ECR Authentication ---
                            LOGIN_URL=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
                            AUTH_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

                            echo "Authenticating to ECR: $LOGIN_URL"
                            docker login --username AWS --password "$AUTH_TOKEN" $LOGIN_URL
                            
                            # --- 3. Clone or Update Repository ---
                            # We use the token injected from Jenkins
                            GITHUB_AUTH_URL="https://${github_owner}:${token_placeholder}@github.com/${github_owner}/$APP_NAME"

                            if [ ! -d "$REPO_DIR" ]; then
                              echo "Cloning repository $APP_NAME into $REPO_DIR..."
                              sudo -u ubuntu git clone "$GITHUB_AUTH_URL" "$REPO_DIR" 
                            else
                              echo "Repository exists. Fetching latest changes..."
                              cd "$REPO_DIR" || exit
                              sudo -u ubuntu git remote set-url origin "$GITHUB_AUTH_URL"
                              sudo -u ubuntu git pull
                            fi

                            # --- 4. Docker Compose Deployment ---
                            echo "Executing Docker Compose Pull and Up..."
                            cd "$REPO_DIR" || exit

                            sudo docker compose -f docker-compose.deploy.yml pull
                            sudo docker compose -f docker-compose.deploy.yml up -d

                            echo "✅ SUCCESS: Application deployed to Compute Server."
                        '''.replace('$${token_placeholder}', GITHUB_TOKEN) 

                        echo "Targeting Instance ID: ${APP_INSTANCE_ID}"
                        
                        // Execute the SSM command, passing the processed script
                        sh """
                            aws ssm send-command \\
                                --instance-ids "${APP_INSTANCE_ID}" \\
                                --document-name "AWS-RunShellScript" \\
                                --parameters commands="'''${deployScript}'''" \\
                                --comment "CD Deploy: Triggered by Jenkins Pipeline Build ${BUILD_NUMBER}"
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