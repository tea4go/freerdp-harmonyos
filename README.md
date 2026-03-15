# FreeRDP HarmonyOS NEXT

基于 FreeRDP 3.18.0 的 HarmonyOS NEXT 6.0 远程桌面客户端。

## 功能特性

### 核心功能
- ✅ RDP 协议支持（FreeRDP 3.18.0）
- ✅ RemoteFX 编解码器
- ✅ GFX 图形管道
- ✅ H.264/AVC 视频编码
- ✅ 音频重定向（本地/远程）
- ✅ 剪贴板同步
- ✅ 触控指针模式
- ✅ 虚拟键盘

### 后台与锁屏功能
- ✅ 后台保持连接（长时任务）
- ✅ 锁屏下只传音频不传图像（SuppressOutput PDU）
- ✅ 音频流永不中断

### 网络保活功能
- ✅ TCP Keepalive（15秒间隔，防NAT超时）
- ✅ RDP Synchronize 心跳（30秒间隔）
- ✅ 断网自动检测
- ✅ 智能重连策略（最多10次，递增延迟）

## 项目结构

```
entry/
├── src/main/
│   ├── ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets
│   │   ├── pages/
│   │   │   ├── Index.ets           # 主页（书签列表）
│   │   │   ├── SessionPage.ets     # 会话页面
│   │   │   ├── BookmarkPage.ets    # 书签编辑
│   │   │   ├── SettingsPage.ets    # 设置
│   │   │   └── AboutPage.ets       # 关于
│   │   ├── components/
│   │   │   ├── SessionView.ets     # 远程桌面画布
│   │   │   ├── TouchPointerView.ets # 触控指针
│   │   │   └── VirtualKeyboard.ets # 虚拟键盘
│   │   ├── services/
│   │   │   ├── LibFreeRDP.ets      # N-API 封装
│   │   │   ├── RdpBackgroundService.ets # 后台服务
│   │   │   └── NetworkManager.ets  # 网络管理
│   │   ├── model/
│   │   │   ├── BookmarkBase.ets    # 书签模型
│   │   │   └── SessionState.ets    # 会话状态
│   │   └── utils/
│   │       ├── KeyboardMapper.ets  # 键盘映射
│   │       └── ClipboardManager.ets # 剪贴板管理
│   ├── cpp/
│   │   ├── CMakeLists.txt
│   │   ├── harmonyos_freerdp.cpp   # FreeRDP 核心封装
│   │   ├── harmonyos_napi.cpp      # N-API 绑定
│   │   ├── harmonyos_event.c       # 事件队列
│   │   └── harmonyos_cliprdr.c     # 剪贴板
│   └── resources/
└── libs/
    └── arm64-v8a/                  # Native 库文件
```

## 快速开始

### 前置条件

- **DevEco Studio 6.x** - 包含 HarmonyOS SDK���NDK、构建工具
- **Windows 11** 或 **Windows 10**（推荐）或 macOS/Linux
- **ARM64 设备** - 真实设备或 ARM 模拟器（不支持 x86_64）

> ⚠️ **重要**: 项目只包含 `arm64-v8a` 架构的原生库，必须使用 ARM 设备或模拟器。

### 1. 编译 Native 库

Native 库需要在 GitHub Actions 上编译：

1. Fork 仓库 `tangwengang-del/freerdp-harmonyos`
2. 推送代码触发 GitHub Actions
3. 下载编译好的 `.so` 文件

<details>
<summary>🔧 高级：从源码重新编译（可选）</summary>

如果需要自定义编译，请参考：
- [REBUILD_NATIVE_OHOS.md](./REBUILD_NATIVE_OHOS.md) - 使用 OHOS NDK 从源码编译
- [build_windows.md](./build_windows.md) - Windows 命令行构建详细指南

</details>

### 2. 配置签名（必需）

HarmonyOS 应用必须签名才能安装。

**快速步骤**：

