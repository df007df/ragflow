#!/bin/bash

# MySQL诊断脚本
echo "=== RAGFlow MySQL诊断脚本 ==="

echo "1. 检查命名空间..."
kubectl get namespace ragflow

echo ""
echo "2. 检查MySQL Pod状态..."
kubectl get pods -n ragflow -l app=mysql

echo ""
echo "3. 检查PVC状态..."
kubectl get pvc -n ragflow

echo ""
echo "4. 检查PV状态..."
kubectl get pv | grep mysql

echo ""
echo "5. 检查节点标签..."
kubectl get nodes --show-labels | grep ragflow

echo ""
echo "6. 检查MySQL Pod事件..."
kubectl get events -n ragflow --sort-by='.lastTimestamp' | grep mysql

echo ""
echo "7. 检查MySQL日志..."
MYSQL_POD=$(kubectl get pods -n ragflow -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$MYSQL_POD" ]; then
    echo "MySQL Pod: $MYSQL_POD"
    kubectl logs -n ragflow $MYSQL_POD --tail=20
else
    echo "未找到MySQL Pod"
fi

echo ""
echo "8. 检查存储类..."
kubectl get storageclass

echo ""
echo "=== 诊断完成 ==="
