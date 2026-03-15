# FreeRDP HarmonyOS 连接问��诊断

## 问题：连接立刻断开

### 可能原因

1. **密码为空** ⭐ 最可能
   - Index.ets 中默认密码是空字符串
   - RDP服务器通常拒绝无密码连接

2. **Native库加载失败**
   - 库文件存在但可能加载失败
   - 需要检查日志确认

3. **网络连接问题**
   - 无法连接到远程主机
   - 端口被阻止

4. **服务器配置问题**
   - 服务器不支持RDP协议
   - NLA认证失败

### 诊断步骤

#### 1. 确认输入了密码

**在快速连接对话框中：**
- ✅ 主机地址：192.168.52.127（或你的服务器地址）
- ✅ 端口：3389
- ✅ 用户名：administrator（或你的用户名）
- ⚠️ **密码：必须输入！**（不能为空）

#### 2. 检查服务器可达性

在设备上测试网络连接：
```bash
# 在PC上运行（确保设备和PC在同一网络）
ping 192.168.52.127

# 测试RDP端口
telnet 192.168.52.127 3389
```

#### 3. 检查服务器配置

确保Windows远程桌面已启用：
1. Windows设置 → 系统 → 远程桌面
2. 启用"启用远程桌面"
3. 确认用户有远程桌面权限

#### 4. 查看应用日志

```bash
# 查看FreeRDP日志
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" hilog -x | grep -E "(FreeRDP|Session|Connection)"
```

### 解决方案

#### 方案1：正确输入密码（推荐）

1. 在应用主界面点击"快速连接"
2. **输入所有必需信息**，特别是密码
3. 点击连接

#### 方案2：创建书签

1. 点击"添加书签"
2. 填写完整的连接信息
3. 保存后点击书签连接

#### 方案3：检查服务器设置

在Windows服务器上：
1. 确保远程桌面已启用
2. 检查防火墙设置（允许3389端口）
3. 确认用户权限

### 调试模式

如果问题仍然存在，需要查看详细日志：

```bash
# 1. 清空日志
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" shell hilog -r

# 2. 开始监控
"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" hilog -x > freerdp_debug.log

# 3. 在设备上尝试连接

# 4. 查看日志
cat freerdp_debug.log | grep -A 10 -B 10 "Connection"
```

### 常见错误信息

- `Password cannot be empty` - 需要输入密码
- `Connection refused` - 服务器未运行或端口错误
- `Authentication failed` - 用户名或密码错误
- `SSL certificate verification failed` - 证书验证失败（代码中已忽略）

### 下一步

如果以上方法都无法解决，请提供：
1. 完整的连接日志
2. 服务器配置信息
3. 网络环境描述
