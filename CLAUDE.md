# 流水线仓库

## 用途
这是「需求文档 → 系统设计」自动化流水线的核心仓库。

## 组成
- `OpenHarness/` - AI Agent 框架（HKUDS 开源项目）
- `pipeline/` - 流水线相关文档和脚本
- `.openharness/` - OpenHarness 配置
- `.claude/` - Claude Code 配置

## 使用方式
流水线会监控目标文档仓库的 stories 变更，自动更新 docs/system_design.md。
