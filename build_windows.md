# Windows 命令行构建 freerdp-harmonyos HAP 包指南

## 环境概述

本项目是基于 HarmonyOS 5.0 (API 12) 的 FreeRDP 鸿蒙客户端，使用 Hvigor 构建系统。
在 Windows 11 下通过命令行编译生成 `.hap` 安装包。

---

## 一、前置条件

### 1.1 必须安装的软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| DevEco Studio | 6.x | 包含 hvigorw、ohpm、SDK、Node.js |
| Windows 11 | 任意 | 测试环境为 Windows 11 IoT Enterprise LTSC 2024 |

> **注意**: 无需单独安装 Node.js 和 HarmonyOS SDK，DevEco Studio 安装后已内置。

### 1.2 DevEco Studio 安装后的关键路径

以默认安装路径 `C:\Program Files\Huawei\DevEco Studio` 为例：

```
DevEco Studio 安装目录/
├── sdk/
│   └── default/
│       ├── openharmony/     ← HarmonyOS SDK 核心（DEVECO_SDK_HOME 指向 sdk/）
│       │   ├── ets/
│       │   ├── native/
│       │   └── toolchains/
│       └── hms/
├── tools/
│   ├── hvigor/
│   │   └── bin/
│   │       └── hvigorw      ← 构建入口工具
│   ├── ohpm/
│   │   └── bin/
│   │       └── ohpm         ← 包管理工具
│   └── node/
│       └── node.exe         ← 内置 Node.js v18.x
└── jbr/                     ← 内置 JDK
```

### 1.3 签名文件

Debug 构建需要签名文件，由 DevEco Studio 在首次打开项目时自动生成并存放于：

```
C:\Users\<用户名>\.ohos\config\
├── default_freerdp-harmonyos_<hash>.cer
├── default_freerdp-harmonyos_<hash>.p12
└── default_freerdp-harmonyos_<hash>.p7b
```

签名配置已写入项目根目录的 `build-profile.json5`，无需手动修改。

---

## 二、核心问题：DEVECO_SDK_HOME 环境变量

### 问题现象

直接在命令行运行 hvigorw 会报错：

```
ERROR: 00303217 Configuration Error
Error Message: Invalid value of 'DEVECO_SDK_HOME' in the system environment path.
```

### 原因

DevEco Studio 以 GUI 方式运行时会自动向进程注入 `DEVECO_SDK_HOME` 环境变量，但该变量**不会写入系统环境变量**，因此命令行 Shell 无法继承。

### 解决方案

每次构建前设置环境变量（或将其永久写入系统环境变量）：

```cmd
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
```

---

## 三、构建命令

### 3.1 Debug 构建（常用）

```cmd
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw" assembleHap ^
  --mode module ^
  -p module=entry@default ^
  -p product=default ^
  -p buildMode=debug
```

### 3.2 Release 构建

```cmd
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw" assembleHap ^
  --mode module ^
  -p module=entry@default ^
  -p product=default ^
  -p buildMode=release
```

### 3.3 参数说明

| 参数 | 值 | 说明 |
|------|----|------|
| `assembleHap` | - | 构建 HAP 安装包任务 |
| `--mode module` | module | 以模块模式构建 |
| `-p module` | `entry@default` | 构建 entry 模块的 default target |
| `-p product` | `default` | 使用 default product 配置（含签名） |
| `-p buildMode` | `debug` / `release` | 构建模式 |

---

## 四、构建输出

构建成功后，HAP 文件输出到：

```
entry/build/default/outputs/default/
├── entry-default-signed.hap     ← 已签名，约 34 MB，可直接安装
├── entry-default-unsigned.hap   ← 未签名版本
├── mapping/                     ← 混淆映射文件
└── pack.info                    ← 包信息
```

### 增量构建

Hvigor 支持增量构建（Incremental Build）。当源文件未发生变化时，任务显示 `UP-TO-DATE`，整个构建可在 **2 秒内**完成。

---

## 五、一键构建脚本

使用项目根目录提供的 `build_windows.cmd` 脚本：

```cmd
build_windows.cmd
```

脚本支持以下可选参数：

```cmd
build_windows.cmd [debug|release] [deveco-studio-path]
```

示例：

```cmd
REM Debug 构建（默认）
build_windows.cmd

REM Release 构建
build_windows.cmd release

REM 指定 DevEco Studio 安装路径
build_windows.cmd debug "D:\Program Files\Huawei\DevEco Studio"
```

---

## 六、项目关键配置

### build-profile.json5（根目录）

```json5
{
  "app": {
    "signingConfigs": [{
      "name": "default",
      "type": "HarmonyOS",
      "material": {
        "certpath": "C:\\Users\\tony\\.ohos\\config\\default_freerdp-harmonyos_*.cer",
        "keyAlias": "debugKey",
        "storeFile": "C:\\Users\\tony\\.ohos\\config\\default_freerdp-harmonyos_*.p12",
        "profile": "C:\\Users\\tony\\.ohos\\config\\default_freerdp-harmonyos_*.p7b"
      }
    }],
    "products": [{
      "name": "default",
      "signingConfig": "default",
      "targetSdkVersion": "5.0.0(12)",
      "compatibleSdkVersion": "5.0.0(12)",
      "runtimeOS": "HarmonyOS"
    }]
  }
}
```

> **注意**: 签名路径硬编码为当前机器的用户目录，在其他机器构建需重新用 DevEco Studio 生成签名或手动修改路径。

### local.properties（项目根，不入版本库）

由 DevEco Studio 自动生成，当前为空（SDK 路径通过 `DEVECO_SDK_HOME` 环境变量传入）：

```properties
OH_SDK_HOME=
HOS_SDK_HOME=
```

---

## 七、故障排除

### 7.1 DEVECO_SDK_HOME 错误

**症状**: `Invalid value of 'DEVECO_SDK_HOME'`

**解决**: 确认 DevEco Studio 安装路径，设置正确的环境变量：

```cmd
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
```

验证 SDK 存在：

```cmd
dir "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony"
```

### 7.2 签名文件缺失

**症状**: `Signing file not found` 或 `SignHap` 任务失败

**解决**: 用 DevEco Studio 打开项目，进入 **File → Project Structure → Signing Configs**，点击 **Automatically generate signature** 自动生成。

### 7.3 ohpm 依赖未安装

**症状**: 构建时找不到 `@ohos/hypium` 等包

**解决**:

```cmd
set PATH=%PATH%;C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin
ohpm install
```

### 7.4 hvigorw 找不到

**症状**: `'hvigorw' is not recognized`

**解决**: 使用完整路径调用，或将 DevEco Studio tools/hvigor/bin 加入 PATH：

```cmd
set PATH=%PATH%;C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin
```

---

## 八、在其他 Windows 机器上构建

1. 安装 DevEco Studio 6.x
2. 打开本项目，进入 **File → Project Structure → Signing Configs**，生成新的 Debug 签名
3. 确认 `build-profile.json5` 中签名路径已更新为本机路径
4. 运行 `build_windows.cmd`

---

## 附：构建日志示例（增量构建）

```
> hvigor UP-TO-DATE :entry:default@PreBuild...
> hvigor Finished :entry:default@ConfigureCmake... after 95 ms
> hvigor UP-TO-DATE :entry:default@CompileArkTS...
> hvigor UP-TO-DATE :entry:default@PackageHap...
> hvigor UP-TO-DATE :entry:default@SignHap...
> hvigor Finished :entry:assembleHap... after 1 ms
> hvigor BUILD SUCCESSFUL in 1 s 813 ms
```
