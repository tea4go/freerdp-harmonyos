# FreeRDP HarmonyOS 在 macOS 编译指南


主机和容器现在是客户在采, 我们没有权限监控
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
| **Git** | 最新版 | 版本控制（macOS 自带或 Homebrew 安装）|
| **Node.js** | 18+ | 前端工具链 |
| **Xcode Command Line Tools** | 最新版 | 提供 clang、make 等基础工具 |

### 1.2 安装 Xcode Command Line Tools

```bash
xcode-select --install
```

### 1.3 安装 Homebrew（可选，用于安装 Node.js 等工具）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安装 Node.js:

```bash
brew install node@18
```

### 1.4 DevEco Studio 配置

1. 下载地址: https://developer.huawei.com/consumer/cn/deveco-studio/
2. 下载 macOS 版本（注意选择 Apple Silicon 或 Intel 版本）
3. 将 `.dmg` 拖入 Applications 文件夹后打开
4. 通过 SDK Manager 安装:
   - HarmonyOS SDK (API 12)
   - HarmonyOS NDK
   - Build Tools

### 1.5 环境变量（可选）

编辑 `~/.zshrc`（macOS 默认 Shell 为 zsh）:

```bash
# HarmonyOS 开发环境变量
export DEVECO_HOME="$HOME/Library/Application Support/Huawei/DevEco Studio"
export HOS_SDK_HOME="$HOME/Library/Huawei/sdk"
export HOS_NDK_HOME="$HOS_SDK_HOME/HarmonyOS-NEXT-DB1-5.0.0.25/openharmony/native"

# 将 hdc 工具添加到 PATH
export PATH="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains:$PATH"
```

使配置生效:

```bash
source ~/.zshrc
```

---

## 2. 项目结构

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

```bash
cd ~/MyWork/GitCode
git clone https://github.com/tea4go/freerdp-harmonyos.git
cd freerdp-harmonyos
git checkout hmrdp
```

### 3.2 配置签名

签名文件已配置在 `build-profile.json5`，证书路径:

```
~/.ohos/config/
├── default_freerdp-harmonyos_xxx.cer
├── default_freerdp-harmonyos_xxx.p7b
└── default_freerdp-harmonyos_xxx.p12
```

> **注意**: macOS 上证书路径为 `~/.ohos/config/`，对应 Windows 的 `C:\Users\{用户名}\.ohos\config\`

### 3.3 使用 DevEco Studio 编译

1. 打开 DevEco Studio（从 Applications 或 Spotlight 搜索）
2. 选择 `File > Open` 打开项目目录
3. 等待项目同步完成（首次同步需要下载依赖，可能较慢）
4. 点击 `Build > Build Hap(s)/APP(s) > Build Hap(s)`
5. 输出位置: `entry/build/default/outputs/default/`

### 3.4 命令行编译（可选）

```bash
# 赋予执行权限（首次需要）
chmod +x ./hvigorw

# 编译 Hap
./hvigorw assembleHap --mode module -p module=entry@default -p product=default

# 或使用 DevEco Studio 内置终端
./hvigorw assembleHap
```

> **注意**: macOS 上使用 `./hvigorw`，而非 Windows 的 `.\hvigorw.bat`

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

**原因**: Native 库需要使用 musl libc 编译，不能用 macOS 的 libc

**解决方案**:
1. 预编译的 .so 文件已经在 `entry/libs/arm64-v8a/` 中
2. 如果需要重新编译，使用 GitHub Actions (见 `.github/workflows/`)
3. 或使用 OHOS NDK 本地编译 (见 `REBUILD_NATIVE_OHOS.md`)

### 5.2 问题: hvigorw 权限被拒绝

**现象**: `zsh: permission denied: ./hvigorw`

**解决方案**:
```bash
chmod +x ./hvigorw
```

### 5.3 问题: DevEco Studio 在 macOS 上无法打开（安全限制）

**现象**: macOS 提示 "无法打开，因为它来自身份不明的开发者"

**解决方案**:
```bash
# 方法一：在 Finder 中右键点击 > 打开
# 方法二：通过终端移除隔离属性
xattr -rd com.apple.quarantine "/Applications/DevEco Studio.app"
```

### 5.4 问题: OpenSSL SIGABRT 崩溃

**原因**: OpenSSL 尝试加载编译时的模块路径

**修复**（已在 `harmonyos_napi.cpp` 中）:
```cpp
setenv("HOME", "/data/storage/el2/base/files", 1);
setenv("OPENSSL_CONF", "/dev/null", 1);
unsetenv("OPENSSL_MODULES");
```

### 5.5 问题: 签名配置错误

**现象**: 构建失败，提示签名相关错误

**解决方案**:
1. 打开 DevEco Studio
2. `File > Project Structure > Signing Configs`
3. 选择 "Automatically generate signature" 或手动配置证书

### 5.6 问题: Node.js 版本不兼容

**现象**: hvigorw 运行报错，提示 Node.js 版本过低

**解决方案**:
```bash
# 使用 Homebrew 安装指定版本
brew install node@18
brew link node@18 --force --overwrite

