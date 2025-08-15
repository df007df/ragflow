#!/bin/bash

set -e

echo "=== RAGFlow 节点标签设置脚本 ==="
echo ""

# 显示当前节点
echo "当前集群节点列表："
kubectl get nodes
echo ""

# 询问用户选择节点
echo "请选择要部署 RAGFlow 的节点："
echo "1. 选择单个节点"
echo "2. 选择多个节点"
echo "3. 选择所有节点"
read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "当前节点列表："
        kubectl get nodes -o custom-columns=NAME:.metadata.name
        echo ""
        read -p "请输入节点名称: " node_name
        echo "正在为节点 $node_name 添加标签..."
        kubectl label nodes $node_name ragflow=true --overwrite
        echo "✅ 节点 $node_name 已添加 ragflow=true 标签"
        ;;
    2)
        echo ""
        echo "当前节点列表："
        kubectl get nodes -o custom-columns=NAME:.metadata.name
        echo ""
        read -p "请输入节点名称（用空格分隔多个节点）: " node_names
        for node in $node_names; do
            echo "正在为节点 $node 添加标签..."
            kubectl label nodes $node ragflow=true --overwrite
            echo "✅ 节点 $node 已添加 ragflow=true 标签"
        done
        ;;
    3)
        echo "正在为所有节点添加标签..."
        nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
        for node in $nodes; do
            echo "正在为节点 $node 添加标签..."
            kubectl label nodes $node ragflow=true --overwrite
            echo "✅ 节点 $node 已添加 ragflow=true 标签"
        done
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "=== 验证标签设置 ==="
echo "带有 ragflow=true 标签的节点："
kubectl get nodes -l ragflow=true

echo ""
echo "=== 下一步操作 ==="
echo "1. 运行 ./deploy.sh 部署 RAGFlow"
echo "2. 或者手动应用配置文件："
echo "   kubectl apply -f namespace.yaml"
echo "   kubectl apply -f configmap.yaml"
echo "   kubectl apply -f storage.yaml"
echo "   kubectl apply -f mysql.yaml"
echo "   kubectl apply -f redis.yaml"
echo "   kubectl apply -f minio.yaml"
echo "   kubectl apply -f elasticsearch.yaml"
echo "   kubectl apply -f ragflow.yaml"
echo "   kubectl apply -f ingress.yaml"
