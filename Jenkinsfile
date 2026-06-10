pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USER = 'nika16'
        DOCKER_CREDENTIALS_ID = 'docker-hub'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/nika-borisenko/microservices-app'
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
            steps {
                sh '''
                    # Удаляем старые тестовые контейнеры, если они остались
                    docker rm -f test-user test-order || true
                    
                    echo "=== Testing User Service ==="
                    docker run -d --name test-user -p 5000:5000 ${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}
                    sleep 5
                    curl -f http://localhost:5000/health || exit 1
                    docker rm -f test-user
                    
                    echo "=== Testing Order Service ==="
                    # ВНИМАНИЕ: Используем порт 3001 на хосте, чтобы избежать конфликта с занятым 3000
                    docker run -d --name test-order -p 3001:3000 ${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}
                    sleep 5
                    curl -f http://localhost:3001/health || exit 1
                    docker rm -f test-order
                '''
            }
        }
        
        stage('Push Images') {
            parallel {
                stage('Push User Service') {
                     steps {
                        script {
                            def userImage = docker.image("${DOCKER_HUB_USER}/user-service:${BUILD_NUMBER}")
                            userImage.push()
                            
                            // Создаем тег latest и пушим его
                            userImage.tag('latest')
                            docker.image("${DOCKER_HUB_USER}/user-service:latest").push()
                        }
                    }
                }
                stage('Push Order Service') {
                    steps {
                        script {
                            def orderImage = docker.image("${DOCKER_HUB_USER}/order-service:${BUILD_NUMBER}")
                            orderImage.push()
                            
                            // Создаем тег latest и пушим его
                            orderImage.tag('latest')
                            docker.image("${DOCKER_HUB_USER}/order-service:latest").push()
                        }
                    }
                }
                stage('Push Gateway') {
                    steps {
                        script {
                            def gatewayImage = docker.image("${DOCKER_HUB_USER}/gateway:${BUILD_NUMBER}")
                            gatewayImage.push()
                            
                            // Создаем тег latest и пушим его
                            gatewayImage.tag('latest')
                            docker.image("${DOCKER_HUB_USER}/gateway:latest").push()
                        }
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    docker compose down || true
                    docker compose up -d
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Все микросервисы успешно развернуты!'
        }
        failure {
            echo 'Ошибка в одном из сервисов!'
            sh 'docker compose down'
        }
    }
}