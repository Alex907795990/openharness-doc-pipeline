#!/bin/bash
set -e

echo "🚀 开始初始化 OpenHarness 自动化文档流水线..."

# 1. 创建必要的目录
mkdir -p oh-story oh-gen-doc .github/workflows

# 2. 写入 GitHub Actions 工作流文件
cat << 'EOF' > .github/workflows/oh_doc_pipeline.yml
name: Auto Generate System Design Docs

on:
  push:
    paths:
      - 'oh-story/**.md'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
          
      - uses: Alex907795990/openharness-doc-pipeline@main
        with:
          api_key: ${{ secrets.OPENHARNESS_API_KEY }}
EOF

echo "✅ 初始化完成！"
echo ""
echo "👉 下一步操作指南："
echo "1. 请在当前 GitHub 仓库的 Settings -> Secrets and variables -> Actions 中添加一个 Secret："
echo "   Name: OPENHARNESS_API_KEY"
echo "   Value: 你的大模型 API Key"
echo "2. 在 oh-story/ 目录下编写你的需求文档 (.md)"
echo "3. 提交代码 (git add . && git commit -m '...' && git push) 即可自动触发文档生成！"
