# FreeRDP HarmonyOS 在 Windows 编译指南

## 项目概述

本项目是基于 FreeRDP 3.x 的 HarmonyOS NEXT 远程桌面客户端。

- **仓库地址**: https://github.com/tea4go/freerdp-harmonyos
- **当前分支**: `hmrdp`
- **目标平台**: HarmonyOS NEXT 5.0.0(12)
- **架构**: arm64-v8a

---

## 1. 开发环境配置

### 1.1 必需软件

| 软件 | 版本 | 说明 |
|------|------|------|
| **DevEco Studio** | 5.0+ | HarmonyOS 官方 IDE |
| **HarmonyOS SDK** | 5.0.0(12) | 目标 SDK 版本 |
| **HarmonyOS NDK** | r10+ | 用于编译 Native C/C++ 代码 |
| **Git** | 最新版 | 版本控制 |
| **Node.js** | 18+ | 前端工具链 |

### 1.2 DevEco Studio 配置

1. 下载地址: https://developer.huawei.com/consumer/cn/deveco-studio/
2. 安装后，通过 SDK Manager 安装:
   - HarmonyOS SDK (API 12)
   - HarmonyOS NDK
   - Build Tools

### 1.3 环境变量 (可选)

```powershell
# 添加到系统环境变量
DEVECO_HOME=C:\Program Files\Huawei\DevEco Studio
HOS_SDK_HOME=%DEVECO_HOME%\sdk
HOS_NDK_HOME=%HOS_SDK_HOME%\HarmonyOS-NEXT-DB1-5.0.0.25\openharmony\native
```

---

## 2. 项��结构

```
freerdp-harmonyos/
├── entry/
│   ├── src/main/
│   │   ├── ets/                    # ArkTS 代码
│   │   │   ├── pages/              # 页面
│   │   │   │   ├── Index.ets       # 主页（自动连接）
│   │   │   │   └── SessionPage.ets # 会话页面
│   │   │   ├── services/
│   │   │   │   └── LibFreeRDP.ets  # N-API 封装
│   │   │   └── components/
│   │   │       └── SessionView.ets # 远程桌面渲染
│   │   ├── cpp/                    # Native C/C++ 代码
│   │   │   ├── CMakeLists.txt      # CMake 配置
│   │   │   ├── harmonyos_freerdp.cpp  # FreeRDP 核心封装
│   │   │   └── harmonyos_napi.cpp  # N-API 绑定
│   │   └── resources/
│   └── libs/
│       └── arm64-v8a/              # 预编译的 .so 库
│           ├── libfreerdp3.so
│           ├── libfreerdp-client3.so
│           ├── libwinpr3.so
│           └── libfreerdp_harmonyos.so
├── build-profile.json5             # 构建配置
└── hvigor/                         # Hvigor 构建系统
```

---

## 3. 编译步骤

### 3.1 克隆项目

```powershell
cd D:\MyWork\GitCode
git clone https://github.com/tea4go/freerdp-harmonyos.git
cd freerdp-harmonyos
git checkout hmrdp
```

### 3.2 配置签名

签名文件已配置在 `build-profile.json5`，证书路径:
```
C:\Users\{用户名}\.ohos\config\
├── default_freerdp-harmonyos_xxx.cer
├── default_freerdp-harmonyos_xxx.p7b
└── default_freerdp-harmonyos_xxx.p12
```

### 3.3 使用 DevEco Studio 编译

1. 打开 DevEco Studio
2. 选择 `File > Open` 打开项目目录
3. 等待项目同步完成
4. 点击 `Build > Build Hap(s)/APP(s) > Build Hap(s)`
5. 输出位置: `entry/build/default/outputs/default/`

### 3.4 命令行编译 (可选)

```powershell
# 如果 hvigorw 在 PATH 中
hvigorw assembleHap --mode module -p module=entry@default -p product=default

# 或使用 DevEco Studio 内置终端
.\hvigorw.bat assembleHap
```

---

## 4. 关键代码文件说明

### 4.1 Native 层 (C++)

| 文件 | 功能 |
|------|------|
| `harmonyos_freerdp.cpp` | FreeRDP 核心封装，处理连接、图形更新 |
| `harmonyos_napi.cpp` | N-API 绑定，暴露接口给 ArkTS |
| `harmonyos_event.c` | 事件队列处理 |
| `harmonyos_cliprdr.c` | 剪贴板重定向 |

### 4.2 ArkTS 层

