# RAGFlow Kubernetes 部署指南

## 概述

本指南介绍如何在Kubernetes集群中部署RAGFlow，使用本地存储作为持久化存储。

## 架构

- **命名空间**: `ragflow`
- **存储类型**: 本地存储 (Local Storage)
- **节点选择**: 使用 `ragflow=true` 标签选择节点
- **存储路径**: `/mnt/ragflow/`

## 文件结构

```
k8s/
├── namespace.yaml              # 命名空间定义
├── simple-local-storage.yaml   # 静态PV配置
├── storage.yaml               # PVC配置
├── configmap.yaml             # 应用配置
├── mysql.yaml                 # MySQL服务
├── redis.yaml                 # Redis服务
├── elasticsearch.yaml         # Elasticsearch服务
├── opensearch.yaml            # OpenSearch服务
├── minio.yaml                 # MinIO服务
├── infinity.yaml              # Infinity服务
├── kibana.yaml                # Kibana服务
├── ragflow.yaml               # RAGFlow主应用
├── ingress.yaml               # Ingress配置
├── deploy-ragflow-storage.sh  # 存储部署脚本
└── test-static-pv.sh          # 测试脚本
```

## 部署步骤

### 1. 准备节点

为运行RAGFlow的节点添加标签：

```bash
kubectl label nodes <node-name> ragflow=true
```

### 2. 部署存储

运行存储部署脚本：

```bash
./k8s/deploy-ragflow-storage.sh
```

或者使用测试脚本（包含详细验证）：

```bash
./k8s/test-static-pv.sh
```

### 3. 部署应用

按顺序部署各个组件：

```bash
# 基础服务
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/elasticsearch.yaml
kubectl apply -f k8s/opensearch.yaml
kubectl apply -f k8s/minio.yaml
kubectl apply -f k8s/infinity.yaml
kubectl apply -f k8s/kibana.yaml

# 主应用
kubectl apply -f k8s/ragflow.yaml

# 可选：Ingress
kubectl apply -f k8s/ingress.yaml
```

## 验证部署

### 检查存储状态

```bash
# 检查StorageClass
kubectl get storageclass

# 检查PV
kubectl get pv

# 检查PVC
kubectl get pvc -n ragflow
```

### 检查服务状态

```bash
# 检查所有Pod
kubectl get pods -n ragflow

# 检查服务
kubectl get svc -n ragflow

# 检查部署
kubectl get deployments -n ragflow
```

### 检查日志

```bash
# 检查RAGFlow日志
kubectl logs -n ragflow deployment/ragflow

# 检查MySQL日志
kubectl logs -n ragflow deployment/mysql
```

## 存储配置

### 本地存储路径

```
/mnt/ragflow/
├── mysql-pvc/           # MySQL数据
├── minio-pvc/           # MinIO对象存储
├── redis-pvc/           # Redis数据
├── elasticsearch-pvc/   # Elasticsearch数据
├── infinity-pvc/        # Infinity向量数据库
├── opensearch-pvc/      # OpenSearch数据
└── ragflow-logs-pvc/    # RAGFlow日志
```

### PV配置

- **存储类**: `ragflow-local-storage`
- **访问模式**: `ReadWriteOnce`
- **节点亲和性**: `ragflow=true`
- **回收策略**: `Retain`

## 故障排除

### 常见问题

1. **PVC无法绑定**
   - 检查节点标签是否正确
   - 检查本地目录是否存在
   - 检查PV状态

2. **Pod无法调度**
   - 检查节点资源是否充足
   - 检查节点标签是否正确
   - 检查污点容忍度

3. **存储权限问题**
   - 检查目录权限 (777)
   - 检查SELinux设置

### 调试命令

```bash
# 检查节点状态
kubectl describe nodes -l ragflow=true

# 检查Pod事件
kubectl describe pod <pod-name> -n ragflow

# 检查PVC详情
kubectl describe pvc <pvc-name> -n ragflow

# 检查PV详情
kubectl describe pv <pv-name>
```

## 清理

### 删除应用

```bash
kubectl delete -f k8s/ragflow.yaml
kubectl delete -f k8s/mysql.yaml
kubectl delete -f k8s/redis.yaml
# ... 删除其他组件
```

### 删除存储

```bash
kubectl delete -f k8s/storage.yaml
kubectl delete -f k8s/simple-local-storage.yaml
```

### 删除命名空间

```bash
kubectl delete namespace ragflow
```

## 注意事项

1. **数据持久性**: 删除PV不会删除本地数据，需要手动清理
2. **节点迁移**: 本地存储绑定到特定节点，迁移时需要重新配置
3. **备份**: 建议定期备份本地存储数据
4. **监控**: 监控本地存储空间使用情况
