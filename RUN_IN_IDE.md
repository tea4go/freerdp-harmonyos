# 运行指南

## 修改说明

已修复关键Bug：
1. **回调参数错误** - `CallJS_ResizeOrSettings` 传递了错误的参数，导致 PixelMap 创建失败
2. **透明度问题** - 添加 `alphaType: image.AlphaType.OPAQUE` 解决黑屏问题

## 在 DevEco Studio 中运行

由于命令行签名工具存在问题，请在 DevEco Studio 中运行：

1. **打开项目**
   ```
   文件 → 打开 → D:\MyWork\GitCode\freerdp-harmonyos
   ```

2. **构建并运行**
   - 点击 Run 按钮（绿色三角形）
   - 或按快捷键：**Shift + F10**
   - 选择设备：192.168.52.79:45913

3. **查看效果**
   - 应用启动后会自动连接 192.168.100.226:3389
   - **现在应该能看到远程桌面的真实内容了！**

## 修复内容

### 文件修改清单：
1. **entry/src/main/cpp/harmonyos_napi.cpp:141-158**
   - 修复 `CallJS_ResizeOrSettings` 参数从 4 个改为 3 个
   - 移除错误的 instance ID 参数

2. **entry/src/main/ets/pages/SessionPage.ets:298**
   - 添加 `alphaType: image.AlphaType.OPAQUE`
   - 解决 RGBX32 → RGBA8888 格式导致的透明度问题

## 预期效果

查看日志应该看到：
```
SessionPage: PixelMap created: 1920x1080 (OPAQUE)
SessionPage: Frame buffer received, size: 8294400 bytes
SessionPage: Buffer written to PixelMap successfully
```

设备屏幕应该显示 Windows 远程桌面的真实画面，而不是黑屏。
