#!/bin/bash

set -e

echo "开始部署 RAGFlow 到 Kubernetes..."

# 检查节点标签
echo "1. 检查节点标签..."
if ! kubectl get nodes -l ragflow=true --no-headers | grep -q .; then
    echo "⚠️  警告：没有找到带有 ragflow=true 标签的节点"
    echo "请先运行以下命令为节点添加标签："
    echo "  kubectl label nodes <node-name> ragflow=true"
    echo "或者运行："
    echo "  ./setup-node-labels.sh"
    echo ""
    read -p "是否继续部署？(y/N): " continue_deploy
    if [[ $continue_deploy != "y" && $continue_deploy != "Y" ]]; then
        echo "部署已取消"
        exit 1
    fi
else
    echo "✅ 找到带有 ragflow=true 标签的节点："
    kubectl get nodes -l ragflow=true
fi

# 创建命名空间
echo "2. 创建命名空间..."
kubectl apply -f namespace.yaml

# 创建 ConfigMap
echo "3. 创建 ConfigMap..."
kubectl apply -f configmap.yaml

# 创建持久化存储
echo "4. 创建持久化存储..."
kubectl apply -f storage.yaml

# 等待 PVC 创建完成
echo "5. 等待 PVC 创建完成..."
kubectl wait --for=condition=Bound pvc --all -n ragflow --timeout=300s

# 部署 MySQL
echo "6. 部署 MySQL..."
kubectl apply -f mysql.yaml

# 部署 Redis
echo "7. 部署 Redis..."
kubectl apply -f redis.yaml

# 部署 MinIO
echo "8. 部署 MinIO..."
kubectl apply -f minio.yaml

# 部署 Elasticsearch
echo "9. 部署 Elasticsearch..."
kubectl apply -f elasticsearch.yaml

# 等待依赖服务就绪
echo "10. 等待依赖服务就绪..."
kubectl wait --for=condition=available deployment/mysql -n ragflow --timeout=300s
kubectl wait --for=condition=available deployment/redis -n ragflow --timeout=300s
kubectl wait --for=condition=available deployment/minio -n ragflow --timeout=300s
kubectl wait --for=condition=available deployment/elasticsearch -n ragflow --timeout=600s

# 部署 RAGFlow
echo "11. 部署 RAGFlow..."
kubectl apply -f ragflow.yaml

# 部署 Ingress
echo "12. 部署 Ingress..."
kubectl apply -f ingress.yaml

# 等待 RAGFlow 就绪
echo "13. 等待 RAGFlow 就绪..."
kubectl wait --for=condition=available deployment/ragflow -n ragflow --timeout=600s

echo "部署完成！"
echo ""
echo "服务状态："
kubectl get pods -n ragflow
echo ""
echo "服务访问信息："
kubectl get svc -n ragflow
echo ""
echo "Ingress 信息："
kubectl get ingress -n ragflow
echo ""
echo "注意事项："
echo "1. 请确保您的 Kubernetes 集群已安装 Ingress Controller"
echo "2. 请根据实际情况修改 ingress.yaml 中的域名配置"
echo "3. 如果需要外部访问，请配置 LoadBalancer 或 NodePort"
echo "4. 默认用户名密码请查看 configmap.yaml 中的配置"
