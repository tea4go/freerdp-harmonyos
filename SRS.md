# FreeRDP HarmonyOS 软件需求规格说明 (SRS)

**文档版本**: 1.0.0
**日期**: 2026-03-27
**目标**: 指导使用 ArkUI 重新实现本项目的完整设计文档

---

## 目录

1. [引言](#1-引言)
2. [总体描述](#2-总体描述)
3. [系统架构](#3-系统架构)
4. [功能需求](#4-功能需求)
5. [非功能需求](#5-非功能需求)
6. [UI 组件设计](#6-ui-组件设计)
7. [服务层设计](#7-服务层设计)
8. [数据模型设计](#8-数据模型设计)
9. [Native 层实现](#9-native-层实现)
10. [配置文件](#10-配置文件)
11. [实现指南](#11-实现指南)

---

## 1. 引言

### 1.1 目的

本文档是 FreeRDP HarmonyOS 远程桌面客户端的软件需求规格说明书，旨在为开发者提供完整的实现指导，使其能够使用 ArkUI 框架从零开始重新实现一个功能相同的应用程序。

### 1.2 项目概述

FreeRDP HarmonyOS 是一个运行在 HarmonyOS 平台上的 RDP（远程桌面协议）客户端，基于 FreeRDP 3.x 开源库实现。它允许用户从 HarmonyOS 设备连接到 Windows 远程桌面。

### 1.3 应用信息

| 属性 | 值 |
|------|-----|
| 包名 | `com.yjsoft.freerdp` |
| 版本号 | 1.0.0 (1000000) |
| 目标平台 | HarmonyOS 5.0.0 (API 12) |
| 支持设备 | 2in1、手机、平板 |
| 支持架构 | arm64-v8a |

### 1.4 核心依赖

- **FreeRDP 3.x**: 远程桌面协议核心库
- **WinPR 3.x**: Windows 可移植运行时
- **OpenSSL**: 加密通信（静态链接到 FreeRDP）
- **HarmonyOS NDK**: Native 开发套件

---

## 2. 总体描述

### 2.1 产品功能

1. **书签管理**: 保存、编辑、删除 RDP 连接配置
2. **快速连接**: 无需保存即可连接到远程桌面
3. **远程桌面会话**: 完整的 RDP 会话支持
4. **触控交互**: 触摸屏鼠标指针模拟
5. **虚拟键盘**: 特殊键和修饰键输入
6. **剪贴板同步**: 本地与远程剪贴板双向同步
7. **后台运行**: 锁屏下保持连接和音频播放
8. **自动重连**: 网络中断后自动恢复连接

### 2.2 用户特征

- 需要远程办公的企业用户
- 系统管理员远程管理服务器
- 需要访问 Windows 应用的移动用户

### 2.3 运行环境

```
硬件要求:
- ARM64 架构处理器
- 2GB+ 内存
- 网络连接（WiFi/移动数据）

软件要求:
- HarmonyOS 5.0.0 或更高版本
- 网络权限
- 后台运行权限
```

---

## 3. 系统架构

### 3.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    UI 层 (ArkUI/ArkTS)                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ Index   │ │Session  │ │Bookmark │ │Settings │           │
│  │ Page    │ │ Page    │ │ Page    │ │ Page    │           │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              UI 组件 (Components)                        ││
│  │ SessionView │ TouchPointerView │ VirtualKeyboard        ││
│  └─────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│                   服务层 (Services)                          │
│  ┌────────────┐ ┌──────────────┐ ┌──────────────────────┐  │
│  │ LibFreeRDP │ │NetworkManager│ │ RdpBackgroundService │  │
│  │ (核心封装)  │ │(网络监控)     │ │   (后台服务)          │  │
│  └────────────┘ └──────────────┘ └──────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                   数据层 (Model)                             │
│  ┌──────────────┐ ┌───────────────┐                        │
│  │ BookmarkBase │ │ SessionState  │                        │
│  │ (连接配置)    │ │ (会话状态)     │                        │
│  └──────────────┘ └───────────────┘                        │
├─────────────────────────────────────────────────────────────┤
│                 Native 层 (C/C++)                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              harmonyos_napi.cpp (N-API 绑定)          │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              harmonyos_freerdp.cpp (FreeRDP 封装)      │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              FreeRDP 3.x Library (预编译)              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 目录结构

```
entry/
├── src/main/
│   ├── cpp/                           # Native C/C++ 代码
│   │   ├── harmonyos_freerdp.cpp      # FreeRDP 核心封装 (60KB)
│   │   ├── harmonyos_freerdp.h        # 头文件
│   │   ├── harmonyos_napi.cpp         # N-API 绑定层 (33KB)
│   │   ├── harmonyos_event.c          # 事件队列管理
│   │   ├── harmonyos_cliprdr.c        # 剪贴板功能
│   │   ├── freerdp_client_compat.c    # 客户端兼容代码
│   │   └── CMakeLists.txt             # 构建配置
│   │
│   ├── ets/                           # ArkTS 源代码
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets       # 应用入口
│   │   │
│   │   ├── pages/                     # 页面
│   │   │   ├── Index.ets              # 主页 (书签列表)
│   │   │   ├── SessionPage.ets        # RDP 会话页面
│   │   │   ├── BookmarkPage.ets       # 书签编辑页面
│   │   │   ├── SettingsPage.ets       # 设置页面
│   │   │   └── AboutPage.ets          # 关于页面
│   │   │
│   │   ├── components/                # UI 组件
│   │   │   ├── SessionView.ets        # 远程桌面画布
│   │   │   ├── TouchPointerView.ets   # 触控指针
│   │   │   └── VirtualKeyboard.ets    # 虚拟键盘
│   │   │
│   │   ├── services/                  # 服务层
│   │   │   ├── LibFreeRDP.ets         # Native 库接口封装
│   │   │   ├── RdpSessionManager.ets  # 会话管理器
│   │   │   ├── RdpBackgroundService.ets # 后台服务
│   │   │   ├── NetworkManager.ets     # 网络管理
│   │   │   ├── AudioFocusManager.ets  # 音频焦点
│   │   │   ├── ClipboardManager.ets   # 剪贴板管理
│   │   │   └── KeyboardMapper.ets     # 键盘映射
│   │   │
│   │   └── model/                     # 数据模型
│   │       ├── BookmarkBase.ets       # 书签模型
│   │       └── SessionState.ets       # 会话状态
│   │
│   └── resources/                     # 资源文件
│       ├── base/
│       │   ├── element/
│       │   │   ├── color.json         # 颜色定义
│       │   │   └── string.json        # 字符串资源
│       │   └── media/                 # 图片资源
│       └── profile/
│           └── main_pages.json        # 页面路由配置
│
└── libs/                              # 第三方库
    └── arm64-v8a/
        ├── libfreerdp3.so
        ├── libfreerdp-client3.so
        ├── libwinpr3.so
        └── libfreerdp_harmonyos.so
```

---

## 4. 功能需求

### 4.1 书签管理 (FR-001)

**描述**: 用户可以保存、编辑、删除 RDP 连接配置

**功能点**:
- 创建新书签
- 编辑现有书签
- 删除书签
- 书签列表展示
- 点击书签快速连接

**数据存储**: 使用 `@ohos.data.preferences` 持久化存储

**书签数据结构**:
```typescript
interface Bookmark {
  id: number;                    // 唯一标识
  label: string;                 // 显示名称
  type: BookmarkType;            // 类型 (手动/快速连接)

  // 连接设置
  hostname: string;              // 主机地址
  port: number;                  // 端口 (默认 3389)
  username: string;              // 用户名
  domain: string;                // 域
  password: string;              // 密码

  // 屏幕设置
  screenSettings: {
    width: number;               // 宽度 (640-8192)
    height: number;              // 高度 (480-8192)
    colors: number;              // 颜色深度 (8/16/24/32)
  };

  // 高级设置
  advancedSettings: {
    consoleMode: boolean;        // 控制台模式
    security: number;            // 安全模式 (0=自动,1=RDP,2=TLS,3=NLA)
    remoteProgram: string;       // 远程程序
    workDir: string;             // 工作目录
    redirectSDCard: boolean;     // SD卡重定向
    redirectSound: number;       // 音频模式 (0=本地,1=远程,2=禁用)
    redirectMicrophone: boolean; // 麦克风重定向
  };

  // 性能标志
  performanceFlags: {
    remoteFX: boolean;           // RemoteFX 编解码
    gfx: boolean;                // GFX 管道
    h264: boolean;               // H.264/AVC 编解码
    wallpaper: boolean;          // 显示壁纸
    fullWindowDrag: boolean;     // 完整窗口拖动
    menuAnimations: boolean;     // 菜单动画
    theming: boolean;            // 主题
    fontSmoothing: boolean;      // 字体平滑
    desktopComposition: boolean; // 桌面合成
  };

  // 网关设置
  gatewaySettings?: {
    enabled: boolean;
    hostname: string;
    port: number;
    username: string;
    domain: string;
    password: string;
  };
}
```

### 4.2 快速连接 (FR-002)

**描述**: 无需保存书签即可快速连接

**功能点**:
- 输入主机地址
- 输入端口 (默认 3389)
- 输入用户名和密码
- 一键连接
- 连接验证

### 4.3 远程桌面会话 (FR-003)

**描述**: 显示远程桌面并处理用户输入

**功能点**:
- 显示远程桌面画面
- 支持缩放 (0.25x - 4.0x)
- 支持平移
- 适应屏幕
- 触摸输入转换为鼠标事件
- 工具栏 (返回、状态、键盘、更多选项)
- 断开连接确认对话框

**连接状态**:
```typescript
enum ConnectionState {
  DISCONNECTED = 0,    // 已断开
  CONNECTING = 1,      // 连接中
  CONNECTED = 2,       // 已连接
  DISCONNECTING = 3,   // 断开中
  RECONNECTING = 4     // 重连中
}
```

### 4.4 触控指针 (FR-004)

**描述**: 提供虚拟鼠标指针用于触摸操作

**功能点**:
- 可拖动的鼠标指针
- 单击 = 左键点击
- 长按 = 右键点击
- 双击 = 开始/结束拖动
- 根据远程光标类型改变颜色

**光标类型**:
```typescript
const CURSOR_TYPE = {
  UNKNOWN: 0,
  DEFAULT: 1,      // 默认箭头 - 白色
  HAND: 2,         // 手型 - 绿色
  IBEAM: 3,        // I型 - 蓝色
  SIZE_NS: 4,      // 上下调整 - 橙色
  SIZE_WE: 5,      // 左右调整 - 橙色
  SIZE_NWSE: 6,    // 斜向调整
  SIZE_NESW: 7,    // 斜向调整
  CROSS: 8,        // 十字 - 紫色
  WAIT: 9          // 等待 - 红色
};
```

### 4.5 虚拟键盘 (FR-005)

**描述**: 提供特殊键和修饰键输入

**功能点**:
- 特殊键 (Esc, F1-F12, Ins, Del, Home, End, PgUp, PgDn, PrtSc, Pause)
- 方向键 (上、下、左、右)
- 修饰键 (Ctrl, Alt, Shift, Win) - 可组合
- 修饰键状态指示
- 键盘类型切换

**虚拟键码** (Windows VK 码):
```typescript
const VK = {
  ESCAPE: 0x1B,
  TAB: 0x09,
  RETURN: 0x0D,
  BACK: 0x08,
  DELETE: 0x2E,
  INSERT: 0x2D,
  HOME: 0x24,
  END: 0x23,
  PRIOR: 0x21,     // Page Up
  NEXT: 0x22,      // Page Down
  LEFT: 0x25,
  UP: 0x26,
  RIGHT: 0x27,
  DOWN: 0x28,
  CONTROL: 0x11,
  MENU: 0x12,      // Alt
  SHIFT: 0x10,
  LWIN: 0x5B,
  F1: 0x70,        // ... 到 F12: 0x7B
};
```

### 4.6 剪贴板同步 (FR-006)

**描述**: 本地与远程剪贴板双向同步

**功能点**:
- 发送本地文本到远程
- 接收远程文本到本地
- 支持纯文本格式

### 4.7 后台运行 (FR-007)

**描述**: 锁屏或后台时保持连接和音频

**功能点**:
- 注册后台音频播放任务
- 显示常驻通知
- 后台模式: 只传音频，不传图像
- 前台恢复: 请求全屏刷新
- 自动重启 (最多 10 次)

**后台服务 API**:
```typescript
class RdpBackgroundService {
  async start(): Promise<boolean>;    // 启动后台服务
  async stop(): Promise<void>;        // 停止后台服务
  static isServiceRunning(): boolean; // 检查运行状态
}
```

### 4.8 网络管理与自动重连 (FR-008)

**描述**: 监控网络状态并在断线时自动重连

**功能点**:
- 监控网络连接状态
- 网络丢失检测
- 自动重连 (最多 10 次，递增延迟)
- 重连成功/失败回调

**重连延迟策略**:
```typescript
const RECONNECT_DELAYS = [
  1000,   // 第 1 次: 1 秒
  5000,   // 第 2 次: 5 秒
  10000,  // 第 3 次: 10 秒
  20000,  // 第 4-10 次: 20 秒
  // ...
];
```

### 4.9 心跳保活 (FR-009)

**描述**: 定期发送心跳保持连接

**功能点**:
- TCP Keepalive (15 秒间隔)
- RDP Synchronize 心跳 (30 秒间隔)
- 连接健康状态检查

---

## 5. 非功能需求

### 5.1 性能要求 (NFR-001)

- 冷启动时间 < 3 秒
- 连接建立时间 < 10 秒 (取决于网络)
- 帧率 >= 15 FPS (在良好网络条件下)
- 内存占用 < 200 MB

### 5.2 安全要求 (NFR-002)

- 密码不明文存储在日志中
- 支持 TLS/NLA 安全连接
- 证书验证 (可配置忽略)
- 不传输敏感日志

### 5.3 可用性要求 (NFR-003)

- 深色主题 UI
- 触摸友好的交互 (最小触摸目标 44dp)
- 清晰的连接状态指示
- 友好的错误提示

### 5.4 兼容性要求 (NFR-004)

- HarmonyOS 5.0.0+
- ARM64 架构
- 支持 2in1、手机、平板设备

---

## 6. UI 组件设计

### 6.1 主页面 (Index.ets)

**功能**: 书签列表和快速连接入口

**UI 结构**:
```
┌─────────────────────────────────────┐
│  远程桌面                     ⚙️ ℹ️  │  <- 标题栏
├─────────────────────────────────────┤
│          [ 快速连接 ]                │  <- 快速连接按钮
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ 🖥️  Work PC                 │    │  <- 书签卡片
│  │     administrator@10.0.0.1  │ ✏️ 🗑️│
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🖥️  Server                  │    │
│  │     admin@192.168.1.100     │ ✏️ 🗑️│
│  └─────────────────────────────┘    │
│                                     │
│                               [+]   │  <- 新建书签 FAB
└─────────────────────────────────────┘
```

**状态管理**:
```typescript
@State bookmarks: BookmarkBase[] = [];
@State isLoading: boolean = true;
@State showQuickConnect: boolean = false;
@State showNativeError: boolean = false;
@State autoConnectOnStart: boolean = false;  // 调试模式
```

**关键方法**:
```typescript
// 加载书签
async loadBookmarks(): Promise<void>

// 保存书签
async saveBookmarks(): Promise<void>

// 连接到书签
connectToBookmark(bookmark: BookmarkBase): void

// 快速连接
quickConnect(): void
```

### 6.2 会话页面 (SessionPage.ets)

**功能**: 显示远程桌面并处理交互

**UI 结构**:
```
┌─────────────────────────────────────┐
│  ←         已连接          ⌨️  ⋮    │  <- 工具栏
├─────────────────────────────────────┤
│                                     │
│     ┌───────────────────────┐       │
│     │                       │       │
│     │    远程桌面画面        │  ←── SessionView
│     │                       │       │
│     │         ▲             │  ←── TouchPointerView
│     │        ╱│╲            │       │
│     └───────────────────────┘       │
│                                     │
├─────────────────────────────────────┤
│  Ctrl Alt Shift Win                 │  <- 虚拟键盘 (可选)
│  Esc F1 F2 F3 F4 ...                │
└─────────────────────────────────────┘
```

**状态管理**:
```typescript
@State session: SessionState | null = null;
@State connectionState: ConnectionState = ConnectionState.DISCONNECTED;
@State statusMessage: string = '正在连接...';
@State desktopWidth: number = 1920;
@State desktopHeight: number = 1080;
@State pixelMap: image.PixelMap | null = null;
@State viewScale: number = 1.0;
@State offsetX: number = 0;
@State offsetY: number = 0;
@State showToolbar: boolean = true;
@State showKeyboard: boolean = false;
@State isInBackground: boolean = false;
```

**生命周期**:
```typescript
aboutToAppear(): void    // 获取路由参数，初始化会话
aboutToDisappear(): void // 清理资源
onPageShow(): void       // 恢复前台，启用图形
onPageHide(): void       // 进入后台，禁用图形
```

### 6.3 SessionView 组件

**功能**: 渲染远程桌面画布，处理触摸输入

**属性**:
```typescript
@Prop instance: number;           // FreeRDP 实例
@Prop desktopWidth: number;       // 桌面宽度
@Prop desktopHeight: number;      // 桌面高度
@Prop pixelMap: image.PixelMap;   // 图像数据
@State viewScale: number;         // 缩放比例
@State offsetX: number;           // X 偏移
@State offsetY: number;           // Y 偏移
```

**触摸处理**:
```typescript
// 单指: 发送鼠标事件或平移
// 双指: 缩放手势

private onTouchDown(event: TouchEvent): void
private onTouchMove(event: TouchEvent): void
private onTouchUp(event: TouchEvent): void

// 坐标转换
private viewToDesktop(viewX: number, viewY: number): DesktopPoint
```

**鼠标事件标志**:
```typescript
const PTR_FLAGS = {
  MOVE: 0x0800,
  DOWN: 0x8000,
  BUTTON1: 0x1000,   // 左键
  BUTTON2: 0x2000,   // 右键
  BUTTON3: 0x4000,   // 中键
  WHEEL: 0x0200,
  WHEEL_NEGATIVE: 0x0100
};
```

### 6.4 TouchPointerView 组件

**功能**: 虚拟鼠标指针

**属性**:
```typescript
@Prop instance: number;
@State pointerX: number;          // 桌面坐标 X
@State pointerY: number;          // 桌面坐标 Y
@State cursorType: number;        // 光标类型
@State isDragging: boolean;       // 是否拖拽中
@State isVisible: boolean;        // 是否可见
```

**手势处理**:
```typescript
// 拖动指针
onTouch(event: TouchEvent): void

// 单击 = 左键
TapGesture({ count: 1 })

// 长按 = 右键
LongPressGesture({ duration: 500 })

// 双击 = 开始/结束拖拽
TapGesture({ count: 2 })
```

### 6.5 VirtualKeyboard 组件

**功能**: 特殊键和修饰键输入

**属性**:
```typescript
@Prop instance: number;
@State keyboardType: string;      // 'special' | 'cursor' | 'modifiers'
@State ctrlActive: boolean;
@State altActive: boolean;
@State shiftActive: boolean;
@State winActive: boolean;
```

**键盘布局**:
```typescript
// 特殊键
const SPECIAL_KEYS = [
  ['Esc', 'F1', 'F2', 'F3', 'F4'],
  ['F5', 'F6', 'F7', 'F8'],
  ['F9', 'F10', 'F11', 'F12'],
  ['Ins', 'Del', 'Home', 'End'],
  ['PgUp', 'PgDn', 'PrtSc', 'Pause']
];

// 方向键
const CURSOR_KEYS = [
  ['', '↑', ''],
  ['←', '↓', '→']
];

// 修饰键
const MODIFIER_KEYS = [
  ['Ctrl', 'Alt', 'Shift', 'Win']
];
```

---

## 7. 服务层设计

### 7.1 LibFreeRDP 服务

**功能**: 封装 Native 库接口

**核心方法**:
```typescript
class LibFreeRDP {
  // 生命周期
  static newInstance(): number;
  static freeInstance(inst: number): void;
  static connect(inst: number): boolean;
  static disconnect(inst: number): boolean;

  // 配置
  static setConnectionInfo(inst: number, bookmark: BookmarkSettings): boolean;
  static setTcpKeepalive(inst: number, enabled: boolean, delay: number,
                          interval: number, retries: number): boolean;

  // 输入
  static sendCursorEvent(inst: number, x: number, y: number, flags: number): boolean;
  static sendKeyEvent(inst: number, keycode: number, down: boolean): boolean;
  static sendUnicodeKeyEvent(inst: number, keycode: number, down: boolean): boolean;
  static sendClipboardData(inst: number, data: string): boolean;

  // 心跳与状态
  static sendHeartbeat(inst: number): boolean;
  static getLastErrorString(inst: number): string;
  static getVersion(): string;
  static isInstanceConnected(inst: number): boolean;

  // 后台模式
  static enterBackgroundMode(inst: number): boolean;
  static exitBackgroundMode(inst: number): boolean;
  static setClientDecoding(inst: number, enable: boolean): number;

  // 刷新
  static requestRefresh(inst: number): boolean;
  static requestRefreshRect(inst: number, x: number, y: number,
                            width: number, height: number): boolean;
}
```

**事件监听**:
```typescript
interface EventListener {
  OnPreConnect(instance: number): void;
  OnConnectionSuccess(instance: number): void;
  OnConnectionFailure(instance: number): void;
  OnDisconnecting(instance: number): void;
  OnDisconnected(instance: number): void;
}

interface UIEventListener {
  OnSettingsChanged(width: number, height: number, bpp: number): void;
  OnGraphicsUpdate(x: number, y: number, width: number, height: number): void;
  OnGraphicsResize(width: number, height: number, bpp: number): void;
  OnCursorTypeChanged(cursorType: number): void;
}
```

**命令行参数构建** (setConnectionInfo):
```typescript
// 构建 FreeRDP 命令行参数
const args = [
  'FreeRDP',
  '/gdi:sw',
  `/v:${hostname}`,
  `/port:${port}`,
  `/u:${username}`,
  `/p:${password}`,
  `/size:${width}x${height}`,
  `/bpp:${colors}`,
  // 性能标志
  performanceFlags.remoteFX ? '/rfx' : null,
  performanceFlags.gfx ? '/gfx' : null,
  performanceFlags.h264 ? '/gfx:AVC444' : null,
  // ...
].filter(Boolean);
```

### 7.2 NetworkManager 服务

**功能**: 网络状态监控和自动重连

**核心方法**:
```typescript
class NetworkManager {
  static async initialize(): Promise<void>;
  static uninitialize(): void;
  static isNetworkAvailable(): boolean;

  // 会话信息 (用于重连)
  static setSessionInfo(session: SessionInfo): void;
  static clearSessionInfo(): void;

  // 回调设置
  static setOnNetworkAvailableCallback(callback: () => void): void;
  static setOnNetworkLostCallback(callback: () => void): void;
  static setOnReconnectSuccessCallback(callback: () => void): void;
  static setOnReconnectFailureCallback(callback: (error: string) => void): void;

  // 重连控制
  static startReconnect(): void;
  static cancelReconnect(): void;
}
```

**网络事件监听**:
```typescript
netConnection.on('netAvailable', (netHandle) => {
  // 网络可用，尝试重连
});

netConnection.on('netLost', (netHandle) => {
  // 网络丢失，通知用户
});
```

### 7.3 RdpBackgroundService 服务

**功能**: 后台运行保持连接

**核心方法**:
```typescript
class RdpBackgroundService {
  constructor(context: UIAbilityContext);

  async start(): Promise<boolean>;   // 启动后台服务
  async stop(): Promise<void>;       // 停止后台服务

  static isServiceRunning(): boolean;
  static setOnServiceRestartCallback(callback: () => void): void;
  async updateNotification(content: string): Promise<void>;
}
```

**后台模式实现**:
```typescript
// 1. 创建 WantAgent
const wantAgentInfo: wantAgent.WantAgentInfo = {
  wants: [{ bundleName, abilityName }],
  operationType: wantAgent.OperationType.START_ABILITY,
  // ...
};

// 2. 启动后台任务
await backgroundTaskManager.startBackgroundRunning(
  context,
  backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
  wantAgent
);

// 3. 显示常驻通知
await notificationManager.publish({
  id: NOTIFICATION_ID,
  content: { title, text },
  isOngoing: true,  // 常驻通知
});
```

---

## 8. 数据模型设计

### 8.1 BookmarkBase 模型

**功能**: 书签数据模型

**类型定义**:
```typescript
enum BookmarkType {
  MANUAL = 0,        // 手动保存的书签
  QUICK_CONNECT = 1  // 快速连接 (临时)
}

class BookmarkBase {
  // 元数据
  id: number = 0;
  label: string = '';
  type: BookmarkType = BookmarkType.MANUAL;

  // 连接信息
  hostname: string = '';
  port: number = 3389;
  username: string = '';
  domain: string = '';
  password: string = '';

  // 嵌套配置
  screenSettings: ScreenSettings;
  advancedSettings: AdvancedSettings;
  performanceFlags: PerformanceFlags;
  debugSettings: DebugSettings;
  gatewaySettings: GatewaySettings;

  // 方法
  static fromJson(json: object): BookmarkBase;
  toJson(): Record<string, Object>;
  clone(): BookmarkBase;
  validate(): string[];  // 返回错误消息数组
  getDisplayLabel(): string;
  getConnectionString(): string;
}
```

**序列化/反序列化**:
```typescript
// 保存到 Preferences
const bookmarksJson = JSON.stringify(bookmarks.map(b => b.toJson()));
await preferences.put('bookmarks', bookmarksJson);

// 从 Preferences 加载
const bookmarksJson = await preferences.get('bookmarks', '[]');
const bookmarksData = JSON.parse(bookmarksJson);
this.bookmarks = bookmarksData.map(data => BookmarkBase.fromJson(data));
```

### 8.2 SessionState 模型

**功能**: 会话状态管理

**类型定义**:
```typescript
enum ConnectionState {
  DISCONNECTED = 0,
  CONNECTING = 1,
  CONNECTED = 2,
  DISCONNECTING = 3,
  RECONNECTING = 4
}

class SessionState {
  private instance: number = 0;
  private bookmark: BookmarkBase;
  private connectionState: ConnectionState;
  private desktopWidth: number = 0;
  private desktopHeight: number = 0;
  private colorDepth: number = 0;
  private pixelMap: image.PixelMap | null = null;
  private connectTime: number = 0;
  private lastUpdateTime: number = 0;
  private updateCount: number = 0;
  private isInBackground: boolean = false;
  private isScreenLocked: boolean = false;

  // Getter/Setter
  getInstance(): number;
  setInstance(instance: number): void;
  getConnectionState(): ConnectionState;
  setConnectionState(state: ConnectionState): void;
  isConnected(): boolean;

  // 显示设置
  updateDisplaySettings(width: number, height: number, bpp: number): void;
  getDesktopWidth(): number;
  getDesktopHeight(): number;

  // PixelMap 管理
  getPixelMap(): image.PixelMap | null;
  setPixelMap(pixelMap: image.PixelMap | null): void;
  async createPixelMap(): Promise<void>;

  // 后台模式
  setInBackground(inBackground: boolean): void;
  shouldSuppressGraphics(): boolean;

  // 统计
  getConnectionDuration(): number;
  getTimeSinceLastUpdate(): number;

  // 清理
  cleanup(): void;
}
```

**全局会话管理器**:
```typescript
class GlobalSessionManager {
  private static sessions: Map<number, SessionState>;

  static registerSession(instance: number, session: SessionState): void;
  static getSession(instance: number): SessionState | undefined;
  static removeSession(instance: number): void;
  static getAllSessions(): SessionState[];
  static getSessionCount(): number;
  static hasConnectedSession(): boolean;
  static cleanupAll(): void;
}
```

---

## 9. Native 层实现

### 9.1 N-API 绑定 (harmonyos_napi.cpp)

**功能**: 桥接 ArkTS 和 C++

**导出函数**:
```cpp
// 核心函数
napi_value FreerdpNew(napi_env, napi_callback_info);       // 创建实例
napi_value FreerdpFree(napi_env, napi_callback_info);      // 释放实例
napi_value FreerdpConnect(napi_env, napi_callback_info);   // 连接
napi_value FreerdpDisconnect(napi_env, napi_callback_info); // 断开

// 输入函数
napi_value FreerdpSendCursorEvent(napi_env, napi_callback_info);  // 鼠标事件
napi_value FreerdpSendKeyEvent(napi_env, napi_callback_info);     // 键盘事件
napi_value FreerdpSendUnicodeKeyEvent(napi_env, napi_callback_info);
napi_value FreerdpSendClipboardData(napi_env, napi_callback_info);

// 网络函数
napi_value FreerdpSetTcpKeepalive(napi_env, napi_callback_info);
napi_value FreerdpSendSynchronizeEvent(napi_env, napi_callback_info);

// 显示函数
napi_value FreerdpSetClientDecoding(napi_env, napi_callback_info);

// 工具函数
napi_value FreerdpGetLastErrorString(napi_env, napi_callback_info);
napi_value FreerdpGetVersion(napi_env, napi_callback_info);
napi_value FreerdpHasH264(napi_env, napi_callback_info);

// 后台模式
napi_value FreerdpEnterBackgroundMode(napi_env, napi_callback_info);
napi_value FreerdpExitBackgroundMode(napi_env, napi_callback_info);

// 回调设置
napi_value SetOnConnectionSuccess(napi_env, napi_callback_info);
napi_value SetOnConnectionFailure(napi_env, napi_callback_info);
// ... 其他回调
```

**线程安全回调**:
```cpp
// 使用 napi_threadsafe_function 从 C++ 线程调用 JS 回调
static napi_threadsafe_function g_tsfnConnectionSuccess;

static void OnConnectionSuccessImpl(int64_t instance) {
    CallbackData* data = new CallbackData{instance};
    napi_call_threadsafe_function(g_tsfnConnectionSuccess, data, napi_tsfn_blocking);
}

static void CallJS_InstanceOnly(napi_env env, napi_value js_callback,
                                void* context, void* data) {
    CallbackData* cbData = static_cast<CallbackData*>(data);
    napi_value arg;
    napi_create_int64(env, cbData->instance, &arg);
    napi_call_function(env, global, js_callback, 1, &arg, &result);
    delete cbData;
}
```

**模块注册**:
```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "freerdpNew", nullptr, FreerdpNew, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "freerdpFree", nullptr, FreerdpFree, nullptr, nullptr, nullptr, napi_default, nullptr },
        // ... 所有导出函数
    };
    napi_define_properties(env, exports, sizeof(desc)/sizeof(desc[0]), desc);

    // OpenSSL 环境配置 (关键!)
    setenv("HOME", "/data/storage/el2/base/files", 1);
    setenv("OPENSSL_CONF", "/dev/null", 1);
    unsetenv("OPENSSL_MODULES");

    return exports;
}

NAPI_MODULE(freerdp_harmonyos, Init)
```

### 9.2 FreeRDP 封装 (harmonyos_freerdp.cpp)

**功能**: 封装 FreeRDP API

**核心结构**:
```cpp
typedef struct {
    rdpContext context;          // FreeRDP 上下文 (必须首位)
    int64_t instanceId;          // 实例 ID
    rdpClientContext* client;    // 客户端上下文

    // 回调函数指针
    void (*onConnectionSuccess)(int64_t);
    void (*onConnectionFailure)(int64_t);
    void (*onDisconnected)(int64_t);
    // ...

    // 状态
    bool isConnected;
    bool isInBackground;
    uint64_t lastActivityTime;
} HarmonyOSContext;
```

**核心函数**:
```cpp
// 创建/销毁实例
int64_t freerdp_harmonyos_new(void);
void freerdp_harmonyos_free(int64_t instance);

// 连接管理
bool freerdp_harmonyos_connect(int64_t instance);
bool freerdp_harmonyos_disconnect(int64_t instance);

// 参数解析
bool freerdp_harmonyos_parse_arguments(int64_t instance,
                                        const char** args, size_t count);

// 输入事件
bool freerdp_harmonyos_send_cursor_event(int64_t instance,
                                          int x, int y, int flags);
bool freerdp_harmonyos_send_key_event(int64_t instance,
                                       int keycode, bool down);

// 后台模式
bool freerdp_harmonyos_enter_background_mode(int64_t instance);
bool freerdp_harmonyos_exit_background_mode(int64_t instance);

// 刷新
bool freerdp_harmonyos_request_refresh(int64_t instance);
```

**图形回调**:
```cpp
// 开始帧
static UINT HarmonyOSBeginPaint(rdpContext* context) {
    // 准备绘图
    return 0;
}

// 结束帧
static UINT HarmonyOSEndPaint(rdpContext* context) {
    // 通知 UI 刷新
    if (onGraphicsUpdate) {
        onGraphicsUpdate(instance, x, y, width, height);
    }
    return 0;
}

// 缓冲区操作
static UINT HarmonyOSAllocateBuffer(rdpContext* context) {
    // 分配像素缓冲区
}

static UINT HarmonyOSWriteBuffer(rdpContext* context, BYTE* data,
                                  int x, int y, int width, int height) {
    // 写入像素数据
}
```

### 9.3 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(freerdp_harmonyos)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# FreeRDP 库路径
set(FREERDP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../libs")

# 包含目录
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${FREERDP_DIR}/include
    ${FREERDP_DIR}/include/freerdp3
    ${FREERDP_DIR}/include/winpr3
)

# 链接目录
link_directories(
    ${FREERDP_DIR}/lib
    ${FREERDP_DIR}/arm64-v8a
)

# 源文件
set(NATIVE_SOURCES
    harmonyos_freerdp.cpp
    harmonyos_napi.cpp
    harmonyos_event.c
    harmonyos_cliprdr.c
    freerdp_client_compat.c
)

# 创建共享库
add_library(freerdp_harmonyos SHARED ${NATIVE_SOURCES})

# 链接库
target_link_libraries(freerdp_harmonyos
    ace_napi.z           # HarmonyOS N-API
    hilog_ndk.z          # 日志
    OpenSLES             # 音频

    freerdp-client3      # FreeRDP 客户端
    freerdp3             # FreeRDP 核心
    winpr3               # WinPR
)

# 编译选项
target_compile_options(freerdp_harmonyos PRIVATE
    -Wall -Wextra -O2 -fPIC
    -DOHOS_PLATFORM
)

# 导出符号
target_compile_definitions(freerdp_harmonyos PRIVATE
    NAPI_VERSION=8
)
```

---

## 10. 配置文件

### 10.1 app.json5 (应用配置)

```json
{
  "app": {
    "bundleName": "com.yjsoft.freerdp",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:layered_image",
    "label": "$string:app_name"
  }
}
```

### 10.2 module.json5 (模块配置)

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "mainElement": "EntryAbility",
    "deviceTypes": ["2in1", "phone", "tablet"],
    "pages": "$profile:main_pages",

    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_network_info_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
      },
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",
        "reason": "$string:permission_background_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
      },
      {
        "name": "ohos.permission.RUNNING_LOCK",
        "reason": "$string:permission_running_lock_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
      }
    ],

    "abilities": [{
      "name": "EntryAbility",
      "srcEntry": "./ets/entryability/EntryAbility.ets",
      "exported": true,
      "backgroundModes": ["audioPlayback", "dataTransfer"],
      "skills": [{
        "entities": ["entity.system.home"],
        "actions": ["ohos.want.action.home"]
      }]
    }]
  }
}
```

### 10.3 build-profile.json5 (构建配置)

```json
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "-O2 -DOHOS_PLATFORM -DWITH_OPENSSL -DWITH_FFMPEG",
      "abiFilters": ["arm64-v8a"]
    }
  }
}
```

### 10.4 main_pages.json (页面路由)

```json
{
  "src": [
    "pages/Index",
    "pages/SessionPage",
    "pages/BookmarkPage",
    "pages/SettingsPage",
    "pages/AboutPage"
  ]
}
```

---

## 11. 实现指南

### 11.1 开发环境设置

1. **安装 DevEco Studio** (最新版本)
2. **安装 HarmonyOS SDK** (API 12+)
3. **配置 NDK** (用于 Native 开发)
4. **准备 FreeRDP 预编译库**

### 11.2 项目创建步骤

1. **创建 HarmonyOS 项目**
   - 选择 "Empty Ability" 模板
   - 设置包名: `com.yjsoft.freerdp`
   - 目标 API: 12

2. **配置项目结构**
   ```
   创建目录:
   - entry/src/main/cpp/
   - entry/src/main/ets/pages/
   - entry/src/main/ets/components/
   - entry/src/main/ets/services/
   - entry/src/main/ets/model/
   - entry/libs/arm64-v8a/
   ```

3. **添加 FreeRDP 库**
   - 将预编译的 .so 文件放入 `entry/libs/arm64-v8a/`
   - 将头文件放入 `entry/libs/include/`

4. **配置 CMakeLists.txt**
   - 复制本文档中的 CMake 配置
   - 调整库路径

5. **配置 build-profile.json5**
   - 启用 Native 构建
   - 设置 ABI 过滤器

6. **实现 Native 层**
   - 实现 N-API 绑定
   - 实现 FreeRDP 封装

7. **实现 ArkTS 层**
   - 按照以下顺序实现:
     1. 数据模型 (BookmarkBase, SessionState)
     2. 服务层 (LibFreeRDP, NetworkManager, RdpBackgroundService)
     3. UI 组件 (SessionView, TouchPointerView, VirtualKeyboard)
     4. 页面 (Index, SessionPage, BookmarkPage, SettingsPage)

### 11.3 调试技巧

1. **启用详细日志**
   ```typescript
   debugSettings.debugLevel = 'DEBUG';  // 或 'TRACE'
   ```

2. **使用 HiLog**
   ```cpp
   #include <hilog/log.h>
   #define LOG_TAG "FreeRDP"
   OH_LOG_INFO(LOG_APP, "Message: %{public}s", value);
   ```

3. **自动连接测试**
   ```typescript
   // Index.ets
   autoConnectOnStart: boolean = true;  // 启动时自动连接
   ```

### 11.4 常见问题

1. **Native 库加载失败**
   - 检查 .so 文件架构 (必须是 arm64-v8a)
   - 检查依赖库是否完整
   - 检查 OpenSSL 环境变量配置

2. **连接成功后崩溃**
   - 检查回调函数是否正确设置
   - 检查线程安全回调实现
   - 检查内存管理

3. **后台音频中断**
   - 确保后台服务正确启动
   - 检查 `KEEP_BACKGROUND_RUNNING` 权限
   - 使用 `AUDIO_PLAYBACK` 后台模式

4. **网络断开后无法重连**
   - 检查网络监听是否正确设置
   - 检查重连延迟策略
   - 检查最大重试次数

### 11.5 性能优化

1. **图形渲染**
   - 使用 PixelMap 直接渲染
   - 启用 H.264 硬件解码 (如果支持)
   - 后台时禁用图形解码

2. **网络优化**
   - 启用 TCP Keepalive (15s)
   - 启用 RDP 心跳 (30s)
   - 使用异步通道

3. **内存优化**
   - 及时释放 PixelMap
   - 限制重连次数
   - 避免内存泄漏

---

## 附录

### A. FreeRDP 命令行参数

```
基础参数:
  /v:<host>           目标主机
  /port:<port>        端口号
  /u:<username>       用户名
  /p:<password>       密码
  /d:<domain>         域

显示参数:
  /size:<WxH>         分辨率
  /bpp:<8|16|24|32>   颜色深度

性能参数:
  /rfx                启用 RemoteFX
  /gfx                启用 GFX
  /gfx:AVC444         启用 H.264
  +wallpaper          显示壁纸
  -wallpaper          隐藏壁纸
  +fonts              字体平滑
  +aero               桌面合成

安全参数:
  /sec:<rdp|tls|nla>  安全模式
  /cert:ignore        忽略证书

音频参数:
  /audio-mode:<0|1|2> 0=本地,1=远程,2=禁用
  /sound              音频重定向
  /microphone         麦克风重定向

其他:
  /admin              管理会话
  /clipboard          剪贴板
  /gateway:g:<host>:<port>,u:<user>,p:<pass>  网关
```

### B. 参考资料

- [FreeRDP 官方文档](https://www.freerdp.com/)
- [HarmonyOS 开发文档](https://developer.harmonyos.com/)
- [ArkUI 组件参考](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkui-ts-components-0000001158313481)
- [N-API 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/napi-guidelines-0000001493903956)

---

**文档结束**