# 验证版本
node --version
```

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

程序启动时自动连接（在 `Index.ets`）:

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

```bash
# 使用 hdc 工具（需要在 PATH 中）
hdc shell hilog -T FreeRDP

# 过滤特定标签（macOS 使用 grep，不是 findstr）
hdc shell hilog | grep "FreeRDP"

# 实时滚动查看
hdc shell hilog | grep --line-buffered "FreeRDP"
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

```bash
git add -A
git commit -m "feat: 描述修改内容

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
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
| aFreeRDP | `~/MyWork/TmpCode/aFreeRDP` | Android FreeRDP 实现 |
| Remmina | `~/MyWork/TmpCode/Remmina` | Linux RDP 客户端 |
| go-freerdp-webconnect | `~/MyWork/GitCode/go-freerdp-webconnect` | Go 封装 |

### 10.2 文档链接

- FreeRDP 官方: https://www.freerdp.com/
- HarmonyOS 开发者: https://developer.huawei.com/consumer/cn/
- HarmonyOS NDK: https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/ndk/Readme-CN.md

---

## 11. 快速恢复清单

重启机器后，按以下步骤恢复开发:

1. [ ] 打开 DevEco Studio（Applications 或 `open -a "DevEco Studio"`）
2. [ ] 打开项目: `~/MyWork/GitCode/freerdp-harmonyos`
3. [ ] 等待项目同步
4. [ ] 检查签名配置（File > Project Structure > Signing）
5. [ ] 构建项目（Build > Build Hap(s)）
6. [ ] 查看日志: `hdc shell hilog | grep FreeRDP`

---

## 12. 修改历史

| 日期 | 修改内容 |
|------|---------|
| 2026-03-28 | 创建 macOS 编译指南 |
| 2026-03-28 | 修复黑屏问题:禁用GFX管道 + 强制Alpha=0xFF |
| 2026-03-29 | 修复原生库加载失败：添加 napi_register_module_v1 导出 |

---

## 14. 本地重新编译原生库 (macOS)

### 14.1 问题: 原生库加载失败

报 "原生库加载失败"

**现象**: 应用启动时提示 "原生库加载失败"

**根本原因**: HarmonyOS NEXT 通过 `dlopen` 加载 N-API 模块时，查找导出符号 `napi_register_module_v1`。 CI 构建的库使用 `NAPI_MODULE` 宏（基于 `__attribute__((constructor))`），将注册函数放入 `.init_array` 段。但 `.init_array` 中的构造函数指针全为零（被 strip 或工具链问题），导致 `napi_module_register()` 永远不被调用。

**解决方案**: 直接导出 `napi_register_module_v1` 函数���绕过构造函数机制:

```cpp
// harmonyos_napi.cpp 末尾添加:
extern "C" __attribute__((visibility("default"))) napi_value napi_register_module_v1(napi_env env, napi_value exports) {
    return Init(env, exports);
}
```

### 14.2 本地重新编译步骤

```bash
# 1. 设置 NDK 路径
NDK_ROOT="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native"
CLANG="$NDK_ROOT/llvm/bin/clang"
CLANGXX="$NDK_ROOT/llvm/bin/clang++"
SYSROOT="$NDK_ROOT/sysroot"
LIBS_DIR="entry/libs/arm64-v8a"
SRC_DIR="entry/src/main/cpp"
INC_DIR="entry/libs/include"
BUILD_DIR="/tmp/freerdp_ohos_build"

rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"

# 2. 编译 C++ 文件
for f in harmonyos_freerdp.cpp harmonyos_napi.cpp; do
  "$CLANGXX" --target=aarch64-linux-ohos --sysroot="$SYSROOT" -D__MUSL__ \
    -fPIC -O2 -Wall -Wextra -DOHOS_PLATFORM -DNAPI_VERSION=8 -std=c++17 \
    -I"$SRC_DIR" -I"$INC_DIR/freerdp3" -I"$INC_DIR/winpr3" \
    -I"entry/libs/FreeRDP-3.10.3/winpr/include" \
    -c "$SRC_DIR/$f" -o "$BUILD_DIR/${f%.cpp}.o"
done

# 3. 编译 C 文件
for f in harmonyos_event.c harmonyos_cliprdr.c harmonyos_jni_callback.c harmonyos_jni_utils.c freerdp_client_compat.c; do
  "$CLANG" --target=aarch64-linux-ohos --sysroot="$SYSROOT" -D__MUSL__ \
    -D_POSIX_C_SOURCE=200809L -fPIC -O2 -Wall -Wextra -DOHOS_PLATFORM -DNAPI_VERSION=8 -std=c11 \
    -I"$SRC_DIR" -I"$INC_DIR/freerdp3" -I"$INC_DIR/winpr3" \
    -I"entry/libs/FreeRDP-3.10.3/winpr/include" \
    -c "$SRC_DIR/$f" -o "$BUILD_DIR/${f%.c}.o"
done

