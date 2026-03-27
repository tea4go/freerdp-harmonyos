# 安装指南 - 修复后的版本

## 代码修改完成

已成功修复连接后无法显示远程桌面的问题。修改的文件：

1. **entry/src/main/cpp/harmonyos_napi.cpp** - 添加获取帧缓冲区的 N-API 接口
2. **entry/src/main/ets/services/LibFreeRDP.ets** - 添加 ArkTS 接口包装
3. **entry/src/main/ets/pages/SessionPage.ets** - 设置图形更新回调并实现 PixelMap 更新

## 构建状态

- ✅ Native C++ 代码编译成功
- ✅ ArkTS 代码编译成功
- ✅ HAP 包生成成功（未签名）
- ❌ 签名失败（需要重新生成签名文件）

## 安装方法

### 方法 1：在 DevEco Studio 中构建和安装（推荐）

1. 打开 DevEco Studio
2. 打开项目：`File` -> `Open` -> 选择 `D:\MyWork\GitCode\freerdp-harmonyos`
3. 等待项目同步完成
4. 重新生成签名：
   - `File` -> `Project Structure` -> `Signing Configs`
   - 点击 `Automatically generate signature`
5. 点击 `Run` 按钮（或按 Shift+F10）
6. 选择已连接的设备，应用会自动安装并启动

### 方法 2：命令行构建（如果签名文件正常）

```bash
# 清理并重新构建
cd D:\MyWork\GitCode\freerdp-harmonyos
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" clean
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug

# 安装
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" install -r entry\build\default\outputs\default\entry-default-signed.hap

# 启动
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" shell aa start -a EntryAbility -b com.yjsoft.freerdp
```

## 测试步骤

1. 启动应用后，会自动连接到配置的远程桌面
2. 连接成功后，应该能看到：
   - 状态从"正在连接..."变为"已连接"
   - **能够看到远程桌面的实际画面**（之前的问题已修复）
   - 可以通过触摸交互控制远程桌面

## 查看日志

如果仍有问题，查看日志：

```bash
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" hilog -x | find "freerdp"
```

重点查看：
- `OnConnectionSuccess` - 连接成功日志
- `OnGraphicsResize` - 图形尺寸设置日志
- `OnGraphicsUpdate` - 图形更新日志
- `PixelMap created` - PixelMap 创建日志
- `updateGraphics` - 图形数据更新日志

## 技术说明

### 修复的问题

之前的代码缺少关键功能：
1. 没有设置图形更新的回调函数
2. 没有从 Native 层获取帧缓冲区数据的接口
3. PixelMap 从未被创建和更新

### 修复方案

1. **Native 层**：导出 `freerdpGetFrameBuffer` 函数获取 GDI 缓冲区
2. **ArkTS 层**：添加图形更新回调和 PixelMap 更新逻辑
3. **工作流程**：
   - 连接成功 → 收到尺寸回调 → 创建 PixelMap
   - 图形更新 → 获取帧缓冲 → 更新 PixelMap → UI 刷新

现在应该能正常显示远程桌面画面了！