1. 从 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 获取调试签名文件
2. 将 `debug.p12`、`debug.cer`、`debug.p7b` 放到 `.signing/` 目录
3. 验证配置：
   ```powershell
   .\check-hap.ps1
   ```

<details>
<summary>📖 详细签名配置说明</summary>

**获取签名文件的方式**：

**方式 1: 华为开发者平台（推荐）**
1. 访问 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 登录华为开发者账号
3. 进入"我的项目" → 选择项目 → "证书" → "生成调试证书"
4. 下载三个文件：`debug.p12`、`debug.cer`、`debug.p7b`

**方式 2: DevEco Studio 自动生成**
1. 在 DevEco Studio 中打开项目
2. File → Project Structure → Signing Configs
3. 勾选 "Automatically generate signature"
4. 等待生成完成

**签名配置位置**: `build-profile.json5`

**安全提醒**:
- ⚠️ 不要将签名文件提交到 Git（已在 `.gitignore` 中配置）
- ⚠️ 不要分享签名文件给他人
- ⚠️ Debug 签名仅用于测试，生产环境需要正式签名

</details>

### 3. 编译 HarmonyOS 应用

配置签名后，使用以下方式构建：

#### 方式A：使用构建脚本（推荐）

```powershell
# 构建 debug 版本
.\build-and-sign.ps1

# 构建 release 版本
.\build-and-sign.ps1 -Release

# 清理后构建
.\build-and-sign.ps1 -Clean
```

#### 方式B：使用 DevEco Studio

1. 打开 DevEco Studio
2. File → Open → 选择项目目录
3. Build → Build Hap(s) / APP(s) → Build Hap(s)

#### 方式C：使用命令行

Windows CMD:
```cmd
build_windows.cmd
```

或直接使用 hvigorw:
```bash
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

> 📖 详细构建参数和故障排除，请参考 [build_windows.md](./build_windows.md)

### 4. 设备设置与安装

#### ⚠️ 重要：必须使用 ARM64 设备

项目只包含 `arm64-v8a` 架构的原生库，**不支持 x86_64 模拟器**。

**方案 1: 使用真实设备（推荐）**

1. **启用开发者模式**:
   - 设置 → 关于手机 → 连续点击"版本号"7次

2. **启用 USB 调试**:
   - 设置 → 系统和更新 → 开发者选项 → 开启"USB 调试"

3. **连接设备**:
   - 使用 USB 数据线连接电脑
   - 在设备上允许 USB 调试授权

**方案 2: 使用 ARM 模拟器**

1. 在 DevEco Studio 中: Tools → Device Manager
2. 点击 **+ New Emulator**
3. **选择 ARM64 架构**的系统镜像（不要选 x86_64）
4. 配置：RAM 至少 2GB，存储至少 8GB
5. 启动模拟器

**验证设备架构**:
```bash
hdc shell getprop ro.product.cpu.abi
# 应该输出: arm64-v8a
```

#### 安装应用

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

### 5. 云调试部署

构建完成后，HAP 文件可以：
- 上传到华为云调试平台
- 部署到远程测试服务器
- 通过 DevEco Studio 远程调试

## 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                    ArkTS UI Layer                           │
│  (Index, SessionPage, BookmarkPage, SettingsPage, About)    │
├─────────────────────────────────────────────────────────────┤
│                   Service Layer                             │
│  (LibFreeRDP, RdpBackgroundService, NetworkManager)         │
├─────────────────────────────────────────────────────────────┤
│                    N-API Bridge                             │
│  (harmonyos_napi.cpp)                                       │
├─────────────────────────────────────────────────────────────┤
│                  Native FreeRDP                             │
│  (harmonyos_freerdp.cpp, event, cliprdr)                    │
├─────────────────────────────────────────────────────────────┤
│                 FreeRDP Libraries                           │
│  (libfreerdp3.so, libwinpr3.so, libfreerdp-client3.so)      │
├─────────────────────────────────────────────────────────────┤
│                 Dependency Libraries                        │
│  (OpenSSL, FFmpeg, cJSON)                                   │
└─────────────────────────────────────────────────────────────┘
```

