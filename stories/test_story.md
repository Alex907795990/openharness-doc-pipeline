# 用户注册与登录功能

## 业务需求描述

系统需要支持用户注册和登录功能，具体需求如下：

1. **用户注册**：用户通过手机号+密码注册账号，需要验证手机号的唯一性。
2. **用户登录**：支持手机号+密码登录，登录成功后返回 JWT Token。
3. **Token 有效期**：访问 Token 有效期为 2 小时，刷新 Token 有效期为 7 天。
4. **密码安全**：密码需要使用 bcrypt 加密存储，不允许明文存储。

## 验收标准

- 注册接口：`POST /api/v1/users/register`
- 登录接口：`POST /api/v1/users/login`
- 刷新 Token：`POST /api/v1/users/refresh`
- 用户信息查询：`GET /api/v1/users/me`（需要认证）
