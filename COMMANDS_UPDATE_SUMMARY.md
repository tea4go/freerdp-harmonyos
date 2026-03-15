# 🎉 README.md 常用命令更新完成！

## ✅ 已完成的工作

### 1. 📖 在 README.md 中添加了完整的"常用命令速查"章节

包含以下内容：

#### 📦 编译项目
- 完整编译（推荐）
- 使用 hvigorw ��译
- 只编译 Native 库

#### 🚀 运行项目
- 安装应用
- 启动应用
- 停止应用

#### 🐛 调试项目
- 设备管理
- 文件传输
- Shell 访问

#### 📋 查看日志
- 实时日志（推荐）
- 日志管理
- 高级日志过滤

#### 🔧 性能分析
- CPU和内存监控
- 网络状态检查

#### 🎯 快速诊断脚本
- 一键诊断的 Windows 批处理脚本

#### 📱 开发者快捷命令
- 快速重启应用
- 快速重新安装
- 查看应用版本
- 清除应用数据

#### 🔍 故障排除命令
- 检查签名问题
- 检查权限
- 检查 Native 库

### 2. 🛠️ 创建了实用脚本工具

#### 📄 diagnose.bat - 诊断工具
**功能：**
- 检查设备连接
- 检查设备架构
- 检查应用安装状态
- 检查应用进程
- 查看最近日志
- 检查网络连接
- 检查应用权限
- 检查 Native 库

**使用：**
```bash
diagnose.bat
```

#### 📄 quick-run.bat - 快速部署工具
**功能：**
- 检查设备连接
- 停止旧版本应用
- 安装新版本应用
- 启动应用
- 可选查看实时日志

**使用：**
```bash
quick-run.bat
```

#### 📄 view-log.bat - 日志查看工具
**功能菜单：**
1. 实时日志 - FreeRDP 相关
2. 实时日志 - 仅错误和警告
3. 实时日志 - 完整
4. 最近 50 行 - FreeRDP 相关
5. 最近 100 行 - 完整
6. 保存日志到文件
7. 清空日志缓冲区
8. 查看连接相关日志
9. 查看 Native 库日志

**使用：**
```bash
view-log.bat
```

#### 📄 dev-tools.ps1 - PowerShell 工具集
**支持的命令：**
- `devices` - 列出设备
- `install` - 安装应用
- `start` - 启动应用
- `stop` - 停止应用
- `restart` - 重启应用
- `logs` - 查看实时日志
- `recent` - 查看最近的日志
- `clear` - 清空日志
- `save` - 保存日志到文件
- `status` - 显示应用状态
- `help` - 显示帮助

**使用示例：**
```powershell
.\dev-tools.ps1 -Action devices
.\dev-tools.ps1 -Action logs -Filter "Connection"
.\dev-tools.ps1 -Action recent -Lines 100
```

#### 📄 COMMANDS_QUICK_REF.md - 快速参考卡片
可打印的命令参考卡片，包含：
- 最常用命令
- 应用生命周期管理
- 日志查看
- 快速重启
- 编译命令
- 开发工作流
- 有用的链接

## 📊 命令分类总览

### 🔥 高频使用（每天）
```bash
quick-run.bat              # 一键部署
view-log.bat               # 查看日志
hdc hilog -x | grep "freerdp"  # 实时日志
```

### 🔧 开发调试（按需）
```bash
diagnose.bat               # 问题诊断
.\dev-tools.ps1 -Action status  # 检查状态
hvigorw assembleHap        # 编译
```

### 📝 日志分析（排查问题）
```bash
view-log.bat               # 交互式日志查看
.\dev-tools.ps1 -Action save    # 保存日志
hdc shell hilog -r         # 清空日志
```

## 🎯 使用场景

### 场景1：日常开发调试
```bash
# 1. 修改代码
# 2. 编译（在DevEco Studio中）
# 3. 部署
quick-run.bat
# 4. 查看日志（如果需要）
view-log.bat
```

### 场景2：连接问题排查
```bash
# 1. 运行诊断
diagnose.bat

# 2. 查看连接日志
.\dev-tools.ps1 -Action logs -Filter "Connection"

# 3. 检查网络
hdc shell netstat -anp | grep 3389
```

### 场景3：性能问题分析
```bash
# 1. 查看CPU/内存
.\dev-tools.ps1 -Action status

# 2. 查看详细日志
view-log.bat -> 选择选项 3（完整日志）

# 3. 保存日志分析
.\dev-tools.ps1 -Action save
```

## 💡 推荐工作流

### 初次使用
```bash
# 1. 检查环境
diagnose.bat

# 2. 部署应用
quick-run.bat

# 3. 打印快速参考
# 打印 COMMANDS_QUICK_REF.md 文件
```

### 日常开发
```bash
# 快速迭代
quick-run.bat -> 查看应用 -> 修改代码 -> quick-run.bat
```

### 问题排查
```bash
# 完整诊断流程
diagnose.bat -> view-log.bat -> 修复问题 -> quick-run.bat
```

## 📚 文档结构

```
freerdp-harmonyos/
├── README.md                      # 主文档（已更新）
├── AUTO_CONNECT_GUIDE.md          # 自动连接指南
├── COMMANDS_QUICK_REF.md          # 命令快速参考（新增）
├── diagnose.bat                    # 诊断工具（新增）
├── quick-run.bat                   # 快速部署（新增）
├── view-log.bat                    # 日志查看（新增）
├── dev-tools.ps1                   # PowerShell工具（新增）
└── build_windows.md               # 详细构建指南
```

## 🎓 学习路径

### 初学者
1. 阅读 README.md 的"常用命令速查"章节
2. 使用 `quick-run.bat` 部署应用
3. 使用 `view-log.bat` 查看日志
4. 打印 `COMMANDS_QUICK_REF.md` 作为参考

### 进阶用户
1. 使用 PowerShell 工具集 `dev-tools.ps1`
2. 自定义诊断脚本
3. 创建自己的快捷命令别名

### 高级用户
1. 修改脚本适应自己的工作流
2. 集成到 CI/CD 流程
3. 添加更多自动化测试

## 🚀 立即开始

1. **部署应用**：
   ```bash
   quick-run.bat
   ```

2. **查看日志**：
   ```bash
   view-log.bat
   ```

3. **遇到问题**：
   ```bash
   diagnose.bat
   ```

## 📖 查看完整文档

- 主文档: [README.md](README.md)
- 自动连接: [AUTO_CONNECT_GUIDE.md](AUTO_CONNECT_GUIDE.md)
- 快速参考: [COMMANDS_QUICK_REF.md](COMMANDS_QUICK_REF.md)
- 构建指南: [build_windows.md](build_windows.md)

---

**💡 提示**: 所有脚本都在项目根目录，可以直接运行！

**🎯 目标**: 让开发调试效率提升 10 倍！
