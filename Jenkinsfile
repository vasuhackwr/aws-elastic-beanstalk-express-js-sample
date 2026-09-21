pipeline {
    agent any

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
                echo 'Scanning Node.js dependencies for High/Critical vulnerabilities...'
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
                sh 'docker build -t secure-devops-app:latest .'
            }
        }

        stage('Container Security Scan') {
            steps {
                echo 'Scanning Docker image with Trivy...'

                sh '''
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy:latest \
                      image \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      secure-devops-app:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application container...'

                sh '''
                    docker rm -f secure-devops-app || true

                    docker run -d \
                      --name secure-devops-app \
                      -p 8080:8080 \
                      secure-devops-app:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying application deployment...'

                sh '''
                    sleep 5
                    docker ps
                    docker exec secure-devops-app wget -qO- http://localhost:8080
                '''
            }
        }
    }

    post {

        success {
            echo 'Pipeline completed successfully.'
            echo 'Application built, security scanned, deployed and verified successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }

        always {
            echo 'CI/CD pipeline execution finished.'
        }
    }
}
