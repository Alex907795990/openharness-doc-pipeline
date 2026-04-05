#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# 配置
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe"

# 确保使用 OpenAI 兼容端点，不受 Claude Code 环境变量干扰
export OPENHARNESS_BASE_URL="https://api.jiekou.ai/openai/v1"

# ---------------------------------------------------------------------------
# 1. 差异检测：找出本次提交中 stories/ 目录变更的 .md 文件
# ---------------------------------------------------------------------------
CHANGED_STORIES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "^stories/.*\.md$" || true)

if [ -z "$CHANGED_STORIES" ]; then
    echo "[update_docs] stories/ 目录无变更，跳过文档更新。"
    exit 0
fi

echo "[update_docs] 检测到以下需求文件变更："
echo "$CHANGED_STORIES"

# ---------------------------------------------------------------------------
# 2. 构建传给 oh 的指令
# ---------------------------------------------------------------------------
FILES_LIST=$(echo "$CHANGED_STORIES" | tr '\n' ' ')

PROMPT="请阅读以下新增或变更的业务需求文件：$FILES_LIST
根据文件内容，更新 docs/system_design.md（需包含【核心数据模型】、【API 接口定义】、【关键业务逻辑】三个章节），
并在 MEMORY.md 末尾追加本次架构变更的核心决策摘要（一两句话即可）。"

# ---------------------------------------------------------------------------
# 3. 调用 OpenHarness 执行文档更新
# ---------------------------------------------------------------------------
echo "[update_docs] 调用 OpenHarness 更新文档..."
cd "$SCRIPT_DIR"
"$OH_CMD" --permission-mode full_auto -p "$PROMPT"

# ---------------------------------------------------------------------------
# 4. Git 提交
# ---------------------------------------------------------------------------
git config user.name  "doc-bot"
git config user.email "doc-bot@update-docs.local"

if git diff --quiet docs/system_design.md MEMORY.md 2>/dev/null && \
   git ls-files --error-unmatch docs/system_design.md MEMORY.md 2>/dev/null; then
    echo "[update_docs] 文档无变化，无需提交。"
    exit 0
fi

git add docs/system_design.md MEMORY.md 2>/dev/null || true
git commit -m "docs: 自动更新系统设计文档 [bot]

根据 stories 变更自动生成，相关文件：$FILES_LIST"

git push 2>/dev/null || echo "[update_docs] 远程推送跳过（无远程仓库或推送失败）。"

echo "[update_docs] 完成。"
