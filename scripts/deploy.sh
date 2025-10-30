#!/bin/bash

#############################################
# Jimeng API 一键部署脚本
# 适用于 Ubuntu/Debian Linux
# 功能：安装 Docker、Nginx、Certbot 并部署项目
#############################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本"
        log_info "使用命令: sudo bash deploy.sh"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    log_info "检查系统版本..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log_success "系统: $OS $VER"
    else
        log_error "无法确定系统版本"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统软件包..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget git ufw
    log_success "系统更新完成"
}

# 安装 Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_warning "Docker 已安装，跳过"
        docker --version
    else
        log_info "开始安装 Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        log_success "Docker 安装完成"
        docker --version
    fi
}

# 安装 Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_warning "Docker Compose 已安装，跳过"
        docker-compose --version
    else
        log_info "开始安装 Docker Compose..."
        # 使用 Docker Compose V2（作为 Docker 插件）
        apt-get install -y docker-compose-plugin
        log_success "Docker Compose 安装完成"
        docker compose version
    fi
}

# 安装 Nginx
install_nginx() {
    if command -v nginx &> /dev/null; then
        log_warning "Nginx 已安装，跳过"
        nginx -v
    else
        log_info "开始安装 Nginx..."
        apt-get install -y nginx
        systemctl enable nginx
        systemctl start nginx
        log_success "Nginx 安装完成"
        nginx -v
    fi
}

# 安装 Certbot
install_certbot() {
    if command -v certbot &> /dev/null; then
        log_warning "Certbot 已安装，跳过"
        certbot --version
    else
        log_info "开始安装 Certbot..."
        apt-get install -y certbot python3-certbot-nginx
        log_success "Certbot 安装完成"
        certbot --version
    fi
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."

    # 启用 UFW
    ufw --force enable

    # 允许 SSH
    ufw allow 22/tcp
    log_info "已开放 SSH (22)"

    # 允许 HTTP
    ufw allow 80/tcp
    log_info "已开放 HTTP (80)"

    # 允许 HTTPS
    ufw allow 443/tcp
    log_info "已开放 HTTPS (443)"

    # 拒绝外部访问 5100（仅允许本地）
    ufw deny 5100/tcp
    log_info "已拒绝外部访问端口 5100（仅内网访问）"

    ufw --force reload
    log_success "防火墙配置完成"
    ufw status
}

# 部署项目
deploy_project() {
    log_info "部署 Jimeng API 项目..."

    # 项目目录
    PROJECT_DIR="/opt/jimeng-api"

    if [ -d "$PROJECT_DIR" ]; then
        log_warning "项目目录已存在: $PROJECT_DIR"
        read -p "是否要删除并重新克隆？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            log_info "使用现有项目目录"
            cd "$PROJECT_DIR"
            git pull || log_warning "无法更新项目，可能不是 Git 仓库"
        fi
    fi

    if [ ! -d "$PROJECT_DIR" ]; then
        log_info "克隆项目..."
        read -p "请输入 Git 仓库地址（留空使用当前目录）: " REPO_URL

        if [ -z "$REPO_URL" ]; then
            log_info "使用当前目录的项目文件..."
            CURRENT_DIR=$(pwd)
            mkdir -p "$PROJECT_DIR"
            cp -r "$CURRENT_DIR"/* "$PROJECT_DIR/" || log_error "复制文件失败"
        else
            git clone "$REPO_URL" "$PROJECT_DIR"
        fi
        log_success "项目准备完成"
    fi

    cd "$PROJECT_DIR"

    # 构建并启动容器
    log_info "构建并启动 Docker 容器..."
    docker compose down || true
    docker compose build
    docker compose up -d

    log_success "Docker 容器启动成功"

    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5

    # 检查容器状态
    docker compose ps
}

# 配置 Nginx 反向代理
configure_nginx() {
    log_info "配置 Nginx 反向代理..."

    read -p "请输入您的域名（例如：api.example.com）: " DOMAIN

    if [ -z "$DOMAIN" ]; then
        log_warning "未输入域名，跳过 Nginx 配置"
        log_info "您可以稍后手动配置，配置文件模板位于: scripts/nginx-config-template.conf"
        return
    fi

    # 创建 Nginx 配置文件
    NGINX_CONF="/etc/nginx/sites-available/jimeng-api"

    cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    # 访问日志
    access_log /var/log/nginx/jimeng-api-access.log;
    error_log /var/log/nginx/jimeng-api-error.log;

    # 限制请求体大小（上传图片需要）
    client_max_body_size 100M;

    # 反向代理到 Docker 容器
    location / {
        proxy_pass http://localhost:5100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 超时设置（支持长轮询）
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;

        # WebSocket 支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    # 启用站点
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/

    # 测试配置
    nginx -t

    # 重启 Nginx
    systemctl reload nginx

    log_success "Nginx 配置完成"

    # 配置 HTTPS
    log_info "开始配置 HTTPS..."
    read -p "是否立即申请 Let's Encrypt 证书？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || \
        certbot --nginx -d "$DOMAIN"
        log_success "HTTPS 证书配置完成"
    else
        log_warning "跳过 HTTPS 配置，稍后可运行: certbot --nginx -d $DOMAIN"
    fi
}

# 显示部署信息
show_deployment_info() {
    log_success "=========================================="
    log_success "         部署完成！"
    log_success "=========================================="
    echo ""
    log_info "服务状态:"
    docker compose ps
    echo ""
    log_info "访问地址:"
    log_info "  - 本地: http://localhost:5100"
    log_info "  - 公网: http://$(curl -s ifconfig.me):80 (如已配置域名则使用域名)"
    echo ""
    log_info "常用命令:"
    log_info "  查看日志: cd /opt/jimeng-api && docker compose logs -f"
    log_info "  重启服务: cd /opt/jimeng-api && docker compose restart"
    log_info "  停止服务: cd /opt/jimeng-api && docker compose down"
    log_info "  更新服务: cd /opt/jimeng-api && git pull && docker compose up -d --build"
    echo ""
    log_info "管理脚本:"
    log_info "  启动: bash /opt/jimeng-api/scripts/manage.sh start"
    log_info "  停止: bash /opt/jimeng-api/scripts/manage.sh stop"
    log_info "  重启: bash /opt/jimeng-api/scripts/manage.sh restart"
    log_info "  日志: bash /opt/jimeng-api/scripts/manage.sh logs"
    log_info "  更新: bash /opt/jimeng-api/scripts/manage.sh update"
    echo ""
    log_warning "重要提示:"
    log_warning "1. 请确保 DNS 已正确解析到服务器 IP"
    log_warning "2. 请修改配置文件配置 Session ID (如需多账号轮询)"
    log_warning "3. 定期检查日志: docker compose logs -f"
    echo ""
    log_success "部署脚本执行完成！"
}

# 主函数
main() {
    echo ""
    log_info "=========================================="
    log_info "    Jimeng API 一键部署脚本"
    log_info "=========================================="
    echo ""

    check_root
    check_system

    log_info "即将开始部署，按 Enter 继续..."
    read

    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    configure_firewall
    deploy_project
    configure_nginx
    show_deployment_info
}

# 执行主函数
main
