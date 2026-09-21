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

        stage('Security Scan') {
            steps {
                echo 'Scanning dependencies for High/Critical vulnerabilities...'
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
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }

        always {
            echo 'CI/CD pipeline execution finished.'
        }
    }
}
