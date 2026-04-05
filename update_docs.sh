#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# 需求文档 → 系统设计 流水线
# 用法: ./update_docs.sh [目标文档仓库路径]
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe"
PROMPT_FILE="$SCRIPT_DIR/pipeline/prompts/update_system_design.md"

# 默认目标仓库
DEFAULT_TARGET="../doc-test"
TARGET_REPO="${1:-$DEFAULT_TARGET}"

# 转换为绝对路径
TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

if [ ! -d "$TARGET_REPO/stories" ]; then
    echo "[update_docs] 错误: $TARGET_REPO 不是有效的文档仓库（缺少 stories 目录）"
    exit 1
fi

# 确保使用 OpenAI 兼容端点
export OPENHARNESS_BASE_URL="https://api.jiekou.ai/openai/v1"

# ---------------------------------------------------------------------------
# 1. 检测目标仓库中 stories/ 的变更
# ---------------------------------------------------------------------------
cd "$TARGET_REPO"
CHANGED_STORIES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "^stories/.*\.md$" || true)

if [ -z "$CHANGED_STORIES" ]; then
    echo "[update_docs] stories/ 目录无变更，跳过文档更新。"
    exit 0
fi

echo "[update_docs] 目标仓库: $TARGET_REPO"
echo "[update_docs] 检测到以下需求文件变更："
echo "$CHANGED_STORIES"

# ---------------------------------------------------------------------------
# 2. 读取提示词模板并替换变量
# ---------------------------------------------------------------------------
FILES_LIST=$(echo "$CHANGED_STORIES" | tr '\n' ' ')
PROMPT_TEMPLATE=$(cat "$PROMPT_FILE")
PROMPT="${PROMPT_TEMPLATE//\{\{CHANGED_FILES\}\}/$FILES_LIST}"

# ---------------------------------------------------------------------------
# 3. 调用 OpenHarness 执行文档更新
# ---------------------------------------------------------------------------
echo "[update_docs] 调用 OpenHarness 更新文档..."
cd "$TARGET_REPO"
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

echo "[update_docs] 完成。目标仓库: $TARGET_REPO"
