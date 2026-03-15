# FreeRDP HarmonyOS - 命令快速参考卡片

> 📋 打印此文件并放在手边，方便随时查阅！

## 🚀 最常用命令

### 设备管理
```bash
# 列出设备
hdc list targets

# 检查架构
hdc shell getprop ro.product.cpu.abi
```

### 应用生命周期
```bash
# 安装
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 启动
hdc shell aa start -a EntryAbility -b com.yjsoft.freerdp

# 停止
hdc shell aa force-stop com.yjsoft.freerdp

# 卸载
hdc uninstall com.yjsoft.freerdp
```

### 日志查看
```bash
# 实时日志
hdc hilog -x | grep "freerdp"

# 最近50行
hdc shell hilog -x | grep "freerdp" | tail -50

# 保存到文件
hdc hilog -x > debug.log
```

### 快速重启
```bash
# 一键重启
hdc shell aa force-stop com.yjsoft.freerdp && hdc shell aa start -a EntryAbility -b com.yjsoft.freerdp
```

## 🔨 编译命令

### 快速编译
```bash
# Debug 版本
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# Release 版本
hvigorw assembleHap --mode module -p product=default -p buildMode=release
```

### 清理
```bash
# 清理构建
hvigorw clean

# 清理并重新编译
hvigorw clean && hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

## 📱 调试技巧

### 网络诊断
```bash
# 检查RDP连接
hdc shell netstat -anp | grep 3389

# 测试连通性
hdc shell ping -c 4 <服务器IP>
```

### 性能监控
```bash
# 查看进程
hdc shell ps -ef | grep freerdp

# 查���CPU/内存
hdc shell top -n 1 | grep freerdp
```

### 文件操作
```bash
# 发送文件到设备
hdc file send local.txt /data/local/tmp/

# 从设备获取文件
hdc file recv /data/local/tmp/remote.txt ./
```

## 🎯 故障排除

### 常见问题
```bash
# 1. 应用安装失败
hdc uninstall com.yjsoft.freerdp
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 2. 检查应用是否运行
hdc shell ps -ef | grep freerdp

# 3. 清空日志重新查看
hdc shell hilog -r
hdc hilog -x | grep "freerdp"

# 4. 检查权限
hdc shell bm dump -n com.yjsoft.freerdp | grep "permission"
```

## 📊 日志过滤技巧

### 按级别过滤
```bash
# 只看错误
hdc hilog -x | grep -E "ERROR|FATAL"

# 只看警告及以上
hdc hilog -x | grep -E "ERROR|WARN|FATAL"

# 只看调试信息
hdc hilog -x | grep "DEBUG"
```

### 按内容过滤
```bash
# 连接相关
hdc hilog -x | grep -i "connect"

# 认证相关
hdc hilog -x | grep -i "auth"

# 网络相关
hdc hilog -x | grep -i "network"
```

## 🛠️ 实用脚本

### 一键部署（保存为 deploy.bat）
```batch
@echo off
hdc shell aa force-stop com.yjsoft.freerdp
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.yjsoft.freerdp
```

### 一键查看日志（保存为 log.bat）
```batch
@echo off
hdc shell hilog -r
hdc hilog -x | find "freerdp"
```

## 📝 环境变量设置

### Windows（添加到系统 PATH）
```
C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains
```

### 或使用临时变量
```batch
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
%HDC% <command>
```

## 💡 开发工作流

### 典型调试流程
```bash
# 1. 编译
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 2. 部署
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 3. 启动
hdc shell aa start -a EntryAbility -b com.yjsoft.freerdp

# 4. 查看日志
hdc hilog -x | grep "freerdp"

# 5. 发现问题，修改代码...

# 6. 重复步骤1-5
```

## 🔗 有用的链接

- 完整文档: [README.md](./README.md)
- 自动连接: [AUTO_CONNECT_GUIDE.md](./AUTO_CONNECT_GUIDE.md)
- 构建指南: [build_windows.md](./build_windows.md)

---

**💡 提示**:
- 大多数命令在 PowerShell 和 CMD 中都可以使用
- 使用 `Ctrl+C` 可以中断日志监控
- 使用 `hdc --help` 查看更多 hdc 命令
