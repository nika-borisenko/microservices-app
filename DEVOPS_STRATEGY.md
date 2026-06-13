# Стратегия интеграции Agile и DevOps: Microservices App

## 1. Контекст проекта
- **Цель:** Ускорить доставку фич за счет независимого развертывания микросервисов и снижения времени CI.
- **Команда:** тока я.
- **Стек:** Python (Flask), Node.js (Express), Nginx, Docker, Jenkins.

## 2. Процесс разработки (Agile + DevOps)

### 2.1. Спринт-цикл
```mermaid
graph LR
    A[Планирование спринта] --> B[Разработка в ветке feature/]
    B --> C[Jenkins: Detect Changes]
    C --> D{Сервис изменен?}
    D -->|Да| E[Build & Test только этого сервиса]
    D -->|Нет| F[Пропуск сборки]
    E --> G[Quality Gate]
    G --> H[Merge в main]
    H --> I[Deploy через Docker Compose]