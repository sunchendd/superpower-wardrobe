#!/usr/bin/env bash
# deploy.sh — Superpower Wardrobe 一键服务器部署脚本
# 用法: bash deploy.sh
set -e

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()  { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; exit 1; }

echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Superpower Wardrobe — Server Deploy     ${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"

# ── 检查依赖 ─────────────────────────────────────────────────────
command -v docker   >/dev/null 2>&1 || error "docker 未安装"
command -v docker compose version >/dev/null 2>&1 || \
  docker-compose version >/dev/null 2>&1 || error "docker compose 未安装"
command -v supabase >/dev/null 2>&1 || warn "supabase CLI 未安装，跳过函数部署"

# ── 检查 .env ──────────────────────────────────────────────────
if [[ ! -f .env ]]; then
  warn ".env 不存在，从 .env.example 复制..."
  cp .env.example .env
  warn "请编辑 .env 填入真实配置后重新运行此脚本"
  exit 1
fi
info ".env 已存在"

# ── 部署 Supabase Edge Function ────────────────────────────────
if command -v supabase >/dev/null 2>&1; then
  info "部署 Edge Function recommend..."
  source .env
  supabase functions deploy recommend \
    --project-ref "${SUPABASE_PROJECT_REF:-}" \
    --no-verify-jwt 2>/dev/null || warn "Edge Function 部署失败，请手动执行"

  # 设置 Secret
  if [[ -n "$OPENWEATHER_API_KEY" ]]; then
    supabase secrets set OPENWEATHER_API_KEY="$OPENWEATHER_API_KEY" \
      --project-ref "${SUPABASE_PROJECT_REF:-}" 2>/dev/null || true
    info "OPENWEATHER_API_KEY secret 已设置"
  else
    warn "OPENWEATHER_API_KEY 未设置，天气功能将使用默认值"
  fi
fi

# ── 运行数据库迁移 ──────────────────────────────────────────────
if command -v supabase >/dev/null 2>&1; then
  info "运行数据库迁移..."
  supabase db push --project-ref "${SUPABASE_PROJECT_REF:-}" 2>/dev/null \
    || warn "迁移推送失败，请在 Supabase Dashboard SQL Editor 手动执行 migrations/*.sql"
fi

# ── 构建 & 启动 Docker 服务 ────────────────────────────────────
info "构建 Docker 镜像..."
docker compose build --no-cache fashion-clip

info "启动服务..."
docker compose up -d

# ── 等待健康检查 ────────────────────────────────────────────────
info "等待 FashionCLIP 服务就绪（最长 120 秒）..."
WAIT=0
until docker compose exec fashion-clip curl -sf http://localhost:8000/health >/dev/null 2>&1; do
  sleep 5; WAIT=$((WAIT+5))
  if [[ $WAIT -ge 120 ]]; then
    warn "FashionCLIP 启动超时，请查看日志: docker compose logs fashion-clip"
    break
  fi
done
[[ $WAIT -lt 120 ]] && info "FashionCLIP 已就绪 ✓"

# ── 打印访问地址 ────────────────────────────────────────────────
PUBLIC_IP=$(curl -sf https://ipv4.icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
echo ""
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${GREEN}部署完成！${RESET}"
echo ""
echo -e "  Web Demo:       ${BOLD}http://$PUBLIC_IP${RESET}"
echo -e "  FashionCLIP API: ${BOLD}http://$PUBLIC_IP:8000/docs${RESET}"
echo -e "  API 健康检查:    ${BOLD}http://$PUBLIC_IP:8000/health${RESET}"
echo ""
echo -e "在 Flutter 应用构建时传入:"
echo -e "  ${BOLD}--dart-define=FASHION_CLIP_URL=http://$PUBLIC_IP:8000${RESET}"
echo -e "  ${BOLD}--dart-define=SUPABASE_URL=\$SUPABASE_URL${RESET}"
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