| 文件 | 功能 |
|------|------|
| `LibFreeRDP.ets` | N-API 封装，提供静态方法 |
| `SessionPage.ets` | 会话页面，处理图形渲染 |
| `SessionView.ets` | 远程桌面显示组件 |

---

## 5. 常见问题及解决方案

### 5.1 问题: Native 库加载失败

**现象**: 应用启动时提示 "原生库加载失败"

**原因**: Native 库需要使用 musl libc 编译，不能用 glibc

**解决方案**:
1. 预编译的 .so 文件已经在 `entry/libs/arm64-v8a/` 中
2. 如果需要重新编译，使用 GitHub Actions (见 `.github/workflows/`)
3. 或使用 OHOS NDK 本地编译 (见 `REBUILD_NATIVE_OHOS.md`)

### 5.2 问题: 图形不显示 (已修复)

**现象**: 连接成功但屏幕为黑

**原因**:
1. `g_onGraphicsUpdate` 回调被注释掉
2. `g_onSettingsChanged` 和 `g_onConnectionSuccess` 回调被跳过

**修复** (commit `171373b`):
```cpp
// harmonyos_freerdp.cpp - 重新启用回调
if (g_onGraphicsUpdate) {
    g_onGraphicsUpdate((int64_t)(uintptr_t)context->instance, x1, y1, x2 - x1, y2 - y1);
}

if (g_onSettingsChanged) {
    g_onSettingsChanged((int64_t)(uintptr_t)instance, width, height, bpp);
}
```

### 5.3 问题: OpenSSL SIGABRT 崩溃

**原因**: OpenSSL 尝试加载编译时的模块路径

**修复** (已在 `harmonyos_napi.cpp` 中):
```cpp
setenv("HOME", "/data/storage/el2/base/files", 1);
setenv("OPENSSL_CONF", "/dev/null", 1);
unsetenv("OPENSSL_MODULES");
```

### 5.4 问题: 签名配置错误

**现象**: 构建失败，提示签名相关错误

**解决方案**:
1. 打开 DevEco Studio
2. `File > Project Structure > Signing Configs`
3. 选择 "Automatically generate signature" 或手动配置证书

---

## 6. 图形渲染管道架构

```
┌─────────────────────────────────────────────────────────────┐
│                    RDP Server                                │
│                    (192.168.100.226:3389)                   │
└─────────────────────────┬───────────────────────────────────┘
                          │ RDP Protocol
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 FreeRDP Native Layer                         │
│  harmonyos_freerdp.cpp                                       │
│  - gdi->primary_buffer ( framebuffer)                        │
│  - harmonyos_end_paint() -> g_onGraphicsUpdate callback      │
└─────────────────────────┬───────────────────────────────────┘
                          │ N-API Thread-Safe Function
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 N-API Bridge                                 │
│  harmonyos_napi.cpp                                          │
│  - OnGraphicsUpdateImpl() -> TSFN                            │
│  - freerdpUpdateGraphics() -> copy framebuffer to buffer     │
└─────────────────────────┬───────────────────────────────────┘
                          │ ArkTS Callback
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 ArkTS Layer                                  │
│  LibFreeRDP.ets                                              │
│  - UIEventListener.OnGraphicsUpdate(x, y, w, h)              │
│  - updateGraphics(instance, buffer, x, y, w, h)              │
└─────────────────────────┬───────────────────────────────────┘
                          │ State Update
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 UI Layer                                     │
│  SessionPage.ets                                             │
│  - graphicsBuffer: ArrayBuffer                               │
│  - pixelMap: image.PixelMap                                  │
│  - createPixelMap() -> create from buffer                    │
│  - updateGraphicsRegion() -> copy from native                │
└─────────────────────────┬───────────────────────────────────┘
                          │ Render
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 Display                                      │
│  SessionView.ets                                             │
│  - Image(this.pixelMap)                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 默认连接配置

程序启动时自动连接 (在 `Index.ets`):

```typescript
quickConnectHost: string = '192.168.100.226';
quickConnectPort: string = '3389';
quickConnectUser: string = 'tony';
quickConnectPassword: string = 'testing123';
```

修改位置: `entry/src/main/ets/pages/Index.ets` 第 24-27 行

---

## 8. 日志调试

### 8.1 查看 HarmonyOS 日志

```powershell
# 使用 hdc 工具
hdc shell hilog -T FreeRDP

