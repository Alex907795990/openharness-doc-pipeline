#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# 需求文档 → 系统设计 流水线
# 用法: ./update_docs.sh [目标文档仓库路径]
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 兼容 Linux/macOS (.venv/bin/oh) 和 Windows (.venv/Scripts/oh.exe)
if [ -f "$SCRIPT_DIR/OpenHarness/.venv/bin/oh" ]; then
    OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/bin/oh"
elif [ -f "$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe" ]; then
    OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe"
else
    echo "[update_docs] 错误: 找不到 OpenHarness 可执行文件 (oh/oh.exe)"
    exit 1
fi

PROMPT_FILE="$SCRIPT_DIR/pipeline/prompts/update_system_design.md"

# 默认目标仓库
DEFAULT_TARGET="../doc-test"
TARGET_REPO="${1:-$DEFAULT_TARGET}"

# 转换为绝对路径
TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

if [ ! -d "$TARGET_REPO/oh-story" ]; then
    echo "[update_docs] 错误: $TARGET_REPO 不是有效的文档仓库（缺少 oh-story 目录）"
    exit 1
fi

# 确保使用 OpenAI 兼容端点
export OPENHARNESS_BASE_URL="https://api.jiekou.ai/openai/v1"
export OPENAI_API_KEY="${OPENHARNESS_API_KEY:-$OPENAI_API_KEY}"
export PYTHONIOENCODING="utf-8"
export PYTHONUTF8=1

# ---------------------------------------------------------------------------
# 1. 检测目标仓库中 oh-story/ 的变更
# ---------------------------------------------------------------------------
cd "$TARGET_REPO"
CHANGED_STORIES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "^oh-story/.*\.md$" || true)

if [ -z "$CHANGED_STORIES" ]; then
    echo "[update_docs] oh-story/ 目录无变更，跳过文档更新。"
    exit 0
fi

echo "[update_docs] 目标仓库: $TARGET_REPO"
echo "[update_docs] 检测到以下需求文件变更："
echo "$CHANGED_STORIES"

# ---------------------------------------------------------------------------
# 2. 收集全量 story 文件列表和 diff 信息
# ---------------------------------------------------------------------------
ALL_STORIES=$(find oh-story -name "*.md" -type f 2>/dev/null | sort | tr '\n' ' ')

# 获取变更文件的 diff 信息
DIFF_INFO=""
for file in $CHANGED_STORIES; do
    DIFF_INFO+="=== DIFF: $file ==="$'\n'
    DIFF_INFO+=$(git diff HEAD~1 HEAD -- "$file" 2>/dev/null || echo "[文件为新增]")$'\n'$'\n'
done

# ---------------------------------------------------------------------------
# 3. 读取提示词模板并替换变量
# ---------------------------------------------------------------------------
PROMPT_TEMPLATE=$(cat "$PROMPT_FILE")
PROMPT="${PROMPT_TEMPLATE//\{\{ALL_STORY_FILES\}\}/$ALL_STORIES}"
PROMPT="${PROMPT//\{\{DIFF_INFO\}\}/$DIFF_INFO}"

# ---------------------------------------------------------------------------
# 4. 调用 OpenHarness 执行文档更新
# ---------------------------------------------------------------------------
echo "[update_docs] 调用 OpenHarness 更新文档..."
cd "$TARGET_REPO"
"$OH_CMD" --api-format openai -m zai-org/glm-5 --permission-mode full_auto -p "$PROMPT"

# ---------------------------------------------------------------------------
# 5. Git 提交
# ---------------------------------------------------------------------------
git config user.name  "doc-bot"
git config user.email "doc-bot@update-docs.local"

# 确保目录存在，避免 git add 报错
mkdir -p oh-gen-doc
touch MEMORY.md

# 支持新版提示词可能生成的多个 yaml 文件
git add oh-gen-doc/ MEMORY.md 2>/dev/null || true

if git diff --cached --quiet 2>/dev/null; then
    echo "[update_docs] 文档无变化，无需提交。"
    exit 0
fi

git commit -m "docs: 自动更新系统设计文档 [bot]

根据 oh-story 变更自动生成，变更文件：$(echo "$CHANGED_STORIES" | tr '\n' ' ')"

echo "[update_docs] 完成。目标仓库: $TARGET_REPO"
