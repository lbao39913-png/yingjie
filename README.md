# 影界

合法影视内容聚合与播放器。当前完成 Phase 1：项目骨架、Theme、Router、数据模型、API 层。

## 切换服务器

只改 `lib/core/config/api_config.dart` 里的 `ApiConfig.baseUrl`。

开发环境默认走 Mock API，生产环境走远程 API。开关在 `lib/core/config/app_config.dart` 的 `AppConfig.env`。

Mock 目录只包含 Creative Commons / 公开样片，不含未授权影视资源。
