pipeline {
    agent any
    environment {
        DOCKER_HUB_USER = 'nika16'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        BRANCH_STRATEGY = "${env.GIT_BRANCH == 'main' ? 'release' : 'feature'}"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/nika-borisenko/microservices-app.git'
            }
        }
        stage('Detect Changes') {
            steps {
                script {
                    env.CHANGED_USER = sh(script: "git diff --name-only HEAD~1 HEAD | grep -q '^user-service/' && echo 'true' || echo 'false'", returnStdout: true).trim()
                    env.CHANGED_ORDER = sh(script: "git diff --name-only HEAD~1 HEAD | grep -q '^order-service/' && echo 'true' || echo 'false'", returnStdout: true).trim()
                    env.CHANGED_GATEWAY = sh(script: "git diff --name-only HEAD~1 HEAD | grep -q '^gateway/' && echo 'true' || echo 'false'", returnStdout: true).trim()
                    
                    echo "Changes detected: User=${env.CHANGED_USER}, Order=${env.CHANGED_ORDER}, Gateway=${env.CHANGED_GATEWAY}"
                }
            }
        }

        stage('Build Services') {
            parallel {
                stage('Build User Service') {
                    when { expression { env.CHANGED_USER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}", "./user-service")
                        }
                    }
                }
                stage('Build Order Service') {
                    when { expression { env.CHANGED_ORDER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}", "./order-service")
                        }
                    }
                }
                stage('Build Gateway') {
                    when { expression { env.CHANGED_GATEWAY == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/gateway:${BUILD_NUMBER}", "./gateway")
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    echo "Running Quality Gate checks..."
                    def sizeStr = sh(script: "docker images ${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER} --format '{{.Size}}' || echo '0B'", returnStdout: true).trim()
                    if (sizeStr.contains('GB')) {
                        error("CRITICAL: User-service image size is too large (>1GB)! Check Dockerfile.")
                    }
                    echo "Quality Gate passed successfully."
                }
            }
        }

        stage('Test Services') {
            parallel {
                stage('Test User Service') {
                    when { expression { env.CHANGED_USER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            sh '''
                                docker rm -f test-user || true
                                docker run -d --name test-user -p 5001:5000 nika16/user-service:${BUILD_NUMBER}
                                sleep 5
                                curl -f http://localhost:5001/health || exit 1
                                docker stop test-user
                                docker rm test-user
                            '''
                        }
                    }
                }
                stage('Test Order Service') {
                    when { expression { env.CHANGED_ORDER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            sh '''
                                docker rm -f test-order || true
                                docker run -d --name test-order -p 3001:3000 nika16/order-service:${BUILD_NUMBER}
                                sleep 5
                                curl -f http://localhost:3001/health || exit 1
                                docker stop test-order
                                docker rm test-order
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Configure Feature Flags') {
            steps {
                script {
                    if (env.GIT_BRANCH =~ /^feature\/.*/) {
                        sh 'echo "FEATURE_NEW_UI=true" > .env'
                        echo "Feature Flag ENABLED for feature branch"
                    } else {
                        sh 'echo "FEATURE_NEW_UI=false" > .env'
                        echo "Feature Flag DISABLED for release branch"
                    }
                }
            }
        }

        stage('Push Images') {
            parallel {
                stage('Push User Service') {
                    when { expression { env.CHANGED_USER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS_ID) {
                                docker.image("${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}").push()
                                docker.image("${DOCKER_HUB_USER}/user-service:latest").push()
                            }
                        }
                    }
                }
                stage('Push Order Service') {
                    when { expression { env.CHANGED_ORDER == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS_ID) {
                                docker.image("${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}").push()
                                docker.image("${DOCKER_HUB_USER}/order-service:latest").push()
                            }
                        }
                    }
                }
                stage('Push Gateway') {
                    when { expression { env.CHANGED_GATEWAY == 'true' || env.GIT_BRANCH == 'main' } }
                    steps {
                        script {
                            docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS_ID) {
                                docker.image("${DOCKER_HUB_USER}/gateway:${BUILD_NUMBER}").push()
                                docker.image("${DOCKER_HUB_USER}/gateway:latest").push()
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh '''
                        docker compose down || true
                        docker compose up -d --build
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'All microservices deployed successfully!'
        }
        failure {
            echo 'Error in one of the services!'
            sh 'docker compose down || true'
            sh 'docker rm -f test-user test-order || true'
        }
    }
}