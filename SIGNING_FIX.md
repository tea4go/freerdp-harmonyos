# 签名问题修复指南

## 问题
签名文件不存在：
```
C:\Users\tony\.ohos\config\default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.cer
C:\Users\tony\.ohos\config\default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.p12
C:\Users\tony\.ohos\config\default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.p7b
```

## 解决方案（在DevEco Studio中操作）

### 步骤 1: 打开项目
1. 启动 DevEco Studio
2. File → Open → 选择 `D:\MyWork\GitCode\freerdp-harmonyos`

### 步骤 2: 生成签名
1. File → Project Structure（或按 Ctrl+Alt+Shift+S）
2. 左侧选择 Project → Signing Configs
3. 点击 **Automatically generate signature** 按钮
4. 等待生成完成（会显示绿色勾选标记）
5. 点击 OK

### 步骤 3: 重新构建
1. Build → Clean Project
2. Build → Rebuild Project

### 步骤 4: 运行
1. 点击 Run 按钮（绿色三角形）
2. 选择设备：192.168.52.79:45913
3. 等待安装完成

## 或者使用命令行（签名生成后）

```bash
# 设置环境变量
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk

# 重新构建
cd D:\MyWork\GitCode\freerdp-harmonyos
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug

# 安装
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" install -r entry\build\default\outputs\default\entry-default-signed.hap

# 启动
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" shell aa start -a EntryAbility -b com.yjsoft.freerdp
```

## 验证
运行后查看日志：
```bash
"C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" hilog -x | findstr "SessionPage OnGraphics PixelMap"
```

应该看到：
- OnGraphicsResize: 1920x1080@32bpp
- PixelMap created: 1920x1080
- OnGraphicsUpdate
- updateGraphics

这表示远程桌面画面正在正常更新！
