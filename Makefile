##############################################################################
# Superpower Wardrobe — 一键部署
#
# 前置条件:
#   1. 复制 .env.example 为 .env 并填入真实凭证
#   2. 从 https://supabase.com/dashboard/account/tokens 生成 Personal Access Token
#   3. 运行: source .env && make setup-all ACCESS_TOKEN=your_token_here OPENWEATHER_KEY=your_key
#
##############################################################################

PROJECT_REF    ?= your_project_ref
SUPABASE_URL   ?= https://$(PROJECT_REF).supabase.co
OPENWEATHER_KEY ?= 
API_BASE     = https://api.supabase.com/v1/projects/$(PROJECT_REF)
MIGRATIONS   = $(sort $(wildcard supabase/migrations/*.sql))
SEED         = supabase/seed.sql

.PHONY: setup-all db-migrate db-seed fn-deploy fn-deploy-all fn-secrets help

## 一键完成所有步骤
setup-all: db-migrate db-seed fn-deploy-all fn-secrets
	@echo ""
	@echo "✅ 所有步骤完成！"
	@echo "   Supabase URL  : $(SUPABASE_URL)"
	@echo "   Edge Functions: $(SUPABASE_URL)/functions/v1/recommend"
	@echo "                   $(SUPABASE_URL)/functions/v1/purchase-suggest"
	@echo ""

## 第1步：应用所有数据库 Migrations（按文件名顺序）
db-migrate:
ifndef ACCESS_TOKEN
	$(error ❌ 缺少 ACCESS_TOKEN. 用法: make setup-all ACCESS_TOKEN=your_token)
endif
	@echo "📦 应用数据库 migrations..."
	@for f in $(MIGRATIONS); do \
	  echo "  → $$f"; \
	  SQL=$$(cat $$f | tr '\n' ' ' | sed "s/'/\\\\''/g"); \
	  curl -sf -X POST "$(API_BASE)/database/query" \
	    -H "Authorization: Bearer $(ACCESS_TOKEN)" \
	    -H "Content-Type: application/json" \
	    -d "{\"query\": \"$$SQL\"}" \
	    && echo "    ✅ 成功" \
	    || echo "    ⚠️  可能已存在，继续..."; \
	done

## 第2步：插入 preset 种子数据
db-seed:
ifndef ACCESS_TOKEN
	$(error ❌ 缺少 ACCESS_TOKEN)
endif
	@echo "🌱 插入 preset 套装数据..."
	@SQL=$$(cat $(SEED) | tr '\n' ' ' | sed "s/'/\\\\''/g"); \
	curl -sf -X POST "$(API_BASE)/database/query" \
	  -H "Authorization: Bearer $(ACCESS_TOKEN)" \
	  -H "Content-Type: application/json" \
	  -d "{\"query\": \"$$SQL\"}" \
	  && echo "✅ Seed 数据插入成功" \
	  || echo "⚠️  Seed 数据可能已存在，继续..."

## 第3步：部署所有 Edge Functions
fn-deploy-all: fn-deploy-recommend fn-deploy-purchase

fn-deploy-recommend:
ifndef ACCESS_TOKEN
	$(error ❌ 缺少 ACCESS_TOKEN)
endif
	@echo "🚀 部署 Edge Function: recommend..."
	SUPABASE_ACCESS_TOKEN=$(ACCESS_TOKEN) supabase functions deploy recommend \
	  --project-ref $(PROJECT_REF) \
	  --no-verify-jwt=false
	@echo "✅ recommend 部署成功"

fn-deploy-purchase:
ifndef ACCESS_TOKEN
	$(error ❌ 缺少 ACCESS_TOKEN)
endif
	@echo "🚀 部署 Edge Function: purchase-suggest..."
	SUPABASE_ACCESS_TOKEN=$(ACCESS_TOKEN) supabase functions deploy purchase-suggest \
	  --project-ref $(PROJECT_REF) \
	  --no-verify-jwt=false
	@echo "✅ purchase-suggest 部署成功"

## 兼容旧命令
fn-deploy: fn-deploy-all

## 第4步：设置 Edge Function 环境变量
fn-secrets:
ifndef ACCESS_TOKEN
	$(error ❌ 缺少 ACCESS_TOKEN)
endif
	@echo "🔑 配置 Edge Function Secrets..."
ifndef OPENWEATHER_KEY
	$(error ❌ 缺少 OPENWEATHER_KEY. 用法: make fn-secrets ACCESS_TOKEN=xxx OPENWEATHER_KEY=xxx)
endif
	SUPABASE_ACCESS_TOKEN=$(ACCESS_TOKEN) supabase secrets set \
	  --project-ref $(PROJECT_REF) \
	  OPENWEATHER_API_KEY=$(OPENWEATHER_KEY)
	@echo "✅ Secrets 配置成功"

## 验证部署
verify:
	@echo "🔍 验证 API 连接..."
	@curl -sf "$(SUPABASE_URL)/rest/v1/preset_outfits?select=name" \
	  -H "apikey: $${SUPABASE_ANON_KEY}" \
	  -H "Authorization: Bearer $${SUPABASE_ANON_KEY}" \
	  && echo "\n✅ 数据库可访问，preset 数据已就绪" \
	  || echo "❌ 无法访问，请先运行 make setup-all"

help:
	@echo "用法："
	@echo "  make setup-all ACCESS_TOKEN=<token>   # 一键完成所有 Supabase 部署"
	@echo "  make db-migrate ACCESS_TOKEN=<token>  # 仅建表"
	@echo "  make db-seed    ACCESS_TOKEN=<token>  # 仅插入 preset 数据"
	@echo "  make fn-deploy  ACCESS_TOKEN=<token>  # 仅部署 Edge Function"
	@echo "  make fn-secrets ACCESS_TOKEN=<token>  # 仅配置 Secrets"
	@echo "  make verify                            # 验证部署结果"
	@echo ""
	@echo "Docker 部署（FashionCLIP + Web Demo）："
	@echo "  make docker-up                         # 启动所有服务"
	@echo "  make docker-down                       # 停止服务"
	@echo "  make docker-logs                       # 查看日志"
	@echo "  make docker-rebuild                    # 重新构建并启动"
	@echo ""
	@echo "获取 Access Token: https://supabase.com/dashboard/account/tokens"

## Docker: 启动所有服务（FashionCLIP + Web Demo nginx）
.PHONY: docker-up docker-down docker-logs docker-rebuild

docker-up:
	@echo "🐳 启动 Docker 服务..."
	docker compose up -d
	@echo "✅ 服务已启动"
	@echo "   FashionCLIP API: http://localhost:8000/docs"
	@echo "   Web Demo:        http://localhost:80"

docker-down:
	@echo "🛑 停止 Docker 服务..."
	docker compose down

docker-logs:
	docker compose logs -f

docker-rebuild:
	@echo "🔨 重新构建并启动..."
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo "✅ 重建完成"
