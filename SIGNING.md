# HarmonyOS 应用签名配置指南

## 快速开始

### 1. 获取签名文件

从华为开发者平台获取调试签名文件：

1. 访问 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 登录华为开发者账号
3. 进入"我的项目" → 选择项目 → "证书" → "生成调试证书"
4. 下载三个文件：
   - `debug.p12` (密钥库文件)
   - `debug.cer` (证书文件)
   - `debug.p7b` (Profile文件)
5. 将文件放置到 `.signing/` 目录

### 2. 验证配置

运行验证脚本：

```powershell
.\setup-signing.ps1
```

成功时会显示：
```
[OK] Found P12 file: debug.p12
[OK] Found CER file: debug.cer
[OK] Found P7B file: debug.p7b
Signing configuration complete!
```

### 3. 构建应用

#### 方式 A：使用 DevEco Studio（推荐）

1. 打开 DevEco Studio
2. File → Open → 选择项目目录
3. Build → Build Hap(s) / APP(s) → Build Hap(s)

#### 方式 B：使用命令行

```powershell
# Debug 构建
.\build-and-sign.ps1

# Release 构建
.\build-and-sign.ps1 -Release

# 清理后构建
.\build-and-sign.ps1 -Clean
```

## 签名配置位置

签名配置在 `build-profile.json5` 中：

```json5
{
  "app": {
    "signingConfigs": [{
      "name": "default",
      "type": "HarmonyOS",
      "material": {
        "certpath": ".signing/debug.cer",
        "keyAlias": "debugKey",
        "storeFile": ".signing/debug.p12",
        "profile": ".signing/debug.p7b"
      }
    }]
  }
}
```

## 构建输出

构建成功后，HAP 文件位于：

```
entry/build/default/outputs/default/entry-default-signed.hap
```

## 常见问题

### Q1: 签名文件缺失

**症状**: `Signing file not found` 或 `SignHap` 任务失败

**解决**:
1. 确认 `.signing/` 目录中包含三个签名文件
2. 运行 `.\setup-signing.ps1` 验证
3. 如果缺失，从华为开发者平台重新下载

### Q2: Bundle ID 不匹配

**症状**: 安装失败或签名验证失败

**解决**:
- 确保证书对应的 Bundle ID 与 `AppScope/app.json5` 中的 `bundleName` 一致
- 当前 Bundle ID: `com.example.myapplication`

### Q3: 在其他机器上构建

**解决**:
1. 安装 DevEco Studio
2. 用 DevEco Studio 打开项目，生成新的 Debug 签名
3. 或手动从华为开发者平台下载签名文件到 `.signing/` 目录

## 安全提醒

⚠️ **重要**：
- 签名文件包含敏感信息，不要提交到 Git（已在 `.gitignore` 中配置）
- 不要分享签名文件给他人
- Debug 签名仅用于测试，生产环境需要正式签名
- 定期备份签名文件到安全位置

## 相关文档

- [README.md](./README.md) - 项目主文档
- [build_windows.md](./build_windows.md) - Windows 构建详细指南
- [华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-signing-V5)
