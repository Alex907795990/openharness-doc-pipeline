# OpenHarness 自动化文档流水线落地开发计划

## 阶段一：环境准备与依赖安装

1. 安装 Python 3.10 及以上版本。
2. 安装 Python 包管理工具 uv。
3. 执行 `git clone https://github.com/HKUDS/OpenHarness.git` 克隆核心仓库。
4. 进入 OpenHarness 目录，执行 `uv sync --extra dev` 安装项目依赖。
5. 配置大模型 API 环境变量。根据所选模型，设置 `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY` 及对应的 Base URL。
6. 在终端执行 `oh -p "测试"`，验证模型连通性。

**阶段一检查步骤：**
- 在终端执行 `python --version` 和 `uv --version`，确认输出正常版本号。
- 在终端执行 `oh -p "你好"`，确认能收到大模型的正常文本回复，且无报错信息。

## 阶段二：业务仓库结构初始化

1. 在业务项目根目录创建 `stories/` 文件夹，用于存放 Markdown 格式的业务需求文档。
2. 在业务项目根目录创建 `docs/` 文件夹，用于存放系统架构和设计文档。
3. 在根目录创建 `CLAUDE.md` 文件，并写入以下完整系统提示词：
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
4. 在根目录创建 `MEMORY.md` 空文件。

**阶段二检查步骤：**
- 检查项目根目录是否存在 `stories/` 和 `docs/` 文件夹。
- 检查根目录是否存在 `CLAUDE.md`，且内容包含完整的系统提示词。
- 检查根目录是否存在 `MEMORY.md` 且为空文件。

## 阶段三：自动化触发脚本开发

1. 在项目根目录创建 `update_docs.sh` 脚本文件。
2. 赋予脚本执行权限：`chmod +x update_docs.sh`。
3. 在脚本中编写差异检测逻辑：使用 `git diff --name-only HEAD~1 HEAD | grep "^stories/.*\.md$"` 获取最新修改的需求文件路径。
4. 在脚本中编写中断逻辑：若未检测到 `stories/` 目录变更，则执行 `exit 0` 退出。
5. 在脚本中编写 AI 调用逻辑：使用 `oh -p "<指令>"` 调用 OpenHarness，将获取到的需求文件路径作为参数传入，指示其更新 `docs/system_design.md`。
6. 在脚本中编写 Git 提交逻辑：执行 `git config` 设置机器人信息，随后对 `docs/system_design.md` 和 `MEMORY.md` 执行 `git add`、`git commit` 和 `git push`。

**阶段三检查步骤：**
- 在 `stories/` 目录下新建一个测试需求文件 `test_story.md`，写入一段简单的业务需求。
- 在终端手动执行 `./update_docs.sh`。
- 检查终端输出，确认脚本正确识别到 `test_story.md` 的变更并调用了 OpenHarness。
- 检查 `docs/system_design.md` 和 `MEMORY.md` 文件的内容是否被自动更新。
- 执行 `git log -1`，确认是否生成了由机器人账号提交的新记录。

## 阶段四：CI/CD 流水线集成

1. 在项目根目录创建 `.github/workflows/ai_doc_pipeline.yml` 文件。
2. 配置流水线触发条件：限定为 `push` 事件，且路径匹配 `stories/**.md`。
3. 配置代码拉取步骤：使用 `actions/checkout@v3`，并设置 `fetch-depth: 2` 以支持文件差异对比。
4. 配置环境初始化步骤：在流水线中安装 Python 3.10 和 uv。
5. 配置 OpenHarness 安装步骤：在流水线中克隆 OpenHarness 仓库并执行 `uv sync`。
6. 配置环境变量注入：从 GitHub Secrets 中读取并注入大模型 API Key。
7. 配置脚本执行步骤：在流水线最后一步执行 `./update_docs.sh`。

**阶段四检查步骤：**
- 将本地代码推送到远程仓库。
- 在本地 `stories/` 目录下新建或修改一个需求文件，执行 `git push` 推送至远程仓库。
- 登录 GitHub/GitLab 查看流水线运行状态，确认 `ai_doc_pipeline` 被触发并执行成功。
- 检查远程仓库的 `docs/system_design.md` 是否更新，并包含流水线生成的提交记录。

## 阶段五：系统权限与通知优化

1. 配置文件读写权限：在 OpenHarness 启动参数或配置中，限制写权限仅作用于 `docs/` 目录和 `MEMORY.md` 文件。
2. 修改脚本中的 AI 调用命令：追加 `--output-format json` 参数，强制 OpenHarness 输出标准 JSON 格式的执行结果。
3. 编写通知解析脚本：读取 OpenHarness 输出的 JSON 数据，提取修改摘要。
4. 配置 Webhook 请求：将提取的修改摘要通过 HTTP POST 请求发送至指定的企业通讯工具（如钉钉、飞书）的 Webhook 地址。

**阶段五检查步骤：**
- 触发一次完整的文档更新流程。
- 检查流水线或脚本执行日志，确认 OpenHarness 的输出格式为纯 JSON 数据。
- 检查对应的企业通讯工具（钉钉/飞书等）群组，确认是否成功收到包含修改摘要的通知消息。