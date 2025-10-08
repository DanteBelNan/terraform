pipeline {
    agent any
    
    environment {
        AWS_CRED_ID     = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'
        
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
                        
                        echo "🚀 Triggering deployment for ${APP_NAME} on instance ${APP_INSTANCE_ID}..."
                        
                        def remoteScript = """
                            # Exit on error
                            set -e
                            
                            # Define repository directory
                            export REPO_DIR="/home/ubuntu/${APP_NAME}"
                            
                            echo "--- 1. Updating repository ---"
                            cd \$REPO_DIR || exit 1
                            
                            # Temporarily configure git to use the token for the pull command
                            git config --global credential.helper 'store'
                            echo "https://${GITHUB_OWNER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
                            
                            git pull
                            
                            # Clean up credentials immediately after use for security
                            rm -f ~/.git-credentials
                            
                            echo "--- 2. Executing deployment script ---"
                            # The deploy.sh script will use environment variables already set on the server
                            bash \$REPO_DIR/deploy.sh
                        """
                        
                        sh """
                            aws ssm send-command \\
                                --instance-ids "${APP_INSTANCE_ID}" \\
                                --document-name "AWS-RunShellScript" \\
                                --parameters commands="'''${remoteScript}'''" \\
                                --comment "Jenkins CD for ${APP_NAME}, Build ${BUILD_NUMBER}"
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