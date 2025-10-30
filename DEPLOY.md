# 📦 Jimeng API 服务器部署指南

本指南将帮助您在 Ubuntu/Debian 服务器上完整部署 Jimeng API 服务。

## 📋 目录

- [环境要求](#环境要求)
- [快速部署](#快速部署)
- [手动部署](#手动部署)
- [配置 Session ID](#配置-session-id)
- [域名和 HTTPS 配置](#域名和-https-配置)
- [服务管理](#服务管理)
- [故障排查](#故障排查)
- [性能优化](#性能优化)

---

## 🔧 环境要求

### 服务器配置建议

| 配置项 | 最低要求 | 推荐配置 |
|--------|---------|---------|
| **CPU** | 1核 | 2核+ |
| **内存** | 1GB | 2GB+ |
| **硬盘** | 10GB | 20GB+ |
| **系统** | Ubuntu 20.04 / Debian 10 | Ubuntu 22.04 / Debian 11 |
| **带宽** | 1Mbps | 5Mbps+ |

### 软件要求

- Docker 20.10+
- Docker Compose 2.0+
- Nginx 1.18+
- Certbot（用于 HTTPS）

---

## 🚀 快速部署（一键脚本）

### 方式一：使用一键部署脚本

```bash
# 1. SSH 登录服务器
ssh root@your-server-ip

# 2. 克隆项目（或上传项目文件）
git clone https://github.com/your-repo/jimeng-api.git
cd jimeng-api

# 3. 赋予脚本执行权限
chmod +x scripts/deploy.sh

# 4. 运行部署脚本
sudo bash scripts/deploy.sh
```

脚本将自动完成：
- ✅ 更新系统软件包
- ✅ 安装 Docker 和 Docker Compose
- ✅ 安装 Nginx
- ✅ 安装 Certbot
- ✅ 配置防火墙
- ✅ 部署项目
- ✅ 配置域名和 HTTPS（可选）

**预计时间**：约 10-15 分钟

---

## 📝 手动部署

如果您希望手动控制每一步，请按照以下步骤操作。

### 步骤 1: 更新系统

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git ufw
```

### 步骤 2: 安装 Docker

```bash
# 使用官方脚本安装 Docker
curl -fsSL https://get.docker.com | sh

# 启动 Docker
sudo systemctl enable docker
sudo systemctl start docker

# 验证安装
docker --version
```

### 步骤 3: 安装 Docker Compose

```bash
# 安装 Docker Compose 插件
sudo apt-get install -y docker-compose-plugin

# 验证安装
docker compose version
```

### 步骤 4: 安装 Nginx

```bash
# 安装 Nginx
sudo apt-get install -y nginx

# 启动 Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# 验证安装
nginx -v
```

### 步骤 5: 安装 Certbot（用于 HTTPS）

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 验证安装
certbot --version
```

### 步骤 6: 克隆项目

```bash
# 创建项目目录
sudo mkdir -p /opt/jimeng-api

# 克隆项目
cd /opt
sudo git clone https://github.com/your-repo/jimeng-api.git

# 或者上传项目文件
# scp -r ./jimeng-api root@your-server-ip:/opt/
```

### 步骤 7: 构建并启动服务

```bash
cd /opt/jimeng-api

# 构建 Docker 镜像
sudo docker compose build

# 启动服务
sudo docker compose up -d

# 查看状态
sudo docker compose ps
```

### 步骤 8: 配置防火墙

```bash
# 启用 UFW
sudo ufw --force enable

# 允许 SSH、HTTP、HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 拒绝外部访问应用端口（仅内网）
sudo ufw deny 5100/tcp

# 重启防火墙
sudo ufw reload

# 查看状态
sudo ufw status
```

---

## 🔑 配置 Session ID

### 获取 Session ID

#### 国内站（jimeng.jianying.com）

1. 访问 https://jimeng.jianying.com
2. 登录账号
3. 打开浏览器开发者工具（F12）
4. 切换到 **Network** 标签
5. 刷新页面
6. 找到任意请求，查看 **Request Headers**
7. 在 **Cookie** 字段中找到 `sessionid` 的值
8. 复制该值

#### 国际站（dreamina.capcut.com）

1. 访问 https://dreamina.capcut.com
2. 按照上述步骤获取 `sessionid`
3. **重要**：国际站需要在 token 前添加 `us-` 前缀

### 配置多个 Session ID（轮询）

```bash
# 编辑环境变量（如果项目支持）
cd /opt/jimeng-api
sudo nano .env
```

添加以下内容：

```env
# 单个国内站 token
JIMENG_SESSION_IDS=your_session_id

# 多个国内站 token（轮询）
JIMENG_SESSION_IDS=token1,token2,token3

# 单个国际站 token
JIMENG_SESSION_IDS=us-your_session_id

# 多个国际站 token（轮询）
JIMENG_SESSION_IDS=us-token1,us-token2

# 混合使用（推荐）
JIMENG_SESSION_IDS=cn_token1,cn_token2,us-us_token1,us-us_token2
```

**重启服务使配置生效**：

```bash
sudo docker compose restart
```

---

## 🌐 域名和 HTTPS 配置

### 步骤 1: 配置 DNS

在您的域名服务商添加 A 记录：

```
类型: A
主机: api（或 @）
值: 您的服务器 IP
TTL: 600
```

等待 DNS 生效（通常 5-30 分钟）。

### 步骤 2: 配置 Nginx 反向代理

```bash
# 使用项目提供的模板
sudo cp /opt/jimeng-api/scripts/nginx-config-template.conf /etc/nginx/sites-available/jimeng-api

# 编辑配置文件
sudo nano /etc/nginx/sites-available/jimeng-api
```

修改 `server_name` 为您的域名：

```nginx
server_name api.yourdomain.com;
```

启用站点：

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/jimeng-api /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl reload nginx
```

### 步骤 3: 申请 HTTPS 证书

```bash
# 使用 Certbot 自动申请和配置
sudo certbot --nginx -d api.yourdomain.com

# 按照提示操作：
# 1. 输入邮箱（可选）
# 2. 同意服务条款（Y）
# 3. 选择是否重定向 HTTP 到 HTTPS（推荐选择 2）
```

**测试证书自动续期**：

```bash
sudo certbot renew --dry-run
```

---

## 🛠️ 服务管理

### 使用管理脚本

项目提供了便捷的管理脚本：

```bash
# 赋予执行权限
chmod +x /opt/jimeng-api/scripts/manage.sh

# 启动服务
sudo bash /opt/jimeng-api/scripts/manage.sh start

# 停止服务
sudo bash /opt/jimeng-api/scripts/manage.sh stop

# 重启服务
sudo bash /opt/jimeng-api/scripts/manage.sh restart

# 查看日志
sudo bash /opt/jimeng-api/scripts/manage.sh logs

# 查看状态
sudo bash /opt/jimeng-api/scripts/manage.sh status

# 更新服务
sudo bash /opt/jimeng-api/scripts/manage.sh update

# 清理日志
sudo bash /opt/jimeng-api/scripts/manage.sh clean

# 备份配置
sudo bash /opt/jimeng-api/scripts/manage.sh backup

# 测试服务
sudo bash /opt/jimeng-api/scripts/manage.sh test
```

### 使用 Docker Compose 命令

```bash
cd /opt/jimeng-api

# 查看容器状态
sudo docker compose ps

# 查看日志
sudo docker compose logs -f

# 重启服务
sudo docker compose restart

# 停止服务
sudo docker compose down

# 启动服务
sudo docker compose up -d

# 重新构建
sudo docker compose build --no-cache
sudo docker compose up -d
```

---

## 🔍 故障排查

### 1. 服务无法启动

```bash
# 查看容器日志
cd /opt/jimeng-api
sudo docker compose logs

# 查看容器状态
sudo docker compose ps

# 检查端口占用
sudo netstat -tulpn | grep 5100

# 重新构建
sudo docker compose down
sudo docker compose build --no-cache
sudo docker compose up -d
```

### 2. 无法访问服务

```bash
# 检查服务是否运行
curl http://localhost:5100/ping

# 检查防火墙
sudo ufw status

# 检查 Nginx 状态
sudo systemctl status nginx

# 测试 Nginx 配置
sudo nginx -t

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/jimeng-api-error.log
```

### 3. HTTPS 证书问题

```bash
# 查看证书状态
sudo certbot certificates

# 手动续期
sudo certbot renew

# 重新申请证书
sudo certbot delete -d api.yourdomain.com
sudo certbot --nginx -d api.yourdomain.com
```

### 4. Session ID 失效

```bash
# 测试 token 有效性
curl -X POST http://localhost:5100/token/check \
  -H "Content-Type: application/json" \
  -d '{"token": "your_session_id"}'

# 查看积分余额
curl -X POST http://localhost:5100/token/points \
  -H "Authorization: Bearer your_session_id"
```

---

## ⚡ 性能优化

### 1. 增加系统资源限制

编辑 `docker-compose.yml`：

```yaml
services:
  jimeng-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 512M
```

### 2. 配置日志轮转

```bash
# 创建日志轮转配置
sudo nano /etc/logrotate.d/jimeng-api
```

添加以下内容：

```
/opt/jimeng-api/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
```

### 3. 启用 Nginx 缓存

编辑 Nginx 配置，添加缓存设置：

```nginx
# 在 http 块中添加
proxy_cache_path /var/cache/nginx/jimeng-api levels=1:2 keys_zone=jimeng_cache:10m max_size=1g inactive=60m use_temp_path=off;

# 在 location 块中添加
proxy_cache jimeng_cache;
proxy_cache_valid 200 10m;
proxy_cache_bypass $http_pragma $http_authorization;
```

### 4. 配置自动更新

```bash
# 创建定时任务
crontab -e

# 添加以下行（每天凌晨 3 点检查更新）
0 3 * * * cd /opt/jimeng-api && git pull && docker compose up -d --build >> /var/log/jimeng-update.log 2>&1
```

---

## 📊 监控和告警

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

### 设置监控（可选）

推荐使用以下监控工具：

- **Portainer**: Docker 可视化管理
- **Grafana + Prometheus**: 指标监控
- **Uptime Kuma**: 服务可用性监控

---

## 🎯 快速参考

### 常用命令

```bash
# 查看服务状态
sudo docker compose ps

# 查看实时日志
sudo docker compose logs -f

# 重启服务
sudo docker compose restart

# 更新服务
cd /opt/jimeng-api && git pull && sudo docker compose up -d --build

# 查看 Nginx 配置
sudo nginx -t

# 重启 Nginx
sudo systemctl reload nginx

# 查看防火墙状态
sudo ufw status
```

### 重要路径

```
项目目录: /opt/jimeng-api
Nginx 配置: /etc/nginx/sites-available/jimeng-api
SSL 证书: /etc/letsencrypt/live/api.yourdomain.com/
日志目录: /opt/jimeng-api/logs/
备份目录: /opt/jimeng-api/backups/
```

---

## 📞 获取帮助

- **GitHub Issues**: https://github.com/your-repo/jimeng-api/issues
- **项目文档**: README.md
- **API 文档**: README.md#api文档

---

## ⚠️ 注意事项

1. **定期更新 Session ID**：Session ID 会过期，需要定期更新
2. **监控服务状态**：定期检查服务运行状态和日志
3. **备份配置文件**：定期备份重要配置
4. **安全加固**：不要暴露不必要的端口
5. **合规使用**：仅供个人学习研究使用

---

部署完成后，您可以通过以下地址访问：

- **HTTP**: http://your-server-ip:80
- **HTTPS**: https://api.yourdomain.com

测试 API：

```bash
curl https://api.yourdomain.com/ping
```

祝您部署顺利！🎉
