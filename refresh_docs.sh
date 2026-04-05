#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# 需求文档 → 系统设计 全量刷新流水线
# 用法: ./refresh_docs.sh [目标文档仓库路径]
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 兼容 Linux/macOS (.venv/bin/oh) 和 Windows (.venv/Scripts/oh.exe)
if [ -f "$SCRIPT_DIR/OpenHarness/.venv/bin/oh" ]; then
    OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/bin/oh"
elif [ -f "$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe" ]; then
    OH_CMD="$SCRIPT_DIR/OpenHarness/.venv/Scripts/oh.exe"
else
    echo "[refresh_docs] 错误: 找不到 OpenHarness 可执行文件 (oh/oh.exe)"
    exit 1
fi

PROMPT_FILE="$SCRIPT_DIR/pipeline/prompts/update_system_design.md"

# 默认目标仓库
DEFAULT_TARGET="../doc-test"
TARGET_REPO="${1:-$DEFAULT_TARGET}"

# 转换为绝对路径
TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

if [ ! -d "$TARGET_REPO/oh-story" ]; then
    echo "[refresh_docs] 错误: $TARGET_REPO 不是有效的文档仓库（缺少 oh-story 目录）"
    exit 1
fi

# 确保使用 OpenAI 兼容端点
export OPENHARNESS_BASE_URL="https://api.jiekou.ai/openai/v1"
export PYTHONIOENCODING="utf-8"
export PYTHONUTF8=1

echo "[refresh_docs] 目标仓库: $TARGET_REPO"
echo "[refresh_docs] 正在执行全量手动刷新..."

# ---------------------------------------------------------------------------
# 1. 收集全量 story 文件列表
# ---------------------------------------------------------------------------
cd "$TARGET_REPO"
ALL_STORIES=$(find oh-story -name "*.md" -type f 2>/dev/null | sort | tr '\n' ' ')

# ---------------------------------------------------------------------------
# 2. 构造全量刷新的伪 Diff 信息
# ---------------------------------------------------------------------------
DIFF_INFO="=== FULL MANUAL REFRESH ===
本次为手动触发的全量刷新，无特定文件 diff。请根据提供的全量 Story 文件，重新审视并更新所有维度的系统设计文档（YAML格式）。"

# ---------------------------------------------------------------------------
# 3. 读取提示词模板并替换变量
# ---------------------------------------------------------------------------
PROMPT_TEMPLATE=$(cat "$PROMPT_FILE")
PROMPT="${PROMPT_TEMPLATE//\{\{ALL_STORY_FILES\}\}/$ALL_STORIES}"
PROMPT="${PROMPT//\{\{DIFF_INFO\}\}/$DIFF_INFO}"

# ---------------------------------------------------------------------------
# 4. 调用 OpenHarness 执行文档更新
# ---------------------------------------------------------------------------
echo "[refresh_docs] 调用 OpenHarness 全量更新文档..."
"$OH_CMD" -m zai-org/glm-5 --permission-mode full_auto -p "$PROMPT"

# ---------------------------------------------------------------------------
# 5. Git 提交
# ---------------------------------------------------------------------------
git config user.name  "doc-bot"
git config user.email "doc-bot@update-docs.local"

# 由于现在允许生成多个 yaml 文件，这里将 oh-gen-doc 整个目录和 MEMORY.md 都加入
git add oh-gen-doc/ MEMORY.md 2>/dev/null || true

if git diff --cached --quiet 2>/dev/null; then
    echo "[refresh_docs] 文档无变化，无需提交。"
    exit 0
fi

git commit -m "docs: 手动全量刷新系统设计文档 [bot]

基于所有 oh-story 重新生成/更新。"

echo "[refresh_docs] 完成。目标仓库: $TARGET_REPO"
