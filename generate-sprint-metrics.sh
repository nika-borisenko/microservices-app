echo "========================================="
echo "  DevOps Metrics for Sprint Review"
echo "========================================="

echo "[Jenkins CI]"
echo "  - Статус последней сборки: $(curl -s http://localhost:8080/job/microservices-app/lastBuild/api/json 2>/dev/null | grep -o '"result":"[^"]*"' | cut -d'"' -f4 || echo "N/A")"

echo ""
echo "[Docker Infrastructure]"
IMAGE_COUNT=$(docker images --format '{{.Repository}}' | grep -c 'nika16' 2>/dev/null || echo "0")
echo "  - Локальных образов проекта: ${IMAGE_COUNT}"

USER_SIZE=$(docker images | grep user-service | grep latest | awk '{print $7}' 2>/dev/null || echo "N/A")
echo "  - Размер образа user-service (latest): ${USER_SIZE}"

echo ""
echo "[Recommendations for Next Sprint]"
echo "  1. [ ] Добавить кэширование зависимостей (pip install / npm install) в Dockerfile"
echo "  2. [ ] Внедрить автоматические интеграционные тесты между сервисами"
echo "  3. [ ] Настроить автоматические откаты при провале health-check"