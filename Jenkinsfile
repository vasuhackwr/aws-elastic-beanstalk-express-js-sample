pipeline {
    agent any

    environment {
        IMAGE_NAME = 'secure-devops-app'
        CONTAINER_NAME = 'secure-devops-app'
        APP_PORT = '8080'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm install'
            }
        }

        stage('Dependency Security Scan') {
            steps {
                echo 'Scanning Node.js dependencies for HIGH and CRITICAL vulnerabilities...'
                sh 'npm audit --audit-level=high'
            }
        }

        stage('Test') {
            steps {
                echo 'No automated tests configured - skipping tests'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Container Security Scan') {
            steps {
                echo 'Running Trivy container security scan...'

                sh '''
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Security scan passed. Deploying application...'

                sh '''
                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${APP_PORT}:${APP_PORT} \
                    ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying application deployment...'

                sh '''
                    sleep 5

                    docker ps

                    docker exec ${CONTAINER_NAME} \
                    wget -qO- http://localhost:${APP_PORT}
                '''
            }
        }
    }

    post {

        success {
            echo 'Pipeline completed successfully.'
            echo 'Application passed security checks, deployed and verified successfully.'
        }

        failure {
            echo 'Pipeline failed.'
            echo 'A build, security, deployment or verification stage failed.'
            echo 'Check the Jenkins console output for details.'
        }

        always {
            echo 'CI/CD pipeline execution finished.'
        }
    }
}
