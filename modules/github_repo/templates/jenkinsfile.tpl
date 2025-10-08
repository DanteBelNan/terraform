// templates/jenkinsfile.tpl

pipeline {
    agent any
    
    environment {
        AWS_CRED_ID     = 'AWS_DEPLOYER_CREDENTIALS' 
        GITHUB_TOKEN_ID = 'GITHUB_PAT_ID'
        
        AWS_REGION      = '${aws_region}'             
        APP_NAME        = '${app_name}'                     
        APP_INSTANCE_ID = '${app_instance_id}'       
        GITHUB_OWNER    = '${github_owner}'

        ECR_NODE_URI    = '${ecr_node_uri}'
        ECR_NGINX_URI   = '${ecr_nginx_uri}'
        ECR_CLI_URI     = '${ecr_cli_uri}'
    }

    stages {
        stage('Build & Push to ECR') {
            steps {
                checkout scm
                withAWS(credentials: AWS_CRED_ID) {
                    
                    script {
                        echo "🚀 Starting Docker build and push process..."
                        
                        sh "aws ecr get-login-password --region $${env.AWS_REGION} | docker login --username AWS --password-stdin $${env.ECR_NODE_URI}"

                        def imageTag = env.GIT_COMMIT.take(12)

                        echo "--- Building node image ---"
                        sh "docker build -t $${env.ECR_NODE_URI}:$${imageTag} -f ./docker/Dockerfile.node ./backend"
                        sh "docker tag $${env.ECR_NODE_URI}:$${imageTag} $${env.ECR_NODE_URI}:latest"
                        sh "docker push $${env.ECR_NODE_URI}:$${imageTag}"
                        sh "docker push $${env.ECR_NODE_URI}:latest"
                        
                        echo "--- Building nginx image ---"
                        sh "docker build -t $${env.ECR_NGINX_URI}:$${imageTag} -f ./docker/Dockerfile.nginx ./frontend"
                        sh "docker tag $${env.ECR_NGINX_URI}:$${imageTag} $${env.ECR_NGINX_URI}:latest"
                        sh "docker push $${env.ECR_NGINX_URI}:$${imageTag}"
                        sh "docker push $${env.ECR_NGINX_URI}:latest"

                        echo "--- Building cli image ---"
                        sh "docker build -t $${env.ECR_CLI_URI}:$${imageTag} -f ./docker/Dockerfile.node ./backend"
                        sh "docker tag $${env.ECR_CLI_URI}:$${imageTag} $${env.ECR_CLI_URI}:latest"
                        sh "docker push $${env.ECR_CLI_URI}:$${imageTag}"
                        sh "docker push $${env.ECR_CLI_URI}:latest"

                        echo "✅ All images pushed to ECR."
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                withCredentials([string(credentialsId: GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                    withAWS(credentials: AWS_CRED_ID) {
                        
                        script {
                            echo "🚀 Triggering deployment for $${env.APP_NAME} on instance $${env.APP_INSTANCE_ID}..."
                            
                            def remoteScript = """
                                set -e
                                export REPO_DIR="/home/ubuntu/$${env.APP_NAME}"
                                echo "--- 1. Updating repository ---"
                                cd \$REPO_DIR || exit 1
                                git config --global credential.helper 'store'
                                echo "https://$${env.GITHUB_OWNER}:$${GITHUB_TOKEN}@github.com" > ~/.git-credentials
                                git pull
                                rm -f ~/.git-credentials
                                echo "--- 2. Executing deployment script ---"
                                bash \$REPO_DIR/deploy.sh
                            """
                            
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
    }
    post {
        success {
            echo 'Pipeline finished successfully.'
        }
        failure {
            echo 'Pipeline failed. Check stages for output.'
        }
    }
}