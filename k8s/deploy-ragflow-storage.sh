#!/bin/bash

# RAGFlow本地存储部署脚本
# 专门为带有 ragflow=true 标签的节点部署本地存储

set -e

echo "=== 部署RAGFlow本地存储 ==="

# 1. 检查是否有ragflow=true标签的节点
echo "检查ragflow=true标签的节点..."
RAGFLOW_NODES=$(kubectl get nodes -l ragflow=true -o jsonpath='{.items[*].metadata.name}')
if [ -z "$RAGFLOW_NODES" ]; then
    echo "错误: 没有找到带有 ragflow=true 标签的节点"
    echo "请先为节点添加标签: kubectl label nodes <node-name> ragflow=true"
    exit 1
fi
echo "发现RAGFlow节点: $RAGFLOW_NODES"

# 2. 确保ragflow命名空间存在
echo "确保ragflow命名空间存在..."
kubectl apply -f k8s/namespace.yaml

# 3. 部署简化的本地存储配置
echo "部署本地存储配置..."
kubectl apply -f k8s/simple-local-storage.yaml

# 4. 在RAGFlow节点上创建存储目录
echo "在RAGFlow节点上创建存储目录..."
for node in $RAGFLOW_NODES; do
    echo "在节点 $node 上创建目录..."
    
    # 使用kubectl debug创建目录
    kubectl debug node/$node -it --image=busybox -- chroot /host mkdir -p /mnt/ragflow/{mysql-pvc,minio-pvc,redis-pvc,elasticsearch-pvc,infinity-pvc,opensearch-pvc,ragflow-logs-pvc}
    
    # 设置权限
    kubectl debug node/$node -it --image=busybox -- chroot /host chmod 777 /mnt/ragflow/*
    
    echo "节点 $node 目录创建完成"
done

# 5. 验证部署
echo "验证PV创建..."

# 6. 验证部署
echo "验证部署..."
echo "=== StorageClass ==="
kubectl get storageclass ragflow-local-storage

echo "=== PersistentVolumes ==="
kubectl get pv

echo "=== PersistentVolumes ==="
kubectl get pv

echo "=== RAGFlow节点状态 ==="
kubectl get nodes -l ragflow=true

echo "=== RAGFlow本地存储部署完成 ==="
echo "现在可以部署PVC: kubectl apply -f k8s/storage.yaml"
echo "然后部署RAGFlow应用: kubectl apply -f k8s/ragflow.yaml"
