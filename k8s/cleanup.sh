#!/bin/bash

set -e

echo "开始清理 RAGFlow 部署..."

# 删除 Ingress
echo "1. 删除 Ingress..."
kubectl delete -f ingress.yaml --ignore-not-found=true

# 删除 RAGFlow
echo "2. 删除 RAGFlow..."
kubectl delete -f ragflow.yaml --ignore-not-found=true

# 删除 Elasticsearch
echo "3. 删除 Elasticsearch..."
kubectl delete -f elasticsearch.yaml --ignore-not-found=true

# 删除 MinIO
echo "4. 删除 MinIO..."
kubectl delete -f minio.yaml --ignore-not-found=true

# 删除 Redis
echo "5. 删除 Redis..."
kubectl delete -f redis.yaml --ignore-not-found=true

# 删除 MySQL
echo "6. 删除 MySQL..."
kubectl delete -f mysql.yaml --ignore-not-found=true

# 删除持久化存储
echo "7. 删除持久化存储..."
kubectl delete -f storage.yaml --ignore-not-found=true

# 删除 ConfigMap
echo "8. 删除 ConfigMap..."
kubectl delete -f configmap.yaml --ignore-not-found=true

# 删除命名空间
echo "9. 删除命名空间..."
kubectl delete -f namespace.yaml --ignore-not-found=true

echo "清理完成！"
echo ""
echo "注意：持久化数据可能仍然存在于存储中，如需完全清理请手动删除相关 PVC 和 PV"
