# OpenHarness 仓库分析报告

## 1. 仓库简介
**OpenHarness** (由 HKUDS 开源) 是一个轻量级的开源智能体基础设施（Agent Harness）。它的核心理念是：大语言模型（LLM）本身只是提供智能的“大脑”，而 Harness 则为模型提供“手、眼、记忆和安全边界”，使其成为一个功能完备的智能体。

通过一个简单的命令行指令 (`oh`)，用户可以启动 OpenHarness，它支持 CLI 智能体集成，并为开发者提供了一个探索和构建智能体工作流的强大平台。

## 2. 核心特性
OpenHarness 提供了五大核心维度的能力：

*   **🔄 智能体循环引擎 (Agent Loop Engine)**：支持流式工具调用循环、API 指数退避重试、并行工具执行以及 Token 计数与成本追踪。
*   **🔧 工具箱 (Harness Toolkit)**：内置 43 种以上的工具（涵盖文件 I/O、Shell、网络搜索、MCP 等），支持按需加载的技能系统（`.md` 格式），并拥有完善的插件生态（兼容 anthropics/skills 等）。
*   **🧠 上下文与记忆 (Context & Memory)**：支持 `CLAUDE.md` 发现与注入、上下文自动压缩、`MEMORY.md` 持久化记忆以及历史会话恢复。
*   **🛡️ 治理与安全 (Governance)**：提供多级权限模式（如默认询问、全自动、只读计划模式）、路径级读写规则控制、工具调用前后的 Hook 拦截以及交互式审批对话框。
*   **🤝 群体协同 (Swarm Coordination)**：支持子智能体生成与任务委派、团队注册与任务管理以及后台任务生命周期管理。

## 3. 架构设计
项目主要使用 Python 编写（占比 96.5%），包含多个核心子系统：
*   `engine/`: 智能体主循环
*   `tools/`: 43+ 核心工具集
*   `skills/` & `plugins/`: 扩展与领域知识库
*   `permissions/` & `hooks/`: 安全权限与生命周期管控
*   `mcp/`: 模型上下文协议 (Model Context Protocol) 客户端集成
*   `memory/` & `tasks/` & `coordinator/`: 记忆、后台任务与多智能体协同
*   `ui/`: 基于 React/Ink 的终端用户界面 (TUI)

## 4. 模型兼容性
OpenHarness 具有极强的模型兼容性，开箱即用支持两大主流 API 格式：
1.  **Anthropic 格式（默认）**：原生支持 Claude 系列，以及兼容该格式的 Moonshot (Kimi)、Vertex、Bedrock 等网关。
2.  **OpenAI 格式**：通过 `--api-format openai` 参数，支持包括 DashScope (阿里云)、DeepSeek、OpenAI (GPT-4o)、GitHub Models、SiliconFlow、Groq 以及本地部署的 Ollama。

## 5. 典型应用场景
*   **代码仓库助手**：在本地读取代码、修改文件并运行检查。
*   **自动化脚本工具**：在 CI/CD 或自动化流程中输出 JSON 或流式 JSON 数据。
*   **插件与技能测试床**：用于实验和开发 Claude 风格的扩展插件。
*   **多智能体原型框架**：用于测试任务委派、后台执行等复杂的群体智能体协作模式。

## 6. 总结
OpenHarness 是一个面向研究人员、开发者和开源社区的优秀基础设施项目。它不仅揭示了生产级 AI 智能体的底层运作机制，还提供了一个高度可扩展、安全且兼容性极强的框架，极大降低了开发复杂多智能体系统的门槛。