#!/bin/bash

# MySQL存储修复脚本
set -e

echo "=== RAGFlow MySQL存储修复脚本 ==="

# 检查节点标签
echo "1. 检查节点标签..."
NODES=$(kubectl get nodes --show-labels | grep ragflow=true | awk '{print $1}')
if [ -z "$NODES" ]; then
    echo "错误: 没有找到带有 ragflow=true 标签的节点"
    echo "请运行以下命令为节点添加标签:"
    echo "kubectl label nodes <your-node-name> ragflow=true"
    exit 1
fi

NODE_NAME=$(echo "$NODES" | head -1)
echo "使用节点: $NODE_NAME"

# 检查存储目录
echo "2. 检查存储目录..."
STORAGE_PATH="/mnt/ragflow/mysql-pvc"
echo "检查路径: $STORAGE_PATH"

# 在节点上执行命令
echo "3. 在节点上创建存储目录..."
kubectl debug node/$NODE_NAME -it --image=busybox -- chroot /host /bin/sh -c "
set -e
echo '创建存储目录...'
mkdir -p $STORAGE_PATH
echo '设置目录权限...'
chown -R 999:999 $STORAGE_PATH
chmod -R 750 $STORAGE_PATH
echo '检查目录状态:'
ls -la $STORAGE_PATH
echo '存储目录准备完成'
"

# 删除现有的PVC和PV
echo "4. 清理现有的存储资源..."
kubectl delete pvc mysql-pvc -n ragflow --ignore-not-found=true
kubectl delete pv mysql-pv --ignore-not-found=true

# 重新创建PV
echo "5. 重新创建PersistentVolume..."
kubectl apply -f simple-local-storage.yaml

# 重新创建PVC
echo "6. 重新创建PersistentVolumeClaim..."
kubectl apply -f storage.yaml

# 等待PVC绑定
echo "7. 等待PVC绑定..."
kubectl wait --for=condition=Bound pvc/mysql-pvc -n ragflow --timeout=60s

# 重启MySQL部署
echo "8. 重启MySQL部署..."
kubectl rollout restart deployment/mysql -n ragflow

# 等待部署就绪
echo "9. 等待MySQL部署就绪..."
kubectl rollout status deployment/mysql -n ragflow --timeout=300s

echo "=== 修复完成 ==="
echo "检查MySQL状态:"
kubectl get pods -n ragflow -l app=mysql
echo ""
echo "查看MySQL日志:"
kubectl logs -n ragflow -l app=mysql --tail=50
