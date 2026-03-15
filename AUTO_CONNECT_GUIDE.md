# 🚀 自动连接调试模式配置完成

## ✅ 已完成的修改

我已经修改了 [entry/src/main/ets/pages/Index.ets](entry/src/main/ets/pages/Index.ets) 文件，添加了**启动时自动连接**功能：

### 修改内容

1. **添加了自动连接开关**（第33行）：
   ```typescript
   @State autoConnectOnStart: boolean = true;  // 设置为 false 可禁用自动连接
   ```

2. **在 `aboutToAppear` 中添加自动连接逻辑**：
   ```typescript
   // 🚀 调试模式：自动快速连接（方便调试）
   if (this.autoConnectOnStart && LibFreeRDP.isNativeLoaded()) {
     console.info(`${TAG}: Auto-connect enabled, connecting in 500ms...`);
     setTimeout(() => {
       this.quickConnect();
     }, 500);  // 延迟500ms，确保页面完全加载
   }
   ```

3. **默认连接参数已配置**：
   - 主机：`192.168.52.127`
   - 端口：`3389`
   - 用户名：`administrator`
   - 密码：`testing123`

## 🔨 如何重新编译和运行

### 方法1：使用DevEco Studio（推荐）

1. 在 DevEco Studio 中打开项目
2. 点击 **Build** → **Rebuild Project**
3. 点击 **Run** → **Run 'entry'** 或按 `Shift+F10`
4. 应用��自动安装到真机并启动
5. **应用启动后500ms会自动连接到远程桌面！**

### 方法2：命令行编译（如果有hvigorw）

```bash
# 编译
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 安装到设备
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" install -r entry/build/default/outputs/default/entry-default-signed.hap

# 启动应用
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" shell aa start -a EntryAbility -b com.yjsoft.freerdp
```

## 🎯 使用效果

- ✅ 应用启动后 **自动连接** 到 `192.168.52.127:3389`
- ✅ 使用预设的用户名和密码
- ✅ 无需手动操作，直接进入远程桌面
- ✅ 大幅提升调试效率！

## ⚙️ 配置选项

### 修改连接参数

如果需要连接到其他服务器，修改 [Index.ets](entry/src/main/ets/pages/Index.ets#L24-L27) 中的默认值：

```typescript
@State quickConnectHost: string = '你的服务器IP';
@State quickConnectPort: string = '3389';
@State quickConnectUser: string = '你的用户名';
@State quickConnectPassword: string = '你的密码';
```

### 禁用自动连接

如果需要恢复手动连接模式，修改第33行：

```typescript
@State autoConnectOnStart: boolean = false;  // 改为 false
```

## 📊 查看连接日志

```bash
# 监控连接过程
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" hilog -x | grep -E "(IndexPage|SessionPage|FreeRDP)"
```

## 🐛 故障排除

### 如果自动连接失败

1. **检查服务器是否可达**：
   ```bash
   ping 192.168.52.127
   telnet 192.168.52.127 3389
   ```

2. **检查用户名密码**：
   - 确认第27行的密码正确
   - 确认第26行的用户名正确

3. **查看日志**：
   ```bash
   "/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" hilog -x | grep -A 20 "Auto-connect"
   ```

4. **临时禁用自动连接**：
   - 将 `autoConnectOnStart` 改为 `false`
   - 重新编译
   - 使用手动快速连接功能

## 🎉 调试流程

现在你的调试流程变得超级简单：

1. **在DevEco Studio中点击 Run** (或按 `Shift+F10`)
2. **等待几秒钟**
3. **自动进入远程桌面！**

无需任何手动操作！🚀

## 📝 注意事项

- ⚠️ **仅用于开发调试**：生产环境请禁用自动连接
- ⚠️ **密码安全**：不要将包含真实密码的代码提交到Git
- ⚠️ **网络要求**：确保设备和服务器在同一网络

## 🔄 恢复正常模式

如果需要恢复正常的手动连接模式：

1. 将 `autoConnectOnStart` 改为 `false`
2. 重新编译
3. 应用启动后会显示书签列表，需要手动点击连接
