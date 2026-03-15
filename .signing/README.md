# HarmonyOS 签名文件

此目录包含 HarmonyOS 应用的调试签名文件。

## 必需文件

将以下三个文件放置在此目录中：

1. **debug.p12** - 密钥库文件（包含私钥）
2. **debug.cer** - 证书文件（包含公钥信息）
3. **debug.p7b** - Profile 文件（应用签名配置）

## 如何获取签名文件

### 方式 1: 华为开发者平台（推荐）

1. 访问 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 登录华为开发者账号
3. 进入"我的项目" → 选择项目 → "证书" → "生成调试证书"
4. 下载三个文件并放到此目录

### 方式 2: DevEco Studio 自动生成

1. 在 DevEco Studio 中打开项目
2. File → Project Structure → Signing Configs
3. 勾选 "Automatically generate signature"
4. 等待生成完成

## 安全提醒

⚠️ **重要**：
- **不要**将签名文件提交到 Git（已在 `.gitignore` 中配置）
- **不要**分享签名文件给他人
- Debug 签名仅用于测试，生产环境需要正式签名
- 定期备份签名文件到安全位置

## 验证配置

运行验证脚本：

```powershell
.\check-hap.ps1
```

## 构建应用

配置完成后，构建应用：

```powershell
# 使用构建脚本（推荐）
.\build-and-sign.ps1

# 或直接使用 hvigorw
.\build_windows.cmd
```

## 相关资源

- [项目主文档](../README.md)
- [Windows 构建指南](../build_windows.md)
- [华为签名配置文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-signing-V5)