## 后台音频实现

### SuppressOutput PDU

当应用进入后台或屏幕锁定时：

```typescript
// 停止图像传输，保持音频
LibFreeRDP.setClientDecoding(instance, false);

// 恢复图像传输
LibFreeRDP.setClientDecoding(instance, true);
```

### 屏幕状态监听

```typescript
screenLock.on('screenLockChange', (isLocked: boolean) => {
  LibFreeRDP.setClientDecoding(instance, !isLocked);
});
```

## 网络保活机制

### 双层保活

1. **TCP Keepalive**（内核层）
   - 空闲 15 秒后开始探测
   - 每 15 秒发送一次探测包
   - 3 次失败后断开

2. **RDP Synchronize**（应用层）
   - 每 30 秒发送一次心跳
   - 约 8 字节，不影响服务器

### 断网重连

```typescript
// 重连策略
const delays = [1000, 5000, 10000, 20000, ...];  // 最多 10 次
```

## 权限说明

| 权限 | 用途 |
|------|------|
| INTERNET | 连接远程桌面服务器 |
| GET_NETWORK_INFO | 监测网络状态变化 |
| KEEP_BACKGROUND_RUNNING | 后台保持音频连接 |
| RUNNING_LOCK | 防止系统休眠断开连接 |

## 常见问题

### Q1: 安装失败 - "install parse native so failed"

**原因**: 使用了 x86_64 模拟器，但项目只提供 ARM64 库

**解决方案**: 使用真实设备或 ARM64 模拟器（参考上方"设备设置与安装"）

### Q2: 签名文件缺失

**症状**: `Signing file not found` 或 `SignHap` 任务失败

**解决方案**:
1. 确认 `.signing/` 目录包含三个文件：`debug.p12`、`debug.cer`、`debug.p7b`
2. 从 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 重新下载
3. 或在 DevEco Studio 中重新生成：File → Project Structure → Signing Configs

### Q3: DEVECO_SDK_HOME 错误

**症��**: `Invalid value of 'DEVECO_SDK_HOME'`

**解决方案**:
```cmd
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
```

### Q4: Bundle ID 不匹配

**症状**: 安装失败或签名验证失败

**解决方案**: 确保证书对应的 Bundle ID 与 `AppScope/app.json5` 中的 `bundleName` 一致

### Q5: Native library not loaded

**原因**: 原生库缺失或架构不匹配

**解决方案**:
1. 确认 `entry/libs/arm64-v8a/` 包含所有 `.so` 文件
2. 确保设备是 ARM64 架构
3. 如需重新编译，参考 [REBUILD_NATIVE_OHOS.md](./REBUILD_NATIVE_OHOS.md)

<details>
<summary>📖 更多故障排除</summary>

详细的故障排除指南，请参考 [build_windows.md](./build_windows.md#七故障排除)

</details>

## 高级用法

### 从源码重新编译 FreeRDP

如果需要自定义编译或使用最新版本的 FreeRDP：

- [REBUILD_NATIVE_OHOS.md](./REBUILD_NATIVE_OHOS.md) - 使用 OHOS NDK 从源码编译

### Windows 命令行构建

详细的 Windows 构建参数和环境配置：

- [build_windows.md](./build_windows.md) - 完整的 Windows 构建指南

### 生成 Release 版本

用于生产环境的正式版本：

```powershell
# 1. 生成发布证书 CSR
.\generate-release-csr.ps1

# 2. 在华为开发者平台上传 CSR 并下载正式证书

# 3. 构建 release 版本
.\build-and-sign.ps1 -Release
```

## 许可证

Apache License 2.0

基于 FreeRDP 开源项目开发。

## 致谢

- [FreeRDP](https://www.freerdp.com/) - 免费的远程桌面协议实现
- [OpenSSL](https://www.openssl.org/) - 加密库
- [FFmpeg](https://ffmpeg.org/) - 多媒体框架
