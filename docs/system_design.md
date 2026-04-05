# 系统设计文档

## 核心数据模型

```yaml
User:
  - id: integer (primary key)
  - phone_number: string (unique)
  - password_hash: string
```

## API 接口定义

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