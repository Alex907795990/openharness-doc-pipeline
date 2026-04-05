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

## API 接口定义

### 打字测试提交
**接口地址**: POST `/api/v1/typing_tests/submit`

**请求参数**:
```json
{
  "user_id": "integer",
  "language": "enum (Chinese, English)",
  "wpm": "float",
  "accuracy": "float"
}
```

**响应参数**:
```json
{
  "message": "Typing test result submitted successfully."
}
```

**验证规则**:
- 用户必须存在（游客模式除外）。
- 必须提供 WPM 和准确率。

---

### 获取个人历史成绩
**接口地址**: GET `/api/v1/typing_tests/history`

**请求头**: 
- Authorization: `Bearer <access_token>`

**响应参数**:
```json
[
  {
    "id": "integer",
    "language": "string",
    "wpm": "float",
    "accuracy": "float",
    "created_at": "timestamp"
  }
]
```

**查询参数**: 
- 按日期排序: `sort_by=date` 或按 WPM 排序: `sort_by=wpm`

---

### 获取全站排行榜
**接口地址**: GET `/api/v1/leaderboard`

**查询参数**:
- 按语言筛选: `language=Chinese` 或 `language=English`
- 分页: `page=1`（每页 100 条）

**响应参数**:
```json
[
  {
    "rank": "integer",
    "user_id": "integer",
    "best_wpm": "float"
  }
]
```

### 用户注册
**接口地址**: POST `/api/v1/users/register`

**请求参数**:
```json
{
  "phone_number": "string",
  "password": "string"
}
```

**响应参数**:
```json
{
  "message": "User registered successfully."
}
```

**验证规则**:
- 手机号格式必须合法。
- 密码长度需不小于 8 位。

---

### 用户登录
**接口地址**: POST `/api/v1/users/login`

**请求参数**:
```json
{
  "phone_number": "string",
  "password": "string"
}
```

**响应参数**:
```json
{
  "access_token": "JWT Token",
  "refresh_token": "JWT Refresh Token"
}
```

---

### 刷新 Token
**接口地址**: POST `/api/v1/users/refresh`

**请求参数**:
```json
{
  "refresh_token": "JWT Refresh Token"
}
```

**响应参数**:
```json
{
  "access_token": "New JWT Token",
  "refresh_token": "New Refresh Token"
}
```

---

### 用户信息查询
**接口地址**: GET `/api/v1/users/me`

**请求头**: 
- Authorization: `Bearer <access_token>`

**响应参数**:
```json
{
  "id": "integer",
  "phone_number": "string"
}
```

## 关键业务逻辑

1. **打字测试模块**：
    - 系统随机生成中文或英文文本。
    - 打字过程中前端实时对比正确与错误字符。
    - 计算 WPM 和准确率，并在结束后提交。

2. **成绩记录模块**：
    - 登录用户可以自动保存成绩至数据库。
    - 支持按测试时间和 WPM 查看历史成绩。
    - 保存用户的最佳成绩以用于排行榜。

3. **排行榜模块**：
    - 查询全站最高 WPM 的前 100 名。
    - 支持按语言筛选。

4. **游客模式**：
    - 无需登录可以完成测试，但不记录成绩。

1. **用户注册**：
    - 验证手机号唯一性。
    - 使用 bcrypt 对用户密码进行哈希。
    - 保存用户记录到数据库。

2. **用户登录**：
    - 校验手机号和密码是否匹配。
    - 使用 JWT 生成访问 Token 和刷新 Token。

3. **Token 有效期管理**：
    - 访问 Token 有效期为 2 小时，刷新 Token 有效期为 7 天。

4. **用户信息查询**：
    - 验证访问 Token 的合法性。
    - 返回用户 ID 和手机号。

5. **安全性要求**：
    - 密码以 bcrypt 加密存储。
    - 所有接口通过 HTTPS 访问。