# 设置 ARM 架构的 HarmonyOS 设备

## 问题说明

当前项目只包含 `arm64-v8a` 架构的原生库,因此只能在 ARM 架构的设备上运行。如果使用 x86_64 模拟器,会出现以下错误:

```
Install Failed: error: failed to install bundle.
code:9568347
error: install parse native so failed.
In the module named entry, the Abi type supported by the device does not match the Abi type configured in the C++ project.
```

## 解决方案:使用 ARM 架构设备

### 方案 1:使用真实设备(推荐)

1. **启用开发者模式**:
   - 在 HarmonyOS 设备上进入:设置 → 关于手机
   - 连续点击"版本号"7次,直到提示"已开启开发者模式"

2. **启用 USB 调试**:
   - 进入:设置 → 系统和更新 → 开发者选项
   - 开启"USB 调试"
   - 开启"仅充电模式下允许 ADB 调试"(如果有)

3. **连接设备**:
   - 使用 USB 数据线连接电脑和设备
   - 在设备上允许 USB 调试授权
   - 在 DevEco Studio 中,设备会自动出现在设备列表中

4. **运行应用**:
   - 在 DevEco Studio 工具栏选择你的设备
   - 点击运行按钮 ▶️

### 方案 2:创建 ARM 架构模拟器

1. **打开设备管理器**:
   - 在 DevEco Studio 中:Tools → Device Manager
   - 或点击工具栏的设备下拉菜单 → Device Manager

2. **��建新模拟器**:
   - 点击 **+ New Emulator** 按钮
   - 选择 **Phone** 或 **Tablet**(根据需要)

3. **选择 ARM64 架构**:
   - **重要**:在选择系统镜像时,选择 **ARM64** 架构的镜像
   - 不要选择 x86_64 架构的镜像
   - 推荐选择:Api 12 (ARM64)

4. **配置模拟器**:
   ```
   Name: HarmonyOS_ARM64
   Device: Phone (建议 1080x2340 分辨率)
   System Image: Api 12 (ARM64)
   RAM: 至少 2GB
   Internal Storage: 至少 8GB
   ```

5. **启动模拟器**:
   - 创建完成后,点击 ▶️ 启动模拟器
   - 等待模拟器完全启动(首次启动较慢)

6. **运行应用**:
   - 在 DevEco Studio 工具栏选择新创建的 ARM64 模拟器
   - 点击运行按钮 ▶️

### 方案 3:检查现有模拟器架构

如果你已经有模拟器,可以检查其架构:

1. **在 DevEco Studio 中**:
   - Tools → Device Manager
   - 查看模拟器的详细信息
   - 查看 "ABI" 列,应该显�� "arm64-v8a"

2. **通过命令行检查**:
   ```bash
   # 如果你有 hdc 工具
   hdc shell getprop ro.product.cpu.abi
   # 应该输出: arm64-v8a
   ```

## 验证设备架构

在运行应用前,确认设备架构:

### 方法 1:在 DevEco Studio 中查看
- 设备下拉菜单会显示设备架构信息
- 例如:"HUAWEI Mate 60 (arm64-v8a)"

### 方法 2:通过代码查看
在应用启动时添加日志:
```typescript
import deviceInfo from '@ohos.deviceInfo';

console.log('Device ABI:', deviceInfo.cpuAbi);
// 应该输出: arm64-v8a
```

## 常见问题

### Q1: 没有真实的 HarmonyOS 设备怎么办?
**A**: 使用方案 2 创建 ARM 架构的模拟器。虽然性能稍差,但功能完整。

### Q2: 为什么不支持 x86_64 模拟器?
**A**: x86_64 需要重新编译所有原生库(OpenSSL, FreeRDP 等),耗时 1-2 小时。如果确实需要,可以修改 GitHub Actions workflow 添加 x86_64 支持。

### Q3: ARM 模拟器很慢怎么办?
**A**:
- 确保电脑支持虚拟化并在 BIOS 中启用
- 在 DevEco Studio 中:File → Settings → Tools → Emulator
- 增加模拟器的 RAM 和 CPU 核心
- 考虑使用真实设备(性能最佳)

### Q4: 如何添加 x86_64 支持?
**A**: 如果必须在 x86_64 模拟器上运行,需要:
1. 修改 `.github/workflows/build-freerdp-harmonyos.yml`
2. 添加 `build-ohos-x86_64` 任务
3. 等待 GitHub Actions 完成(1-2 小时)
4. 下载构建产物到 `entry/libs/x86_64/`
5. 修改 `entry/build-profile.json5` 的 `abiFilters` 添加 `x86_64`

## 下一步

设置好 ARM 设备后:
1. 在 DevEco Studio 中选择该设备
2. 点击运行 ▶️
3. 应用应该能够正常安装和运行

如果仍有问题,请检查:
- 签名配置是否正确
- 设备是否已授权
- DevEco Studio 的错误日志
