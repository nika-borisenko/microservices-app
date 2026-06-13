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
                                # ИСПРАВЛЕНО: Пробрасываем на порт 5001 хоста, чтобы избежать конфликтов
                                docker run -d --name test-user -p 5001:5000 ${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}
                                echo "Waiting for User Service to start..."
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
                                # ИСПРАВЛЕНО: Пробрасываем на порт 3001 хоста, чтобы избежать конфликтов
                                docker run -d --name test-order -p 3001:3000 ${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}
                                echo "Waiting for Order Service to start..."
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
                        # ИСПРАВЛЕНО: Используем 'docker compose' (через пробел) вместо 'docker-compose'
                        docker compose down || true
                        docker compose up -d --build
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Все микросервисы успешно развернуты!'
        }
        failure {
            echo 'Ошибка в одном из сервисов! Проверьте логи выше.'
            # ИСПРАВЛЕНО: Используем 'docker compose' (через пробел)
            sh 'docker compose down || true'
            sh 'docker rm -f test-user test-order || true'
        }
    }
}