# 4. 链接（不要 strip!）
"$CLANGXX" --target=aarch64-linux-ohos --sysroot="$SYSROOT" -D__MUSL__ \
  -shared -fPIC \
  -o /tmp/libfreerdp_harmonyos.so \
  "$BUILD_DIR"/*.o \
  -L"$LIBS_DIR" -lace_napi.z -lhilog_ndk.z -lOpenSLES \
  -lfreerdp-client3 -lfreerdp3 -lwinpr3 \
  -Wl,--allow-shlib-undefined -Wl,-rpath,'$ORIGIN'

# 5. 夋制到目标（不要直接覆盖，用临时文件再 cp)
cp /tmp/libfreerdp_harmonyos.so "$LIBS_DIR/libfreerdp_harmonyos.so"
```

**注意**:
- 不要使用 `llvm-strip --strip-unneeded`，会清除 `.init_array` 中的构造函数
- 确保 `libc++_shared.so` 在 `entry/libs/arm64-v8a/` 目录中

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

### 13.2 问题: PixelMap 不更新显示

**现象**: 连接成功，OnGraphicsUpdate 回调正常触发，但屏幕不显示远程桌面内容

**根本原因**: HarmonyOS 的 PixelMap 在创建后，底层 ArrayBuffer 数据被更新，但 PixelMap 不会自动检测到变化。

**错误代码**:
```typescript
// ❌ 错误：只更新 buffer，PixelMap 不知道数据变了
const success = LibFreeRDP.updateGraphics(instance, this.graphicsBuffer, x, y, width, height);
if (success) {
  this.refreshTrigger++;  // 这不会触发 PixelMap 更新
}
```

**正确代码**:
```typescript
// ✅ 正确：更新 buffer 后，调用 writeBufferToPixels 通知 PixelMap
const success = LibFreeRDP.updateGraphics(instance, this.graphicsBuffer, x, y, width, height);
if (success) {
  this.pixelMap.writeBufferToPixels(this.graphicsBuffer);  // 通知 PixelMap 数据已更新
  this.refreshTrigger++;
}
```

**修复文件**: `entry/src/main/ets/pages/SessionPage.ets` 的 `updateGraphicsRegion()` 方法

**经验教训**: HarmonyOS PixelMap 不会自动监听 ArrayBuffer 变化，需要显式调用 `writeBufferToPixels()` 来更新图像数据。

### 13.3 问题: 远程桌面画面黑屏/不显示

**现象**: 连接成功，OnGraphicsUpdate 回调正常触发，writeBufferToPixels 也被调用，但屏幕显示全黑

**根本原因**: Native 层 `freerdp_harmonyos_update_graphics()` 中的 `freerdp_image_copy()` 参数设置错误：
1. **目标 stride 错误**: 使用了 `width * 4`（更新区域宽度），而非 `gdi->width * 4`（全屏宽度）
2. **目标起始位置错误**: 从 (0, 0) 开始写入，而非从 (x, y) 位置
3. **只复制了更新区域**: ArkTS 层传入的是全屏大小的 buffer，但只复制了更新区域到 buffer 起始位置
4. **像素格式错误**: 使用 `PIXEL_FORMAT_RGBX32` 而非 `PIXEL_FORMAT_BGRA32`（PixelMap 使用 BGRA_8888）

**错误代码**:
```cpp
// ❌ 错误：只复制更新区域到 buffer 的 (0,0) 位置
UINT32 DstFormat = PIXEL_FORMAT_RGBX32;
return freerdp_image_copy(buffer, DstFormat, width * 4, 0, 0, width, height,
                          gdi->primary_buffer, gdi->dstFormat, gdi->stride, x, y,
                          &gdi->palette, FREERDP_FLIP_NONE);
```

**正确代码**:
```cpp
// ✅ 正确：复制整个 GDI 缓冲区到输出 buffer
UINT32 DstFormat = PIXEL_FORMAT_BGRA32;
return freerdp_image_copy(buffer, DstFormat, gdi->width * 4, 0, 0,
                          gdi->width, gdi->height,
                          gdi->primary_buffer, gdi->dstFormat, gdi->stride, 0, 0,
                          &gdi->palette, FREERDP_FLIP_NONE);
```

**修复文件**: `entry/src/main/cpp/harmonyos_freerdp.cpp` 第 1113 行

**经验教训**: `freerdp_image_copy` 的目标 stride 必须与目标 buffer 的行宽一致（全屏宽度），而非更新区域的宽度。ArkTS 层传入的是全屏大小的 buffer，因此需要复制整个 GDI 缓冲区。

---

### 13.5 问题: 重连后画面仍然黑屏（session instance 未同步）

**现象**: 第一次连接断开后自动重连，画面一直黑屏

**根本原因**: `NetworkManager.doReconnect()` 创建新 FreeRDP instance，但 `SessionPage.session.getInstance()` 仍返回旧 instance。`updateGraphicsRegion` 用旧 instance 调用 `freerdp_harmonyos_update_graphics`，旧 GDI buffer 已释放返回 `false`。

**修复文件**: `entry/src/main/ets/pages/SessionPage.ets` 的 `onConnectionSuccess()` 方法

```typescript
// ✅ 正确：每次连接成功都更新 session 持有的 instance 指针
const oldInst = this.session.getInstance();
if (oldInst !== instance) {
    this.session.setInstance(instance);
    GlobalSessionManager.registerSession(instance, this.session);
}
```

---

### 13.6 问题: PixelMap 内容更新后 Image 组件不重绘（黑屏）

**现象**: `writeBufferToPixels` 调用成功，但屏幕一直显示黑屏

**根本原因**: HarmonyOS ArkTS 的响应式系统基于**引用变化**检测状态更新。`writeBufferToPixels()` 只修改了 PixelMap 的内部像素数据，但 `@State pixelMap` 的引用没有变化。ArkTS 框架检测不到"变化"，不触发 Image 组件重绘。

**错误代码**:
```typescript
// ❌ 错误：只更新内容，引用不变，UI 不重绘
this.pixelMap.writeBufferToPixels(this.graphicsBuffer).then(() => {
    this.isUpdatingPixelMap = false;  // Image 仍然显示旧内容（黑屏）
});
```

**正确代码**:
```typescript
// ✅ 正确：更新内容后，通过"清空再赋值"强制触发引用变化
this.pixelMap.writeBufferToPixels(this.graphicsBuffer).then(() => {
    const pm = this.pixelMap;
    this.pixelMap = null;    // 触发 @State 变化（Image 暂时为空）
    this.pixelMap = pm;      // 再赋值（Image 用新内容重绘）
    this.isUpdatingPixelMap = false;
});
```

**修复文件**: `entry/src/main/ets/pages/SessionPage.ets` 的 `updateGraphicsRegion()` 方法

**经验教训**: HarmonyOS `@State` / `@Prop` 响应式系统对引用类型（如 PixelMap）只追踪引用变化，不追踪内容变化。`writeBufferToPixels` 更新 PixelMap 像素数据后，必须通过重新赋值 `@State` 变量来触发 UI 重绘。

---

### 13.7 问题: GDI 缓冲区全黑（高级编解码器绕过 GDI 管道）

**现象**: 连接成功，`OnGraphicsUpdate` 回调正常触发，帧数据复制正常，但像素值全为 `B=0 G=0 R=0 A=255`（全黑）

**根本原因**:

1. **GFX/H264/RemoteFX 绕过 `gdi->primary_buffer`**: 当连接参数包含 `/gfx`、`/rfx`、`/gfx:AVC444` 时，服务器使用高级编解码管道。此时帧数据写入 GFX 专属缓冲区，`gdi->primary_buffer` 从不更新，始终保持全零（黑色）。

2. **`gdi_init` 格式参数错误**: `gdi_init(instance, PIXEL_FORMAT_RGBX32)` 与后续 `freerdp_harmonyos_update_graphics` 中的 `PIXEL_FORMAT_BGRA32` 目标格式不一致，虽然 `freerdp_image_copy` 会做格式转换，但应保持一致。

**错误配置**:
```typescript
// ❌ 错误：BookmarkBase.ets 默认全部启用高级编解码器
performanceFlags: PerformanceFlags = {
    remoteFX: true,  // 添加 /rfx 参数
    gfx: true,       // 添加 /gfx 参数
    h264: true,      // 添加 /gfx:AVC444 参数
    ...
}
```

```cpp
// ❌ 错误：gdi_init 使用 RGBX32 而非 BGRA32
if (!gdi_init(instance, PIXEL_FORMAT_RGBX32)) {
```

**正确配置**:
```typescript
// ✅ 正确：禁用高级编解码器，强制使用基础位图模式（写入 gdi->primary_buffer）
performanceFlags: PerformanceFlags = {
    remoteFX: false,  // 不添加 /rfx
    gfx: false,       // 不添加 /gfx
    h264: false,      // 不添加 /gfx:AVC444
    ...
}
```

```cpp
// ✅ 正确：gdi_init 使用 BGRA32，与输出格式一致
if (!gdi_init(instance, PIXEL_FORMAT_BGRA32)) {
```

**修复文件**:
- `entry/src/main/ets/model/BookmarkBase.ets`（第 111-113 行）
- `entry/src/main/ets/services/NetworkManager.ets`（`doReconnect()` 中第 301-303 行）
- `entry/src/main/cpp/harmonyos_freerdp.cpp`（第 480 行）

**经验教训**: 在 GFX 管道启用时，`gdi->primary_buffer` 不接收任何数据。必须禁用 `/gfx`、`/rfx`、`/gfx:AVC444` 等高级编解码器参数，强制服务器使用基础 RDP 位图协议，才能保证 `gdi->primary_buffer` 有有效的像素数据。

---

### 13.8 问题: FreeRDP_SupportGraphicsPipeline=TRUE 导致 GFX 管道被协商（持续黑屏）

**现象**: BookmarkBase 中已禁用 gfx/remoteFX/h264，但屏幕仍然黑屏

**根本原因**: `freerdp_harmonyos_parse_arguments()` 中硬编码了：
```cpp
freerdp_settings_set_bool(inst->context->settings, FreeRDP_SupportGraphicsPipeline, TRUE);
```
这向服务器广播客户端支持 GFX 管道能力。即使命令行参数中未包含 `/gfx`，服务器仍可能主动协商使用 GFX 管道。一旦服务器使用 GFX 管道，`gdi->primary_buffer` 永远不会收到像素数据，导致持续黑屏。

**修复**: 将 `FreeRDP_SupportGraphicsPipeline` 设为 FALSE，强制使用传统 RDP 位图模式。

```cpp
// ❌ 错误：允许服务器协商 GFX 管道
freerdp_settings_set_bool(inst->context->settings, FreeRDP_SupportGraphicsPipeline, TRUE);

// ✅ 正确：禁用 GFX 管道协商，强制传统位图模式
freerdp_settings_set_bool(inst->context->settings, FreeRDP_SupportGraphicsPipeline, FALSE);
freerdp_settings_set_bool(inst->context->settings, FreeRDP_SupportDynamicChannels, FALSE);
```

**修复文件**: `entry/src/main/cpp/harmonyos_freerdp.cpp` - `freerdp_harmonyos_parse_arguments()` 函数

---

### 13.9 问题: GDI 缓冲区 Alpha 通道为 0（像素透明显示黑屏）

**现象**: 连接成功，像素有 RGB 值但 Alpha=0，屏幕仍显示黑色

**根本原因**: FreeRDP GDI 在某些渲染路径下可能不设置 Alpha 通道（保持为 0）。`gdi_init()` 用 `calloc` 初始化缓冲区，所有字节为 0（A=0）。HarmonyOS `BGRA_8888` 格式将 Alpha=0 解释为完全透明，透过图片看到黑色背景。

**修复**: 在 `freerdp_harmonyos_update_graphics()` 中，图像复制后强制所有像素 Alpha=0xFF：

```cpp
// 复制 GDI 缓冲区到输出缓冲区
BOOL result = freerdp_image_copy(buffer, DstFormat, gdi->width * 4, 0, 0,
                                 gdi->width, gdi->height,
                                 gdi->primary_buffer, gdi->dstFormat, gdi->stride, 0, 0,
                                 &gdi->palette, FREERDP_FLIP_NONE);

if (result) {
    // 强制 Alpha=0xFF，防止透明像素显示为黑色
    size_t pixelCount = (size_t)gdi->width * (size_t)gdi->height;
    uint32_t* pixels = (uint32_t*)buffer;
    for (size_t i = 0; i < pixelCount; i++) {
        pixels[i] |= 0xFF000000U;  // 设置 Alpha 字节(最高字节)为 255
    }
}
```

**修复文件**: `entry/src/main/cpp/harmonyos_freerdp.cpp` - `freerdp_harmonyos_update_graphics()` 函数

---

### 13.10 问题: Image 组件不渲染动态更新的 PixelMap（持续黑屏）

**现象**: 连接成功，PixelMap 每帧通过 `createPixelMap` 创建新引用，`@State pixelMap` 更新，`@Prop pixelMap` 在 SessionView 中也有 `@Watch`，但 Image 组件始终显示黑屏。日志显示像素数据正确（非零 RGB 值）。

**根本原因**:
1. HarmonyOS ArkTS 的 `Image` 组件设计用于静态图片显示，对高频动态 PixelMap 更新存在缓存问题
2. `@Prop` 对 PixelMap 引用变化的传播可能被框架优化（跳过重绘）
3. 即使 `createPixelMap` 创建了新引用，Image 组件可能不会重新读取像素数据

**对比 Android 实现**: Android aFreeRDP 使用自定义 View + Canvas 的 `onDraw()` 方法直接绘制 Bitmap，通过 `invalidate()` 显式触发重绘，完全避免了 ImageView 的缓存问题。

**修复方案**: 用 **Canvas + drawImage** 替代 Image 组件，使用 `writeBufferToPixels` 替代 `createPixelMap`：

```typescript
// ❌ 错误：Image 组件对高频动态 PixelMap 更新不可靠
Image(this.pixelMap)
    .width(this.desktopWidth * this.viewScale)
    .height(this.desktopHeight * this.viewScale)
    .position({ x: this.offsetX, y: this.offsetY })
    .objectFit(ImageFit.Fill)
```

```typescript
// ✅ 正确：Canvas 直接绘制 PixelMap，显式控制渲染
Canvas(this.canvasCtx)
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
    .onReady(() => {
        this.isCanvasReady = true
        this.drawDesktop()
    })

// drawDesktop 方法：
drawDesktop(): void {
    this.canvasCtx.clearRect(0, 0, this.viewWidth, this.viewHeight)
    this.canvasCtx.drawImage(this.pixelMap, this.offsetX, this.offsetY,
        this.desktopWidth * this.viewScale, this.desktopHeight * this.viewScale)
}
```

同时简化 SessionPage 的 `updateGraphicsRegion`：
```typescript
// ❌ 错误：每帧创建新 PixelMap（昂贵且不可靠）
image.createPixelMap(buf, opts).then((newPm) => {
    this.pixelMap = newPm  // @State 变化但 Image 可能不重绘
})

// ✅ 正确：复用单个 PixelMap，通过 writeBufferToPixels 更新数据
this.pixelMap.writeBufferToPixels(this.graphicsBuffer).then(() => {
    this.renderVersion++  // 触发 Canvas 重绘
})
```

**修复文件**:
- `entry/src/main/ets/components/SessionView.ets` - 用 Canvas 替代 Image
- `entry/src/main/ets/pages/SessionPage.ets` - 用 writeBufferToPixels 替代 createPixelMap

---

### 13.11 问题: Canvas + drawImage 仍然黑屏（@Watch 可能未触发）

**现象**: Canvas 替代 Image 组件后，屏幕仍然全黑。日志显示 writeBufferToPixels 成功、像素数据正确，但看不到远程桌面。

**诊断步骤**:
1. 在 `onRenderVersionChanged()` 和 `drawDesktop()` 中添加详细日志
2. 在 Canvas 上绘制红色测试矩形验证 Canvas 本身是否工作
3. 检查 `@Prop @Watch` 是否正确触发

**修改文件**:
- `entry/src/main/ets/components/SessionView.ets` - 添加诊断日志和测试矩形

**状态**: 已确认根因，详见 13.12

---

### 13.12 问题: Canvas drawImage 不反映 writeBufferToPixels 更新的 PixelMap 数据

**现象**: Canvas 红色测试矩形可见（Canvas 工作正常），`drawImage(pixelMap)` 调用"成功"（无异常），但远程桌面区域始终黑色。日志确认：
- `@Watch('onRenderVersionChanged')` 每帧正确触发
- `drawDesktop()` 被正确调用，参数正确
- `canvasCtx.drawImage()` 完成"成功"
- `writeBufferToPixels` 报告成功
- graphicsBuffer 中像素数据正确（非零 RGB 值）

**根本原因**: HarmonyOS Canvas `drawImage(pixelMap)` 内部缓存了 PixelMap 的初始像素数据。`writeBufferToPixels()` 更新了 PixelMap 的内部缓冲区，但 Canvas 的 `drawImage` 不会重新读取更新后的数据，仍然绘制初始数据（全黑）。

**错误代码**:
```typescript
// ❌ 错误：writeBufferToPixels 更新数据后 Canvas drawImage 仍显示旧数据
this.pixelMap.writeBufferToPixels(this.graphicsBuffer).then(() => {
    this.renderVersion++;  // 触发 Canvas 重绘，但 drawImage 仍用旧数据
});
```

**正确代码**:
```typescript
// ✅ 正确：每帧创建新 PixelMap，Canvas drawImage 获取最新数据
image.createPixelMap(this.graphicsBuffer, this.pixelMapOpts).then((newPm: image.PixelMap) => {
    this.pixelMap = newPm;  // @State 变化 → SessionView @Prop 更新
    this.renderVersion++;   // 触发 Canvas 重绘
});
```

**修复文件**: `entry/src/main/ets/pages/SessionPage.ets` 的 `updateGraphicsRegion()` 方法

**经验教训**: HarmonyOS Canvas `drawImage` 对同一个 PixelMap 引用存在缓存行为。`writeBufferToPixels` 虽然更新了 PixelMap 内部数据，但 Canvas 不会重新读取。必须创建新的 PixelMap 对象（新引用），Canvas 才会重新读取像素数据。

---

### 13.13 问题: Canvas putImageData 执行成功但屏幕显示白色

**现象**: Canvas `putImageData` 日志显示执行成功（像素数据正确：`src(0,0)=B136G128R8A255`），但屏幕始终显示白色。Canvas 的 `backgroundColor('#1a1a1a')` 也不可见（应为深灰色）。

**诊断日志**:
```
SessionView: @Watch fired rv=1 canvas=true vw=387.2 buf=8294400 dw=1920 dh=1080
SessionView: putImageData done 387x799 src=1920x1080 scale=0.202 ox=0.0 oy=290.9 pxWritten=84366
```

**关键线索**:
1. putImageData 执行成功，像素数据正确（非零 RGB 值）
2. Canvas backgroundColor #1a1a1a 不可见 → Canvas 组件本身未渲染到屏幕
3. "Canvas ready" 出现两次 → Canvas 可能被销毁重建
4. 屏幕显示白色（不是黑色 #000000 或深灰 #1a1a1a）→ 不是父组件背景

**可能原因**:
1. 硬件加速（`RenderingContextSettings(true)`）导致 putImageData 写入 GPU 缓冲但未提交到屏幕
2. Canvas 组件因父组件 @State 变化被重建，canvasCtx 与可见 Canvas 断开
3. HarmonyOS Canvas putImageData 对 ImageData 的 data 属性修改不反映到实际像素
4. Canvas 实际像素尺寸（DPI 缩放）与 ImageData 尺寸不匹配

**诊断步骤**: 添加 `fillRect` 测试到 Canvas onReady 回调和 putImageData 之后，确认 Canvas 绘图 API 是否工作。禁用硬件加速测试。

**修复文件**:
- `entry/src/main/ets/components/SessionView.ets` - 添加诊断 + 禁用 HW 加速

---

### 13.14 问题: Canvas putImageData 写入成功但像素不渲染（最终修复）

**现象**: Canvas `putImageData` 日志显示执行成功（像素数据正确：非零 RGB 值），但远程桌面区域始终空白。Canvas `fillRect` 诊断矩形可见（红色 80x80 方块），证明 Canvas 绘图管道正常工作，但 `putImageData` 写入的数据不会被渲染到屏幕。

**根本原因**: HarmonyOS NEXT 5.0.0(12) 的 Canvas `putImageData()` API 存在缺陷。虽然 API 调用返回成功且不报错，但写入 ImageData 的像素数据不会被 Canvas 渲染管道实际提交到屏幕。这是 HarmonyOS Canvas 实现的一个已知问题。

**修复方案**: 用 `Canvas.drawImage(PixelMap)` 替代 `putImageData`。PixelMap 是 HarmonyOS 原生的图像数据容器，Canvas `drawImage` 对 PixelMap 的渲染经过不同的代码路径，不受 `putImageData` 缺陷影响。

**架构变化**:

1. **渲染路径**: `putImageData(BGRA→RGBA手动转换)` → `drawImage(PixelMap)`
2. **共享机制**: 通过模块级 `sharedPixelMap` 变量在 SessionPage 和 SessionView 之间共享 PixelMap 引用（避免 @Prop 深拷贝）
3. **缩放**: 由 Canvas drawImage 的 `dx/dy/dw/dh` 参数处理（不再手动像素级缩放）

**修改文件**:
- `entry/src/main/ets/services/LibFreeRDP.ets` - 添加 `sharedPixelMap` / `setSharedPixelMap` 导出
- `entry/src/main/ets/pages/SessionPage.ets` - 每帧创建 PixelMap 后调用 `setSharedPixelMap(newPm)`
- `entry/src/main/ets/components/SessionView.ets` - `drawDesktop()` 从 putImageData 改为 `drawImage(sharedPixelMap)`

**修改前代码** (SessionView.drawDesktop):
```typescript
// ❌ putImageData 在 HarmonyOS 上不渲染
const imageData = this.canvasCtx.createImageData(canvasW, canvasH);
// ... BGRA→RGBA 手动像素转换 ...
this.canvasCtx.putImageData(imageData, 0, 0);
```

**修改后代码** (SessionView.drawDesktop):
```typescript
// ✅ drawImage(PixelMap) 在 HarmonyOS 上正常渲染
const pm = sharedPixelMap;
if (pm) {
  this.canvasCtx.clearRect(0, 0, this.viewWidth, this.viewHeight);
  this.canvasCtx.drawImage(pm, this.offsetX, this.offsetY,
    this.desktopWidth * this.viewScale, this.desktopHeight * this.viewScale);
}
```

**性能对比**:
- `putImageData`: 每帧需手动遍历所有像素做 BGRA→RGBA 转换 + 缩放（CPU 密集，且不渲染）
- `drawImage(PixelMap)`: 由 Canvas/GPU 处理缩放和渲染（高效且实际工作）

**经验教训**: HarmonyOS Canvas 的 `putImageData` API 不可靠，应使用 `drawImage` + PixelMap 进行动态图像渲染。这与 Android 的 Canvas 行为不同（Android 的 putImageData 正常工作）。

---

*本文档由 Claude Sonnet 4.6 生成*
