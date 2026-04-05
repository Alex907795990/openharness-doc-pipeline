# OpenHarness 使用指南

本文档基于官方说明，为您提供从零开始安装、配置和使用 OpenHarness 的完整指南。

## 1. 环境准备
在开始之前，请确保您的系统已安装以下依赖：
*   **Python 3.10+** 和包管理工具 `uv`
*   **Node.js 18+**（可选，用于支持 React 终端 UI）
*   一个有效的大语言模型 (LLM) API Key

## 2. 安装步骤
使用 Git 克隆仓库并使用 `uv` 安装依赖：

```bash
# 克隆仓库
git clone https://github.com/HKUDS/OpenHarness.git
cd OpenHarness

# 安装依赖（包含开发依赖）
uv sync --extra dev
```

## 3. 启动与配置模型
OpenHarness 支持两种主要的 API 格式。你可以通过环境变量或命令行参数来配置。

### 方式一：使用 Anthropic 格式（默认）
适用于 Claude、Kimi (Moonshot)、Vertex 等兼容 Anthropic 接口的模型。

```bash
# 以 Kimi 为例配置环境变量
export ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic
export ANTHROPIC_API_KEY=your_kimi_api_key
export ANTHROPIC_MODEL=kimi-k2.5

# 启动 OpenHarness
oh                    # 如果已经激活了虚拟环境
# 或者
uv run oh             # 如果未激活虚拟环境
```

### 方式二：使用 OpenAI 格式
适用于 GPT-4o、DeepSeek、通义千问 (DashScope)、Ollama 等兼容 OpenAI 接口的模型。

```bash
# 方式 A：通过命令行参数直接启动
uv run oh --api-format openai \
  --base-url "https://dashscope.aliyuncs.com/compatible-mode/v1" \
  --api-key "sk-xxx" \
  --model "qwen3.5-flash"

# 方式 B：通过环境变量配置后启动
export OPENHARNESS_API_FORMAT=openai
export OPENAI_API_KEY=sk-xxx
export OPENHARNESS_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
export OPENHARNESS_MODEL=qwen3.5-flash

uv run oh
```

## 4. 命令行高级用法 (非交互模式)
OpenHarness 非常适合集成到自动化脚本中，支持单次执行和结构化输出：

```bash
# 单次提示并输出到标准输出
oh -p "Explain this codebase"

# 以 JSON 格式输出结果（适合程序化调用）
oh -p "List all functions in main.py" --output-format json

# 实时流式输出 JSON 事件
oh -p "Fix the bug" --output-format stream-json
```

## 5. 终端 UI (TUI) 交互指南
进入交互模式后，OpenHarness 提供了一个基于 React/Ink 的富文本终端界面：
*   **命令选择器**：输入 `/` 唤起命令菜单，使用方向键选择，回车确认。
*   **权限对话框**：在执行敏感操作（如写入文件、执行 Shell）时，会弹出交互式的 `y/n` 确认框。
*   **模式切换**：输入 `/permissions` 切换权限模式（如切换到只读的 Plan Mode）。
*   **恢复会话**：输入 `/resume` 从历史记录中选择并恢复之前的对话。

## 6. 插件管理
OpenHarness 兼容 Claude 风格的插件，你可以通过以下命令管理插件：

```bash
# 查看已安装插件列表
oh plugin list

# 安装新插件
oh plugin install <source>

# 启用指定插件
oh plugin enable <name>
```