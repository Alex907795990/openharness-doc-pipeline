### 架构变更记录
- 新增了用户注册与登录功能，包括以下接口：用户注册 (`POST /api/v1/users/register`)、用户登录 (`POST /api/v1/users/login`)、刷新 Token (`POST /api/v1/users/refresh`)、用户信息查询 (`GET /api/v1/users/me`)。
- 核心安全要求：密码采用 bcrypt 哈希存储，Token 设置有效期（访问 Token 为 2 小时，刷新 Token 为 7 天）。