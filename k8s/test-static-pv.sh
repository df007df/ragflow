#!/bin/bash

# 测试静态PV配置脚本

set -e

echo "=== 测试RAGFlow静态PV配置 ==="

# 1. 检查节点标签
echo "1. 检查ragflow=true标签的节点..."
RAGFLOW_NODES=$(kubectl get nodes -l ragflow=true -o jsonpath='{.items[*].metadata.name}')
if [ -z "$RAGFLOW_NODES" ]; then
    echo "❌ 错误: 没有找到带有 ragflow=true 标签的节点"
    echo "请先为节点添加标签: kubectl label nodes <node-name> ragflow=true"
    exit 1
fi
echo "✅ 发现RAGFlow节点: $RAGFLOW_NODES"

# 2. 部署命名空间
echo "2. 创建ragflow命名空间..."
kubectl apply -f k8s/namespace.yaml

# 3. 部署静态PV
echo "3. 部署静态PV配置..."
kubectl apply -f k8s/simple-local-storage.yaml

# 4. 检查StorageClass
echo "4. 检查StorageClass..."
kubectl get storageclass ragflow-local-storage

# 5. 检查PV状态
echo "5. 检查PV状态..."
kubectl get pv -l type=local-storage

# 6. 创建存储目录
echo "6. 在节点上创建存储目录..."
for node in $RAGFLOW_NODES; do
    echo "在节点 $node 上创建目录..."
    kubectl debug node/$node -it --image=busybox -- chroot /host mkdir -p /mnt/ragflow/{mysql-pvc,minio-pvc,redis-pvc,elasticsearch-pvc,infinity-pvc,opensearch-pvc,ragflow-logs-pvc}
    kubectl debug node/$node -it --image=busybox -- chroot /host chmod 777 /mnt/ragflow/*
    echo "✅ 节点 $node 目录创建完成"
done

# 7. 部署PVC
echo "7. 部署PVC..."
kubectl apply -f k8s/storage.yaml

# 8. 等待PVC绑定
echo "8. 等待PVC绑定..."
sleep 10

# 9. 检查PVC状态
echo "9. 检查PVC绑定状态..."
kubectl get pvc -n ragflow

# 10. 验证绑定
echo "10. 验证PV和PVC绑定..."
echo "=== PV状态 ==="
kubectl get pv -o wide

echo "=== PVC状态 ==="
kubectl get pvc -n ragflow -o wide

echo "=== 测试完成 ==="
echo "如果所有PVC都显示为Bound状态，说明静态PV配置成功！"
