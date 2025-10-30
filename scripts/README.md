# 📜 部署脚本说明

本目录包含 Jimeng API 的部署和管理脚本。

## 📁 文件列表

| 文件 | 用途 | 执行方式 |
|-----|------|---------|
| **deploy.sh** | 一键部署脚本 | `sudo bash deploy.sh` |
| **manage.sh** | 服务管理脚本 | `bash manage.sh [命令]` |
| **nginx-config-template.conf** | Nginx 配置模板 | 复制到 `/etc/nginx/sites-available/` |

---

## 🚀 deploy.sh - 一键部署脚本

### 功能

自动完成以下操作：
- ✅ 更新系统软件包
- ✅ 安装 Docker 和 Docker Compose
- ✅ 安装 Nginx
- ✅ 安装 Certbot（HTTPS 证书）
- ✅ 配置防火墙（UFW）
- ✅ 克隆/部署项目
- ✅ 配置 Nginx 反向代理
- ✅ 申请 HTTPS 证书

### 使用方法

```bash
# 1. 进入项目目录
cd /opt/jimeng-api

# 2. 赋予执行权限
chmod +x scripts/deploy.sh

# 3. 以 root 权限运行
sudo bash scripts/deploy.sh
```

### 运行流程

1. 检查系统环境
2. 更新系统
3. 安装必要软件
4. 配置防火墙
5. 部署项目
6. 询问是否配置域名
7. 询问是否申请 HTTPS 证书
8. 显示部署信息

### 注意事项

- **必须使用 root 权限**
- **适用于 Ubuntu/Debian 系统**
- **执行时间约 10-15 分钟**
- **需要稳定的网络连接**

---

## 🛠️ manage.sh - 服务管理脚本

### 功能

提供便捷的服务管理命令。

### 可用命令

| 命令 | 功能 | 示例 |
|-----|------|------|
| `start` | 启动服务 | `bash manage.sh start` |
| `stop` | 停止服务 | `bash manage.sh stop` |
| `restart` | 重启服务 | `bash manage.sh restart` |
| `logs` | 查看日志 | `bash manage.sh logs` |
| `status` | 查看状态 | `bash manage.sh status` |
| `update` | 更新服务 | `bash manage.sh update` |
| `clean` | 清理日志 | `bash manage.sh clean` |
| `backup` | 备份配置 | `bash manage.sh backup` |
| `env` | 查看环境 | `bash manage.sh env` |
| `test` | 测试服务 | `bash manage.sh test` |
| `help` | 显示帮助 | `bash manage.sh help` |

### 使用示例

```bash
# 启动服务
bash /opt/jimeng-api/scripts/manage.sh start

# 查看实时日志
bash /opt/jimeng-api/scripts/manage.sh logs

# 更新服务
bash /opt/jimeng-api/scripts/manage.sh update

# 备份配置
bash /opt/jimeng-api/scripts/manage.sh backup
```

### 别名设置（可选）

为了更方便使用，可以设置别名：

```bash
# 编辑 ~/.bashrc
nano ~/.bashrc

# 添加以下行
alias jimeng='bash /opt/jimeng-api/scripts/manage.sh'

# 重新加载配置
source ~/.bashrc

# 现在可以直接使用
jimeng start
jimeng logs
jimeng status
```

---

## 📄 nginx-config-template.conf - Nginx 配置模板

### 功能

提供 Nginx 反向代理配置模板。

### 使用方法

```bash
# 1. 复制到 Nginx 配置目录
sudo cp scripts/nginx-config-template.conf /etc/nginx/sites-available/jimeng-api

# 2. 编辑配置文件
sudo nano /etc/nginx/sites-available/jimeng-api

# 3. 修改 server_name 为您的域名
# server_name api.yourdomain.com;

# 4. 创建软链接
sudo ln -s /etc/nginx/sites-available/jimeng-api /etc/nginx/sites-enabled/

# 5. 测试配置
sudo nginx -t

# 6. 重启 Nginx
sudo systemctl reload nginx
```

### 配置特点

- ✅ 支持长轮询（900秒超时）
- ✅ 支持大文件上传（100MB）
- ✅ 支持 WebSocket
- ✅ 详细的日志记录
- ✅ 健康检查端点
- ✅ 静态文件缓存

---

## 🔐 权限设置

在 Linux 系统中，建议设置正确的权限：

```bash
# 设置脚本可执行权限
chmod +x scripts/deploy.sh
chmod +x scripts/manage.sh

# 设置配置文件只读权限
chmod 644 scripts/nginx-config-template.conf
```

---

## 📊 目录结构

```
scripts/
├── deploy.sh                     # 一键部署脚本
├── manage.sh                     # 服务管理脚本
├── nginx-config-template.conf    # Nginx 配置模板
└── README.md                     # 本文件
```

---

## ⚠️ 注意事项

### deploy.sh

1. **仅在全新服务器或首次部署时使用**
2. **会修改系统配置**（防火墙、Nginx 等）
3. **确保有 root 权限**
4. **建议在测试环境先验证**

### manage.sh

1. **默认项目目录为 `/opt/jimeng-api`**
2. **可修改脚本中的 `PROJECT_DIR` 变量**
3. **某些命令需要 sudo 权限**

### nginx-config-template.conf

1. **必须修改 `server_name`**
2. **确保端口 5100 可访问**
3. **HTTPS 配置由 Certbot 自动完成**

---

## 🔄 更新脚本

如果脚本有更新，拉取最新代码后重新赋予执行权限：

```bash
cd /opt/jimeng-api
git pull
chmod +x scripts/*.sh
```

---

## 🐛 故障排查

### deploy.sh 执行失败

```bash
# 查看详细错误
sudo bash -x scripts/deploy.sh

# 检查系统版本
cat /etc/os-release

# 检查网络连接
ping -c 4 google.com
```

### manage.sh 命令无效

```bash
# 检查项目目录
ls -la /opt/jimeng-api

# 检查 Docker
docker --version
docker compose version

# 检查容器状态
docker ps -a
```

---

## 📞 获取帮助

- **详细部署文档**: [DEPLOY.md](../DEPLOY.md)
- **快速开始**: [QUICKSTART.md](../QUICKSTART.md)
- **项目主页**: [README.md](../README.md)

---

## 🎯 最佳实践

1. **定期备份配置**
   ```bash
   bash manage.sh backup
   ```

2. **监控服务状态**
   ```bash
   bash manage.sh status
   ```

3. **定期更新服务**
   ```bash
   bash manage.sh update
   ```

4. **查看日志排查问题**
   ```bash
   bash manage.sh logs
   ```

---

有任何问题，欢迎提交 Issue 或查看详细文档！
