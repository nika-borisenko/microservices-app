pipeline {
    agent any
    environment {
        DOCKER_HUB_USER = 'nika16'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/nika-borisenko/microservices-app.git'
            }
        }
        stage('Build Services') {
            parallel {
                stage('Build User Service') {
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}", "./user-service")
                        }
                    }
                }
                stage('Build Order Service') {
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}", "./order-service")
                        }
                    }
                }
                stage('Build Gateway') {
                    steps {
                        script {
                            docker.build("${DOCKER_HUB_USER}/gateway:${BUILD_NUMBER}", "./gateway")
                        }
                    }
                }
            }
        }
        stage('Test Services') {
            parallel {
                stage('Test User Service') {
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
        stage('Push Images') {
            parallel {
                stage('Push User Service') {
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