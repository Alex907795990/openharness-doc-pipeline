# 基于 OpenHarness 的需求驱动自动化文档流水线

本文档提供了一套基于 OpenHarness (OH) 的自动化工作流方案。该方案的核心目标是：**人类只需在 Git 仓库中提交大白话的业务需求（Story），AI（OpenHarness）将自动读取需求、分析系统影响，并维护和更新结构化的系统设计文档。**

## 1. 核心架构与目录设计

建议在 Git 仓库中采用以下目录结构，将“输入（需求）”和“输出（系统文档）”分离，并利用 OH 的特性注入系统提示词和持久化记忆。

```text
my-project/
├── stories/                  # 人类提交大白话需求的目录
│   ├── 001_user_login.md     # 例如：用户登录需求
│   └── 002_payment_flow.md   # 例如：支付流程需求
├── docs/                     # AI 维护的结构化系统文档
│   └── system_design.md      # 核心系统架构与接口文档
├── CLAUDE.md                 # OH 的全局系统提示词（定义 AI 的角色和输出规范）
├── MEMORY.md                 # OH 的持久化记忆（记录架构演进的关键决策）
└── .github/workflows/        # CI/CD 流水线配置（如 GitHub Actions）
```

## 2. 核心配置文件

### 2.1 `CLAUDE.md` (定义 AI 角色与规范)
OH 启动时会自动读取当前目录下的 `CLAUDE.md`。在这里定义 AI 的任务和文档规范：

```markdown
# 角色定义
你是一个资深的系统架构师。你的核心任务是：当有新的业务需求（Story）加入时，阅读需求并更新 `docs/system_design.md`。

# 维护系统文档的规则：
1. 必须保持结构化：包含【核心数据模型】、【API 接口定义】、【关键业务逻辑】三个固定章节。
2. 不要删除旧的有效逻辑，而是将新需求融入现有架构中。
3. 遇到需求冲突时，在文档中添加【待确认风险】标记。
4. 使用你的文件读写工具（File I/O tools）直接修改 `docs/system_design.md`。
5. 每次修改后，在 `MEMORY.md` 中简要记录本次架构变更的核心决策。
```

## 3. 自动化处理脚本

编写一个 Shell 脚本（例如 `update_docs.sh`），用于在 CI/CD 环境中找出最新提交的需求，并调用 OH 进行处理。

```bash
#!/bin/bash

# 1. 获取最新添加或修改的 story 文件
LATEST_STORY=$(git diff --name-only HEAD~1 HEAD | grep "^stories/.*\.md$")

if [ -z "$LATEST_STORY" ]; then
  echo "没有检测到新的 Story，跳过更新。"
  exit 0
fi

echo "检测到新需求: $LATEST_STORY"

# 2. 调用 OpenHarness 处理需求并更新文档
# 使用 -p 传入单次指令，并开启全自动权限模式（具体参数视 OH 版本而定，如 --yes 或设置环境变量跳过确认）
oh -p "我刚刚在 $LATEST_STORY 中提交了一个新需求。请阅读该文件，分析它对现有系统的影响，并使用你的工具更新 docs/system_design.md 文件。完成后简要总结你修改了哪些部分。"

# 3. 将 AI 的修改提交到 Git
git config --global user.name "OpenHarness AI"
git config --global user.email "ai@openharness.local"
git add docs/system_design.md MEMORY.md
git commit -m "docs: 基于 $LATEST_STORY 自动更新系统设计文档"
git push
```

## 4. CI/CD 集成 (GitHub Actions 示例)

将上述脚本配置到 Git 仓库的流水线中。只要人类往 `stories/` 目录 push 了新文件，流水线就会自动触发 OH。

文件路径：`.github/workflows/ai_doc_pipeline.yml`

```yaml
name: AI System Doc Updater

on:
  push:
    paths:
      - 'stories/**.md' # 只有 stories 目录更新时才触发

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 2 # 获取上一个 commit 以便对比文件差异

      - name: Setup Python & uv
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - run: pip install uv
      
      - name: Install OpenHarness
        run: |
          git clone https://github.com/HKUDS/OpenHarness.git /tmp/oh
          cd /tmp/oh && uv sync
          echo 'export PATH="/tmp/oh/.venv/bin:$PATH"' >> $GITHUB_ENV

      - name: Run OpenHarness Pipeline
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} # 从 GitHub Secrets 获取 API Key
        run: |
          chmod +x ./update_docs.sh
          ./update_docs.sh
```

## 5. 进阶优化建议

1. **利用 `MEMORY.md` 追踪架构演进**：通过在 `CLAUDE.md` 中要求 OH 记录变更日志，让 AI 在处理未来的复杂需求时，能“回忆”起之前的设计初衷和历史包袱。
2. **多智能体校验 (Swarm)**：对于极其复杂的系统，可以利用 OH 的群体协同功能拆分任务：
   *   **Agent A (产品经理)**：读取 Story，输出结构化的需求分析 JSON。
   *   **Agent B (架构师)**：读取 JSON，修改 `system_design.md`。
   *   **Agent C (审查员)**：对比修改前后的文档，如果不符合规范，打回给 Agent B 重写。
3. **消息通知集成**：使用 `oh -p "..." --output-format json` 让 OH 返回标准的 JSON 格式，方便后续的 Webhook 解析，将 AI 的更新摘要发送到钉钉、飞书或 Slack。