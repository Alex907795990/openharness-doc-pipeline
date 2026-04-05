# 系统设计文档

## 核心数据模型

```yaml
TypingTest:
  - id: integer (primary key)
  - user_id: integer (foreign key to User)
  - language: enum (values: 'Chinese', 'English')
  - wpm: float
  - accuracy: float
  - created_at: timestamp

Leaderboard:
  - id: integer (primary key)
  - user_id: integer (foreign key to User)
  - language: enum (values: 'Chinese', 'English')
  - best_wpm: float
```

```yaml
User:
  - id: integer (primary key)
  - phone_number: string (unique)
  - password_hash: string
```

```yaml
VisualEffects:
  - style_id: integer (primary key)
  - name: string (e.g., 'Cyberpunk')
  - typing_animation: string (e.g., 'impact')
  - success_feedback: string (e.g., 'success sound')
  - failure_feedback: string (e.g., 'error sound')
```

## API 接口定义

### 获取网页视觉效果
**接口地址**: GET `/api/v1/visual_effects`

**响应参数**:
```json
[
  {
    "style_id": "integer",
    "name": "string",
    "typing_animation": "string",
    "success_feedback": "string",
    "failure_feedback": "string"
  }
]
```

---

## 关键业务逻辑

1. **网页主题可配置**：
    - 用户可以通过选择视觉效果，定义网页的主题风格。
    - 默认支持的样式包括赛博朋克风格。

2. **视觉效果动态更新**：
    - 当用户在打字时触发动画。
    - 成功或失败时根据配置提供反馈声音或提示。