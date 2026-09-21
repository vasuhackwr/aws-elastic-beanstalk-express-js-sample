pipeline {
    agent any

    environment {
        IMAGE_NAME = 'secure-devops-app'
        CONTAINER_NAME = 'secure-devops-app'
        APP_PORT = '8080'
        HOST_PORT = '8081'

        // Node 16 Docker image required by the assessment
        NODE_IMAGE = 'node:16'
    }

    options {
        // Keep the most recent 10 builds
        buildDiscarder(logRotator(
            numToKeepStr: '10',
            artifactNumToKeepStr: '5'
        ))

        // Add timestamps to Jenkins console output
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Node 16 - Install Dependencies') {
            steps {
                echo 'Installing dependencies using Node 16 Docker image...'

                sh '''
                    docker run --rm \
                    -v "$PWD:/app" \
                    -w /app \
                    ${NODE_IMAGE} \
                    npm ci
                '''
            }
        }

        stage('Dependency Security Scan') {
            steps {
                echo 'Scanning dependencies for HIGH and CRITICAL vulnerabilities using Node 16...'

                sh '''
                    docker run --rm \
                    -v "$PWD:/app" \
                    -w /app \
                    ${NODE_IMAGE} \
                    npm audit --audit-level=high
                '''
            }
        }

        stage('Unit Test') {
            steps {
                echo 'Running automated Jest unit tests using Node 16...'

                sh '''
                    docker run --rm \
                    -v "$PWD:/app" \
                    -w /app \
                    ${NODE_IMAGE} \
                    npm test
                '''
            }
        }

        stage('Create Audit Artifact') {
            steps {
                echo 'Creating npm security audit report...'

                sh '''
                    docker run --rm \
                    -v "$PWD:/app" \
                    -w /app \
                    ${NODE_IMAGE} \
                    sh -c "npm audit --json > npm-audit.json || true"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building hardened Docker image...'

                sh '''
                    docker build --no-cache \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest \
                    .
                '''
            }
        }

        stage('Container Security Scan') {
            steps {
                echo 'Running Trivy container security scan...'
                echo 'Pipeline will fail if HIGH or CRITICAL vulnerabilities are detected.'

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
                echo 'Security gates passed. Deploying application...'

                sh '''
                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${APP_PORT} \
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
            echo 'Unit tests and security gates passed.'
            echo 'Application deployed and verified successfully.'
        }

        failure {
            echo 'Pipeline failed.'
            echo 'A build, test, security, deployment, or verification stage failed.'
            echo 'Check the Jenkins console output for details.'
        }

        always {
            echo 'Archiving CI/CD security artifacts...'

            archiveArtifacts(
                artifacts: 'npm-audit.json',
                allowEmptyArchive: true,
                fingerprint: true
            )

            echo 'CI/CD pipeline execution finished.'
        }
    }
}