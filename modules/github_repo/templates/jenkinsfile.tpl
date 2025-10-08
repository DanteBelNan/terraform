// templates/jenkinsfile.tpl

pipeline {
    agent any
    
    environment {
        // Jenkins credential IDs
        AWS_CRED_ID     = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'
        
        // Variables injected by Terraform
        AWS_REGION      = '${aws_region}'             
        APP_NAME        = '${app_name}'                     
        APP_INSTANCE_ID = '${app_instance_id}'       
        GITHUB_OWNER    = '${github_owner}'
    }

    stages {
        stage('Deploy to EC2') {
            steps {
                withCredentials([string(credentialsId: GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                    withAWS(credentials: AWS_CRED_ID) {
                        
                        // All Jenkins variables are escaped with '$$' to prevent Terraform from processing them
                        echo "🚀 Triggering deployment for $${env.APP_NAME} on instance $${env.APP_INSTANCE_ID}..."
                        
                        // This script will be executed ON the EC2 instance via SSM
                        def remoteScript = """
                            # Exit on error
                            set -e
                            
                            # Define repository directory using the Jenkins environment variable
                            export REPO_DIR="/home/ubuntu/$${env.APP_NAME}"
                            
                            echo "--- 1. Updating repository ---"
                            cd \$REPO_DIR || exit 1
                            
                            # Temporarily configure git to use the token for the pull command
                            # GITHUB_TOKEN is a local Groovy var, env.GITHUB_OWNER is a Jenkins env var
                            git config --global credential.helper 'store'
                            echo "https://$${env.GITHUB_OWNER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
                            
                            git pull
                            
                            # Clean up credentials immediately after use for security
                            rm -f ~/.git-credentials
                            
                            echo "--- 2. Executing deployment script ---"
                            # The deploy.sh script will use environment variables already set on the server
                            bash \$REPO_DIR/deploy.sh
                        """
                        
                        // Send the script to the EC2 instance for execution
                        sh """
                            aws ssm send-command \\
                                --instance-ids "$${env.APP_INSTANCE_ID}" \\
                                --document-name "AWS-RunShellScript" \\
                                --parameters commands="'''${remoteScript}'''" \\
                                --comment "Jenkins CD for $${env.APP_NAME}, Build $${BUILD_NUMBER}"
                        """
                        
                        echo "✅ SSM Command sent. Check AWS Console for execution status."
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Pipeline finished successfully.'
        }
        failure {
            echo 'Pipeline failed. Check SSM command output in AWS Console.'
        }
    }
}