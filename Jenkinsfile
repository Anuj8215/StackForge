pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS    = 'github-credentials'
        DOCKERHUB_USER        = 'anujpawar8215'
        FRONTEND_IMAGE        = "${DOCKERHUB_USER}/stackforge-frontend"
        BACKEND_IMAGE         = "${DOCKERHUB_USER}/stackforge-backend"
        K8S_FRONTEND_DEPLOY   = 'k8s/app/frontend/deployment.yaml'
        K8S_BACKEND_DEPLOY    = 'k8s/app/backend/deployment.yaml'
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    echo "Image tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                            sh 'npm run lint'
                            sh 'npm test -- --coverage --watchAll=false'
                        }
                    }
                }
                stage('Backend Tests') {
                    environment { NODE_ENV = 'test' }
                    steps {
                        dir('backend') {
                            sh 'npm ci'
                            sh 'npm run lint'
                            sh 'npm test -- --coverage'
                        }
                    }
                }
            }
        }

        stage('Docker Build') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        sh """
                            docker build \\
                              --target production \\
                              -t ${FRONTEND_IMAGE}:${env.IMAGE_TAG} \\
                              -t ${FRONTEND_IMAGE}:latest \\
                              ./frontend
                        """
                    }
                }
                stage('Build Backend') {
                    steps {
                        sh """
                            docker build \\
                              --target production \\
                              -t ${BACKEND_IMAGE}:${env.IMAGE_TAG} \\
                              -t ${BACKEND_IMAGE}:latest \\
                              ./backend
                        """
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${FRONTEND_IMAGE}:${env.IMAGE_TAG}"
                sh "docker push ${FRONTEND_IMAGE}:latest"
                sh "docker push ${BACKEND_IMAGE}:${env.IMAGE_TAG}"
                sh "docker push ${BACKEND_IMAGE}:latest"
            }
        }

        stage('Update K8s Image Tags') {
            steps {
                sh """
                    sed -i 's|image: ${FRONTEND_IMAGE}:.*|image: ${FRONTEND_IMAGE}:${env.IMAGE_TAG}|g' ${K8S_FRONTEND_DEPLOY}
                    sed -i 's|image: ${BACKEND_IMAGE}:.*|image: ${BACKEND_IMAGE}:${env.IMAGE_TAG}|g' ${K8S_BACKEND_DEPLOY}
                    echo "Updated image tags to ${env.IMAGE_TAG}"
                """
            }
        }

        stage('Git Push Config') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: env.GITHUB_CREDENTIALS,
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins@stackforge.io"
                        git config user.name "Jenkins CD"
                        git add ${K8S_FRONTEND_DEPLOY} ${K8S_BACKEND_DEPLOY}
                        git commit -m "COMMIT : UPDATE IMAGE TAG TO ${env.IMAGE_TAG}"
                        git push https://\${GIT_USER}:\${GIT_TOKEN}@github.com/Anuj8215/StackForge.git HEAD:main
                    """
                }
            }
        }

        stage('Load Test Gate') {
            steps {
                sh 'bash load-test/run-load-test.sh'
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()
        }
        success {
            echo "Pipeline SUCCESS - images pushed with tag ${env.IMAGE_TAG}"
        }
        failure {
            echo "Pipeline FAILED - check stage logs above"
        }
    }
}
