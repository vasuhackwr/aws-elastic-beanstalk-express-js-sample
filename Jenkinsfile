pipeline {
    agent any

    environment {
        IMAGE_NAME = 'secure-devops-app'
        DOCKERHUB_IMAGE = 'vasu1257/secure-devops-app'

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
                echo 'Scanning dependencies for HIGH and CRITICAL vulnerabilities...'

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

        stage('Tag Docker Image') {
            steps {
                echo 'Tagging security-approved image for Docker Hub...'

                sh '''
                    docker tag \
                    ${IMAGE_NAME}:latest \
                    ${DOCKERHUB_IMAGE}:${BUILD_NUMBER}

                    docker tag \
                    ${IMAGE_NAME}:latest \
                    ${DOCKERHUB_IMAGE}:latest
                '''
            }
        }

        stage('Publish to Docker Hub') {
            steps {
                echo 'Publishing security-approved Docker image to Docker Hub...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | \
                        docker login \
                        -u "$DOCKERHUB_USERNAME" \
                        --password-stdin

                        docker push ${DOCKERHUB_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKERHUB_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Security gates passed and image published.'
                echo 'Deploying application...'

                sh '''
                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${APP_PORT} \
                    ${DOCKERHUB_IMAGE}:${BUILD_NUMBER}
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
            echo 'Unit tests passed.'
            echo 'Dependency and container security gates passed.'
            echo 'Docker image published to Docker Hub.'
            echo 'Application deployed and verified successfully.'
        }

        failure {
            echo 'Pipeline failed.'
            echo 'A build, test, security, publication, deployment, or verification stage failed.'
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