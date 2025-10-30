#!/bin/bash

#############################################
# Jimeng API 服务管理脚本
# 功能：启动、停止、重启、查看日志、更新服务
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录
PROJECT_DIR="/opt/jimeng-api"

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

# 检查项目目录
check_project_dir() {
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "项目目录不存在: $PROJECT_DIR"
        log_info "请先运行部署脚本: bash scripts/deploy.sh"
        exit 1
    fi
    cd "$PROJECT_DIR"
}

# 启动服务
start_service() {
    log_info "启动 Jimeng API 服务..."
    docker compose up -d
    log_success "服务启动成功"
    sleep 2
    docker compose ps
}

# 停止服务
stop_service() {
    log_info "停止 Jimeng API 服务..."
    docker compose down
    log_success "服务已停止"
}

# 重启服务
restart_service() {
    log_info "重启 Jimeng API 服务..."
    docker compose restart
    log_success "服务重启成功"
    sleep 2
    docker compose ps
}

# 查看日志
view_logs() {
    log_info "查看服务日志（Ctrl+C 退出）..."
    docker compose logs -f --tail=100
}

# 查看状态
view_status() {
    log_info "服务状态:"
    docker compose ps
    echo ""
    log_info "容器资源使用:"
    docker stats --no-stream $(docker compose ps -q)
    echo ""
    log_info "服务健康检查:"
    curl -s http://localhost:5100/ping || log_warning "服务未响应"
}

# 更新服务
update_service() {
    log_info "更新 Jimeng API 服务..."

    # 检查是否为 Git 仓库
    if [ -d ".git" ]; then
        log_info "拉取最新代码..."
        git pull
    else
        log_warning "不是 Git 仓库，跳过代码更新"
    fi

    log_info "重新构建并启动服务..."
    docker compose down
    docker compose build --no-cache
    docker compose up -d

    log_success "服务更新完成"
    sleep 2
    docker compose ps
}

# 清理日志
clean_logs() {
    log_info "清理日志文件..."

    # 清理应用日志
    if [ -d "$PROJECT_DIR/logs" ]; then
        rm -rf "$PROJECT_DIR/logs/*"
        log_success "应用日志已清理"
    fi

    # 清理 Docker 日志
    docker compose logs --no-color > /dev/null 2>&1
    log_success "Docker 日志已清理"

    log_success "日志清理完成"
}

# 备份配置
backup_config() {
    log_info "备份配置文件..."

    BACKUP_DIR="$PROJECT_DIR/backups"
    BACKUP_FILE="$BACKUP_DIR/config_$(date +%Y%m%d_%H%M%S).tar.gz"

    mkdir -p "$BACKUP_DIR"

    tar -czf "$BACKUP_FILE" \
        configs/ \
        .env 2>/dev/null || true

    log_success "配置已备份到: $BACKUP_FILE"
}

# 查看环境信息
view_env() {
    log_info "=========================================="
    log_info "         系统环境信息"
    log_info "=========================================="
    echo ""
    log_info "操作系统:"
    cat /etc/os-release | grep PRETTY_NAME
    echo ""
    log_info "Docker 版本:"
    docker --version
    echo ""
    log_info "Docker Compose 版本:"
    docker compose version
    echo ""
    log_info "磁盘使用:"
    df -h | grep -E '^Filesystem|/$'
    echo ""
    log_info "内存使用:"
    free -h
    echo ""
    log_info "CPU 信息:"
    lscpu | grep "Model name"
    echo ""
}

# 测试服务
test_service() {
    log_info "测试 Jimeng API 服务..."

    # 测试健康检查
    log_info "1. 健康检查 /ping"
    response=$(curl -s http://localhost:5100/ping)
    if [ $? -eq 0 ]; then
        log_success "健康检查通过: $response"
    else
        log_error "健康检查失败"
        return 1
    fi

    # 测试模型列表
    log_info "2. 获取模型列表 /v1/models"
    response=$(curl -s http://localhost:5100/v1/models)
    if [ $? -eq 0 ]; then
        log_success "模型列表获取成功"
        echo "$response" | head -n 5
    else
        log_warning "模型列表获取失败（可能需要 Session ID）"
    fi

    log_success "服务测试完成"
}

# 显示帮助
show_help() {
    echo ""
    log_info "=========================================="
    log_info "     Jimeng API 服务管理脚本"
    log_info "=========================================="
    echo ""
    echo "使用方法: bash manage.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  start       - 启动服务"
    echo "  stop        - 停止服务"
    echo "  restart     - 重启服务"
    echo "  logs        - 查看日志（实时）"
    echo "  status      - 查看状态"
    echo "  update      - 更新服务"
    echo "  clean       - 清理日志"
    echo "  backup      - 备份配置"
    echo "  env         - 查看环境信息"
    echo "  test        - 测试服务"
    echo "  help        - 显示帮助"
    echo ""
    echo "示例:"
    echo "  bash manage.sh start"
    echo "  bash manage.sh logs"
    echo "  bash manage.sh update"
    echo ""
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case "$1" in
        start)
            check_project_dir
            start_service
            ;;
        stop)
            check_project_dir
            stop_service
            ;;
        restart)
            check_project_dir
            restart_service
            ;;
        logs)
            check_project_dir
            view_logs
            ;;
        status)
            check_project_dir
            view_status
            ;;
        update)
            check_project_dir
            update_service
            ;;
        clean)
            check_project_dir
            clean_logs
            ;;
        backup)
            check_project_dir
            backup_config
            ;;
        env)
            view_env
            ;;
        test)
            check_project_dir
            test_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