# 过滤特定标签
hdc shell hilog | findstr "FreeRDP"
```

### 8.2 关键日志标签

| 标签 | 说明 |
|------|------|
| `FreeRDP` | Native 层主日志 |
| `FreeRDP.NAPI` | N-API 层日志 |
| `SessionPage` | 会话页面日志 |
| `LibFreeRDP` | ArkTS 封装层日志 |

### 8.3 关键日志点

```
# 连接流程
harmonyos_pre_connect: ENTER
harmonyos_post_connect: ENTER
harmonyos_post_connect: Desktop size: 1920x1080, bpp: 32
OnSettingsChanged 1920x1080@32
OnConnectionSuccess

# 图形更新
harmonyos_end_paint: frame=0, region=[0,0,1920,1080]
OnGraphicsUpdate: region=(0,0,1920,1080)
updateGraphicsRegion: copying data
```

---

## 9. Git 操作

### 9.1 提交代码

```powershell
git add -A
git commit -m "feat: 描述修改内容

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push origin hmrdp
```

### 9.2 最近提交

| Commit | 说明 |
|--------|------|
| `171373b` | feat: 实现远程桌面图形渲染管道 |
| `37b75e4` | 之前的修复 |

---

## 10. 参考资源

### 10.1 参考项目

| 项目 | 路径 | 说明 |
|------|------|------|
| aFreeRDP | `C:\MyWork\TmpCode\aFreeRDP` | Android FreeRDP 实现 |
| Remmina | `C:\MyWork\TmpCode\Remmina` | Linux RDP 客户端 |
| go-freerdp-webconnect | `C:\MyWork\GitCode\go-freerdp-webconnect` | Go 封装 |

### 10.2 文档链接

- FreeRDP 官方: https://www.freerdp.com/
- HarmonyOS 开发者: https://developer.huawei.com/consumer/cn/
- HarmonyOS NDK: https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/ndk/Readme-CN.md

---

## 11. 快速恢复清单

重启机器后，按以下步骤恢复开发:

1. [ ] 打开 DevEco Studio
2. [ ] 打开项目: `D:\MyWork\GitCode\freerdp-harmonyos`
3. [ ] 等待项目同步
4. [ ] 检查签名配置 (File > Project Structure > Signing)
5. [ ] 构建项目 (Build > Build Hap(s))
6. [ ] 查看日志: `hdc shell hilog -T FreeRDP`

---

## 12. 修改历史

| 日期 | 修改内容 |
|------|---------|
| 2026-03-28 | 修复 SIGABRT 崩溃：替换 freerdp_settings_get_uint32() 为直接成员访问 |
| 2026-03-28 | 实现远程桌面图形渲染管道修复 |
| 2026-03-28 | 添加自动启动连接功能 |
| 2026-03-28 | 创建本文档 |

---

## 13. 关键技术问题及解决方案

### 13.1 问题: freerdp_settings_get_uint32() 导致 SIGABRT 崩溃

**现象**: 连接成功后应用立即崩溃 (SIGABRT)

**根本原因**: FreeRDP 库内部使用 `WINPR_ASSERT` 宏进行参数验证。当检测到无效参数时触发 `abort()`。

**错误代码**:
```cpp
// ❌ 错误：会触发 abort()
UINT32 width = freerdp_settings_get_uint32(settings, FreeRDP_DesktopWidth);
UINT32 height = freerdp_settings_get_uint32(settings, FreeRDP_DesktopHeight);
UINT32 bpp = freerdp_settings_get_uint32(settings, FreeRDP_ColorDepth);
```

**正确代码**:
```cpp
// ✅ 正确：直接访问成员变量
UINT32 width = settings->DesktopWidth;
UINT32 height = settings->DesktopHeight;
UINT32 bpp = settings->ColorDepth;
```

**修复文件**: `entry/src/main/cpp/harmonyos_freerdp.cpp`

**受影响的函数**:
- `harmonyos_desktop_resize()` - 第 291-293 行
- `harmonyos_post_connect()` - 第 483-485 行
- `freerdp_harmonyos_set_client_decoding()` - 第 1305-1306 行
- `freerdp_harmonyos_enter_background_mode()` - 第 1385-1386 行
- `freerdp_harmonyos_exit_background_mode()` - 第 1425-1426 行
- `freerdp_harmonyos_request_refresh()` - 第 1609-1610 行

**经验教训**: 在 HarmonyOS/musl libc 环境下，避免使用可能触发 abort() 的 FreeRDP API 函数，改用直接成员访问更安全。

---

*本文档由 Claude Opus 4.5 生成*
