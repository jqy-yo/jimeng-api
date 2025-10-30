# ⚡ 快速开始 - 5 分钟部署指南

本指南帮助您在 **5 分钟内**将 Jimeng API 部署到您的服务器。

---

## 🎯 部署步骤

### 1️⃣ 准备工作（1 分钟）

**SSH 连接服务器**：
```bash
ssh root@your-server-ip
```

**准备域名（可选）**：
- 在域名服务商添加 A 记录
- 指向您的服务器 IP

**获取 Session ID**（必需）：
- 访问 https://jimeng.jianying.com（国内站）
- 或 https://dreamina.capcut.com（国际站）
- 按 F12 打开开发者工具
- Network 标签找到请求
- Cookie 中找到 `sessionid`
- 国际站需加 `us-` 前缀

---

### 2️⃣ 上传项目（1 分钟）

**方式一：Git 克隆**
```bash
cd /opt
git clone https://github.com/your-repo/jimeng-api.git
cd jimeng-api
```

**方式二：直接上传**
```bash
# 在本地执行
scp -r ./jimeng-api root@your-server-ip:/opt/
```

---

### 3️⃣ 一键部署（3 分钟）

```bash
cd /opt/jimeng-api

# 赋予脚本执行权限
chmod +x scripts/deploy.sh
chmod +x scripts/manage.sh

# 运行一键部署脚本
sudo bash scripts/deploy.sh
```

脚本会提示您：
1. **是否克隆项目**（已有则跳过）
2. **输入域名**（可选，直接回车跳过）
3. **是否申请 HTTPS**（有域名则选择 Y）

---

## 🎉 部署完成！

### 验证部署

```bash
# 检查服务状态
docker compose ps

# 测试 API
curl http://localhost:5100/ping

# 如果配置了域名
curl https://api.yourdomain.com/ping
```

预期输出：
```
pong
```

---

## 🔑 配置 Session ID（可选但推荐）

### 方式一：通过 API 请求时传入

直接在请求头中添加：
```bash
curl -X POST https://api.yourdomain.com/v1/images/generations \
  -H "Authorization: Bearer your_session_id" \
  -H "Content-Type: application/json" \
  -d '{"model": "jimeng-4.0", "prompt": "可爱的小猫"}'
```

### 方式二：配置多账号轮询

编辑环境变量（如果项目支持）：
```bash
cd /opt/jimeng-api
nano .env
```

添加：
```env
# 多个 Session ID，逗号分隔
JIMENG_SESSION_IDS=token1,token2,us-token3,us-token4
```

重启服务：
```bash
docker compose restart
```

---

## 🛠️ 常用命令

### 服务管理

```bash
cd /opt/jimeng-api

# 启动
bash scripts/manage.sh start

# 停止
bash scripts/manage.sh stop

# 重启
bash scripts/manage.sh restart

# 查看日志
bash scripts/manage.sh logs

# 查看状态
bash scripts/manage.sh status

# 更新服务
bash scripts/manage.sh update
```

### Docker 命令

```bash
cd /opt/jimeng-api

# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 重启
docker compose restart

# 重新构建
docker compose up -d --build
```

---

## 📝 测试 API

### 健康检查

```bash
curl http://localhost:5100/ping
```

### 文生图

```bash
curl -X POST http://localhost:5100/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SESSION_ID" \
  -d '{
    "model": "jimeng-4.0",
    "prompt": "一只可爱的猫咪，油画风格",
    "ratio": "1:1",
    "resolution": "2k"
  }'
```

### 查看模型列表

```bash
curl http://localhost:5100/v1/models
```

### 查看积分

```bash
curl -X POST http://localhost:5100/token/points \
  -H "Authorization: Bearer YOUR_SESSION_ID"
```

---

## 🚨 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker compose logs

# 重新构建
docker compose down
docker compose build --no-cache
docker compose up -d
```

### 无法访问

```bash
# 检查服务
curl http://localhost:5100/ping

# 检查防火墙
sudo ufw status

# 检查端口
sudo netstat -tulpn | grep 5100
```

### Nginx 问题

```bash
# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

---

## 📂 项目文件结构

```
jimeng-api/
├── scripts/
│   ├── deploy.sh                    # 一键部署脚本 ⭐
│   ├── manage.sh                    # 服务管理脚本 ⭐
│   └── nginx-config-template.conf   # Nginx 配置模板
│
├── .env.example                     # 环境变量示例
├── docker-compose.yml               # Docker Compose 配置
├── docker-compose.prod.yml          # 生产环境配置
├── Dockerfile                       # Docker 镜像定义
│
├── DEPLOY.md                        # 详细部署文档 📖
├── QUICKSTART.md                    # 快速开始（本文件）⚡
└── README.md                        # 项目说明
```

---

## 🔗 访问地址

部署完成后，可通过以下地址访问：

- **本地访问**: http://localhost:5100
- **服务器 IP**: http://YOUR_SERVER_IP
- **域名访问**: https://api.yourdomain.com（如已配置）

API 文档：查看 README.md

---

## 📞 需要帮助？

- **详细文档**: 查看 [DEPLOY.md](DEPLOY.md)
- **项目说明**: 查看 [README.md](README.md)
- **问题反馈**: GitHub Issues

---

## ⚠️ 重要提示

1. **定期更新 Session ID**：Session ID 会过期
2. **监控服务状态**：定期查看日志
3. **备份配置**：重要配置定期备份
4. **安全加固**：不要暴露不必要的端口
5. **合规使用**：仅供学习研究使用

---

## 🎁 额外功能

### 启用生产环境配置

```bash
# 使用生产环境配置文件
docker compose -f docker-compose.prod.yml up -d
```

### 配置自动更新

```bash
# 添加定时任务
crontab -e

# 每天凌晨 3 点自动更新
0 3 * * * cd /opt/jimeng-api && git pull && docker compose up -d --build
```

### 配置日志轮转

```bash
# 创建日志轮转配置
sudo nano /etc/logrotate.d/jimeng-api

# 添加配置
/opt/jimeng-api/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

---

恭喜！您已成功部署 Jimeng API 🎉

现在您可以开始使用 API 进行图像和视频生成了。

有任何问题，请查看 [DEPLOY.md](DEPLOY.md) 获取详细帮助。
