/*
 * HarmonyOS FreeRDP Session Page
 * 
 * Remote desktop session view with full interaction support
 * 
 * Copyright 2026 FreeRDP HarmonyOS Port
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import image from '@ohos.multimedia.image';
import { BookmarkBase } from '../model/BookmarkBase';
import { SessionState, ConnectionState, GlobalSessionManager } from '../model/SessionState';
import LibFreeRDP, { EventListener, BookmarkSettings, ScreenSettings, AdvancedSettings, PerformanceFlags, DebugSettings, GatewaySettings } from '../services/LibFreeRDP';
import { RdpBackgroundService } from '../services/RdpBackgroundService';
import { NetworkManager, SessionInfo } from '../services/NetworkManager';
import { SessionView } from '../components/SessionView';
import { TouchPointerView } from '../components/TouchPointerView';
import { VirtualKeyboard } from '../components/VirtualKeyboard';

/**
 * Router params interface
 */
interface SessionPageParams {
  bookmark?: object;
}

const TAG = 'SessionPage';

// Global callbacks for event listener (workaround for ArkTS struct limitations)
let globalOnPreConnectCallback: ((instance: number) => void) | null = null;
let globalOnConnectionSuccessCallback: ((instance: number) => void) | null = null;
let globalOnConnectionFailureCallback: ((instance: number) => void) | null = null;
let globalOnDisconnectingCallback: ((instance: number) => void) | null = null;
let globalOnDisconnectedCallback: ((instance: number) => void) | null = null;

/**
 * Session event listener implementation class
 */
class SessionEventListenerImpl implements EventListener {
  OnPreConnect(instance: number): void {
    if (globalOnPreConnectCallback) {
      globalOnPreConnectCallback(instance);
    }
  }

  OnConnectionSuccess(instance: number): void {
    if (globalOnConnectionSuccessCallback) {
      globalOnConnectionSuccessCallback(instance);
    }
  }

  OnConnectionFailure(instance: number): void {
    if (globalOnConnectionFailureCallback) {
      globalOnConnectionFailureCallback(instance);
    }
  }

  OnDisconnecting(instance: number): void {
    if (globalOnDisconnectingCallback) {
      globalOnDisconnectingCallback(instance);
    }
  }

  OnDisconnected(instance: number): void {
    if (globalOnDisconnectedCallback) {
      globalOnDisconnectedCallback(instance);
    }
  }
}

// Heartbeat interval for keeping connection alive
const HEARTBEAT_INTERVAL_MS = 30000;

@Entry
@Component
struct SessionPage {
  // Session state
  @State session: SessionState | null = null;
  @State @Watch('onConnectionStateChanged') connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @State statusMessage: string = '正在连接...';
  
  // Display state
  @State desktopWidth: number = 1920;
  @State desktopHeight: number = 1080;
  @State pixelMap: image.PixelMap | null = null;
  @State pixelMapVersion: number = 0;  // Force UI update

  // Screen dimensions for coordinate conversion
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  @State viewScale: number = 1.0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  
  // UI state
  @State showToolbar: boolean = true;
  @State showKeyboard: boolean = false;
  @State cursorType: number = 1;
  @State isInBackground: boolean = false;
  @State isScreenLocked: boolean = false;
  @State remoteDesktopHasFocus: boolean = false;  // Track if remote desktop has focus
  @State keyboardInputText: string = '';  // Hidden TextInput for IME input
  private keyboardInputController: TextInputController = new TextInputController();
  private lastInputLength: number = 0;
  private lastKeyPressTime: number = 0;  // Track last key press time
  private keyEventHandled: boolean = false;  // Prevent double-handling between onKeyEvent and onChange
  
  // Components
  private sessionView: SessionView | null = null;
  private touchPointerView: TouchPointerView | null = null;
  private virtualKeyboard: VirtualKeyboard | null = null;
  
  // Services
  private backgroundService: RdpBackgroundService | null = null;
  private context = getContext(this) as common.UIAbilityContext;
  
  // Heartbeat timer
  private heartbeatTimer: number = -1;

  // Auto-hide toolbar timer
  private toolbarHideTimer: number = -1;
  private static readonly TOOLBAR_HIDE_DELAY = 4000;

  /**
   * Watch connectionState changes
   */
  onConnectionStateChanged(): void {
    console.info(`${TAG}: connectionState changed to ${this.connectionState} (CONNECTED=${ConnectionState.CONNECTED})`);
    console.info(`${TAG}: Will render ${this.connectionState === ConnectionState.CONNECTED ? 'SessionView' : 'status view'}`);
  }

  aboutToAppear(): void {
    console.info(`${TAG}: aboutToAppear`);
    
    // Get bookmark from router params
    const params = router.getParams() as SessionPageParams;
    if (params && params.bookmark) {
      const bookmark = BookmarkBase.fromJson(params.bookmark);
      this.initSession(bookmark);
    } else {
      console.error(`${TAG}: No bookmark provided`);
      this.statusMessage = '错误：未提供连接信息';
    }
    
    // Initialize network manager
    NetworkManager.initialize();
    NetworkManager.setOnNetworkLostCallback(() => {
      this.onNetworkLost();
    });
    NetworkManager.setOnReconnectSuccessCallback(() => {
      this.onReconnectSuccess();
    });
    
    // Keep screen on
    this.setKeepScreenOn(true);
  }

  aboutToDisappear(): void {
    console.info(`${TAG}: aboutToDisappear`);
    
    this.cleanup();
  }

  onPageShow(): void {
    console.info(`${TAG}: onPageShow`);
    this.isInBackground = false;

    // Enter fullscreen immersive mode
    this.setFullScreen(true);

    if (this.session) {
      this.session.setInBackground(false);
      // Resume graphics
      if (this.session.getInstance() !== 0) {
        LibFreeRDP.setClientDecoding(this.session.getInstance(), true);
      }
    }
  }

  onPageHide(): void {
    console.info(`${TAG}: onPageHide`);
    this.isInBackground = true;

    // Exit fullscreen
    this.setFullScreen(false);

    if (this.session) {
      this.session.setInBackground(true);
      // Suppress graphics but keep audio
      if (this.session.getInstance() !== 0) {
        LibFreeRDP.setClientDecoding(this.session.getInstance(), false);
      }
    }
  }

  /**
   * Initialize session with bookmark
   */
  private async initSession(bookmark: BookmarkBase): Promise<void> {
    console.info(`${TAG}: Initializing session for ${bookmark.hostname}`);

    // Create session state
    this.session = new SessionState(bookmark);
    this.connectionState = ConnectionState.CONNECTING;
    this.statusMessage = '正在连接...';

    // Set up event listener callbacks
    globalOnPreConnectCallback = (instance: number): void => {
      console.info(`${TAG}: OnPreConnect`);
      this.statusMessage = '正在建立连接...';
    };
    globalOnConnectionSuccessCallback = (instance: number): void => {
      console.info(`${TAG}: OnConnectionSuccess`);
      this.onConnectionSuccess(instance);
    };
    globalOnConnectionFailureCallback = (instance: number): void => {
      console.error(`${TAG}: OnConnectionFailure`);
      this.onConnectionFailure(instance);
    };
    globalOnDisconnectingCallback = (instance: number): void => {
      console.info(`${TAG}: OnDisconnecting`);
      this.statusMessage = '正在断开连接...';
    };
    globalOnDisconnectedCallback = (instance: number): void => {
      console.info(`${TAG}: OnDisconnected`);
      this.onDisconnected(instance);
    };

    // Set up event listener
    const eventListener = new SessionEventListenerImpl();
    LibFreeRDP.setEventListener(eventListener);

    // Set up graphics update callbacks
    LibFreeRDP.setOnGraphicsUpdateCallback((x: number, y: number, width: number, height: number) => {
      if (this.session && this.session.getInstance() !== 0) {
        this.updateGraphics();
      }
    });

    LibFreeRDP.setOnGraphicsResizeCallback((width: number, height: number, bpp: number) => {
      console.info(`${TAG}: OnGraphicsResize: ${width}x${height}@${bpp}bpp`);
      this.desktopWidth = width;
      this.desktopHeight = height;
      if (this.session) {
        this.session.updateDisplaySettings(width, height, bpp);
      }
      // Recreate pixel map with new dimensions and update graphics
      this.createPixelMap();
      // Immediately get real FreeRDP data
      this.updateGraphics();
    });

    LibFreeRDP.setOnSettingsChangedCallback((width: number, height: number, bpp: number) => {
      console.info(`${TAG}: OnSettingsChanged: ${width}x${height}@${bpp}bpp`);
      this.desktopWidth = width;
      this.desktopHeight = height;
      if (this.session) {
        this.session.updateDisplaySettings(width, height, bpp);
      }
      // Recreate pixel map with new dimensions
      this.createPixelMap();
    });

    // Create FreeRDP instance
    const instance = LibFreeRDP.newInstance();
    if (instance === 0) {
      this.statusMessage = '错误：无法创建连接实例';
      this.connectionState = ConnectionState.DISCONNECTED;
      return;
    }

    this.session.setInstance(instance);
    GlobalSessionManager.registerSession(instance, this.session);

    // Set connection info
    const connectionInfo: BookmarkSettings = this.createConnectionInfo(bookmark);
    if (!LibFreeRDP.setConnectionInfo(instance, connectionInfo)) {
      this.statusMessage = '错误：连接参数无效';
      this.connectionState = ConnectionState.DISCONNECTED;
      return;
    }

    // Set session info for reconnection
    const sessionInfo: SessionInfo = {
      instance: instance,
      hostname: bookmark.hostname,
      port: bookmark.port,
      username: bookmark.username,
      domain: bookmark.domain,
      password: bookmark.password
    };
    NetworkManager.setSessionInfo(sessionInfo);

    // Connect
    if (!LibFreeRDP.connect(instance)) {
      this.statusMessage = '错误：连接失败';
      this.connectionState = ConnectionState.DISCONNECTED;
    }
  }

  /**
   * Create or recreate pixel map with current dimensions
   */
  private async createPixelMap(): Promise<void> {
    if (this.desktopWidth <= 0 || this.desktopHeight <= 0) {
      console.warn(`${TAG}: Cannot create pixel map - invalid dimensions`);
      return;
    }

    // Release old pixel map
    if (this.pixelMap) {
      this.pixelMap.release();
      this.pixelMap = null;
    }

    try {
      // Create empty PixelMap with correct dimensions
      const buffer = new ArrayBuffer(this.desktopWidth * this.desktopHeight * 4);

      // Create pixel map with inline options
      this.pixelMap = await image.createPixelMap(buffer, {
        size: { width: this.desktopWidth, height: this.desktopHeight },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.OPAQUE,
        editable: true
      } as image.InitializationOptions);
      console.info(`${TAG}: PixelMap created: ${this.desktopWidth}x${this.desktopHeight}`);
    } catch (error) {
      console.error(`${TAG}: Failed to create pixel map:`, error);
    }
  }

  /**
   * Update graphics from frame buffer
   */
  private async updateGraphics(): Promise<void> {
    if (!this.session || this.session.getInstance() === 0) {
      return;
    }

    try {
      // Get frame buffer from native
      const frameBuffer = LibFreeRDP.getFrameBuffer(this.session.getInstance());
      if (!frameBuffer) {
        return;
      }

      console.info(`${TAG}: Frame buffer received, size: ${frameBuffer.byteLength} bytes`);

      // Create NEW PixelMap with inline options
      const newPixelMap = await image.createPixelMap(frameBuffer, {
        size: { width: this.desktopWidth, height: this.desktopHeight },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.OPAQUE,
        editable: false
      } as image.InitializationOptions);

      // Release old PixelMap AFTER creating new one
      if (this.pixelMap) {
        this.pixelMap.release();
      }

      // Replace with new PixelMap
      this.pixelMap = newPixelMap;
      this.pixelMapVersion++;

      console.info(`${TAG}: PixelMap updated, version: ${this.pixelMapVersion}`);
    } catch (error) {
      console.error(`${TAG}: Failed to update graphics:`, error);
    }
  }

  /**
   * Handle connection success
   */
  private async onConnectionSuccess(instance: number): Promise<void> {
    console.info(`${TAG}: onConnectionSuccess called, setting connectionState to CONNECTED`);
    this.connectionState = ConnectionState.CONNECTED;
    this.statusMessage = '已连接';
    console.info(`${TAG}: connectionState set to ${this.connectionState}, statusMessage=${this.statusMessage}`);

    if (this.session) {
      this.session.setConnectionState(ConnectionState.CONNECTED);
    }

    // Start background service
    this.backgroundService = new RdpBackgroundService(this.context);
    await this.backgroundService.start();

    // Start heartbeat
    this.startHeartbeat();

    // Auto-hide toolbar
    this.scheduleToolbarHide();

    promptAction.showToast({ message: '连接成功' });
  }

  /**
   * Handle connection failure
   */
  private onConnectionFailure(instance: number): void {
    const errorStr = LibFreeRDP.getLastErrorString(instance);
    this.statusMessage = `连接失败: ${errorStr}`;
    this.connectionState = ConnectionState.DISCONNECTED;
    
    if (this.session) {
      this.session.setConnectionState(ConnectionState.DISCONNECTED);
    }
    
    promptAction.showToast({ message: `连接失败: ${errorStr}` });
  }

  /**
   * Handle disconnection
   */
  private async onDisconnected(instance: number): Promise<void> {
    this.connectionState = ConnectionState.DISCONNECTED;
    this.statusMessage = '已断开连接';
    
    if (this.session) {
      this.session.setConnectionState(ConnectionState.DISCONNECTED);
    }
    
    // Stop background service
    if (this.backgroundService) {
      await this.backgroundService.stop();
    }
    
    // Stop heartbeat
    this.stopHeartbeat();
    
    promptAction.showToast({ message: '连接已断开' });
  }

  /**
   * Handle network lost
   */
  private onNetworkLost(): void {
    console.warn(`${TAG}: Network lost`);
    this.statusMessage = '网络连接丢失，正在等待重连...';
    this.connectionState = ConnectionState.RECONNECTING;
  }

  /**
   * Handle reconnect success
   */
  private onReconnectSuccess(): void {
    console.info(`${TAG}: Reconnect success`);
    this.statusMessage = '已重新连接';
    this.connectionState = ConnectionState.CONNECTED;
    promptAction.showToast({ message: '已重新连接' });
  }

  /**
   * Setup screen lock listener
   * Note: screenLock.on/off API is not available in current SDK version
   */
  private setupScreenLockListener(): void {
    // Screen lock monitoring is not available in current SDK
    console.info(`${TAG}: Screen lock listener setup skipped (API not available)`);
  }

  /**
   * Start heartbeat timer
   */
  private startHeartbeat(): void {
    this.stopHeartbeat();
    
    const heartbeatCallback = (): void => {
      if (this.session && this.session.getInstance() !== 0 && 
          this.connectionState === ConnectionState.CONNECTED) {
        LibFreeRDP.sendHeartbeat(this.session.getInstance());
      }
    };
    this.heartbeatTimer = setInterval(heartbeatCallback, HEARTBEAT_INTERVAL_MS) as number;
    
    console.info(`${TAG}: Heartbeat started (interval: ${HEARTBEAT_INTERVAL_MS}ms)`);
  }

  /**
   * Stop heartbeat timer
   */
  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
      console.info(`${TAG}: Heartbeat stopped`);
    }
  }

  /**
   * Create connection info from bookmark
   */
  private createConnectionInfo(bookmark: BookmarkBase): BookmarkSettings {
    // Create screen settings with explicit type
    const screenSettings: ScreenSettings = {
      width: bookmark.screenSettings.width,
      height: bookmark.screenSettings.height,
      colors: bookmark.screenSettings.colors
    };

    // Create advanced settings with explicit type
    const advancedSettings: AdvancedSettings = {
      consoleMode: bookmark.advancedSettings.consoleMode,
      security: bookmark.advancedSettings.security,
      remoteProgram: bookmark.advancedSettings.remoteProgram,
      workDir: bookmark.advancedSettings.workDir,
      redirectSDCard: bookmark.advancedSettings.redirectSDCard,
      redirectSound: bookmark.advancedSettings.redirectSound,
      redirectMicrophone: bookmark.advancedSettings.redirectMicrophone
    };

    // Create performance flags with explicit type
    const performanceFlags: PerformanceFlags = {
      remoteFX: bookmark.performanceFlags.remoteFX,
      gfx: bookmark.performanceFlags.gfx,
      h264: bookmark.performanceFlags.h264,
      wallpaper: bookmark.performanceFlags.wallpaper,
      fullWindowDrag: bookmark.performanceFlags.fullWindowDrag,
      menuAnimations: bookmark.performanceFlags.menuAnimations,
      theming: bookmark.performanceFlags.theming,
      fontSmoothing: bookmark.performanceFlags.fontSmoothing,
      desktopComposition: bookmark.performanceFlags.desktopComposition
    };

    // Create debug settings with explicit type
    const debugSettings: DebugSettings = {
      asyncChannel: bookmark.debugSettings.asyncChannel,
      asyncUpdate: bookmark.debugSettings.asyncUpdate,
      debugLevel: bookmark.debugSettings.debugLevel
    };

    // Create bookmark settings
    const info: BookmarkSettings = {
      hostname: bookmark.hostname,
      port: bookmark.port,
      username: bookmark.username,
      domain: bookmark.domain,
      password: bookmark.password,
      screenSettings: screenSettings,
      advancedSettings: advancedSettings,
      performanceFlags: performanceFlags,
      debugSettings: debugSettings
    };

    // Add gateway settings if enabled
    if (bookmark.gatewaySettings && bookmark.gatewaySettings.enabled) {
      const gatewaySettings: GatewaySettings = {
        enabled: bookmark.gatewaySettings.enabled,
        hostname: bookmark.gatewaySettings.hostname,
        port: bookmark.gatewaySettings.port,
        username: bookmark.gatewaySettings.username,
        domain: bookmark.gatewaySettings.domain,
        password: bookmark.gatewaySettings.password
      };
      info.gatewaySettings = gatewaySettings;
    }
    return info;
  }

  /**
   * Schedule toolbar auto-hide
   */
  private scheduleToolbarHide(): void {
    if (this.toolbarHideTimer !== -1) {
      clearTimeout(this.toolbarHideTimer);
    }
    
    const hideCallback = (): void => {
      this.showToolbar = false;
    };
    this.toolbarHideTimer = setTimeout(hideCallback, SessionPage.TOOLBAR_HIDE_DELAY) as number;
  }

  /**
   * Toggle toolbar visibility
   */
  private toggleToolbar(): void {
    this.showToolbar = !this.showToolbar;
    if (this.showToolbar) {
      this.scheduleToolbarHide();
    }
  }

  /**
   * Disconnect
   */
  private disconnect(): void {
    if (this.session && this.session.getInstance() !== 0) {
      LibFreeRDP.disconnect(this.session.getInstance());
    }
  }

  /**
   * Set keep screen on
   */
  private async setKeepScreenOn(keepOn: boolean): Promise<void> {
    try {
      const win = await window.getLastWindow(this.context);
      await win.setWindowKeepScreenOn(keepOn);
    } catch (error) {
      console.error(`${TAG}: Failed to set keep screen on:`, error);
    }
  }

  /**
   * Set fullscreen immersive mode
   */
  private async setFullScreen(fullscreen: boolean): Promise<void> {
    try {
      const win = await window.getLastWindow(this.context);
      if (fullscreen) {
        // Hide status bar and navigation bar
        await win.setWindowSystemBarEnable([]);
        await win.setWindowLayoutFullScreen(true);
        console.info(`${TAG}: Fullscreen mode enabled`);
      } else {
        await win.setWindowSystemBarEnable(['status', 'navigation']);
        await win.setWindowLayoutFullScreen(false);
        console.info(`${TAG}: Fullscreen mode disabled`);
      }
    } catch (error) {
      console.error(`${TAG}: Failed to set fullscreen:`, error);
    }
  }

  /**
   * Cleanup resources
   */
  private async cleanup(): Promise<void> {
    console.info(`${TAG}: Cleaning up`);
    
    // Stop timers
    this.stopHeartbeat();
    if (this.toolbarHideTimer !== -1) {
      clearTimeout(this.toolbarHideTimer);
    }
    
    // Disconnect
    if (this.session && this.session.getInstance() !== 0) {
      LibFreeRDP.freeInstance(this.session.getInstance());
      GlobalSessionManager.removeSession(this.session.getInstance());
    }
    
    // Stop background service
    if (this.backgroundService) {
      await this.backgroundService.stop();
    }
    
    // Clear network manager
    NetworkManager.clearSessionInfo();
    
    // Allow screen to turn off
    this.setKeepScreenOn(false);
    
    // Screen lock listener cleanup not needed (API not available)
  }

  /**
   * Go back
   */
  private goBack(): void {
    promptAction.showDialog({
      title: '断开连接',
      message: '确定要断开远程桌面连接吗？',
      buttons: [
        { text: '取消', color: '#888888' },
        { text: '断开', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.disconnect();
        router.back();
      }
    });
  }

  @Builder
  Toolbar() {
    Row() {
      // Back button
      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor('#80424242')
      .onClick(() => {
        this.goBack();
      })
      
      Blank()
      
      // Status
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#80000000')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(16)
      
      Blank()
      
      // Keyboard button
      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_edit'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor('#80424242')
      .margin({ right: 8 })
      .onClick(() => {
        this.showKeyboard = !this.showKeyboard;
      })
      
      // More options
      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_more'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor('#80424242')
      .onClick(() => {
        // TODO: Show more options menu
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#40000000')
  }

  build() {
    Stack() {
      // Direct rendering with coordinate conversion
      if (this.connectionState === ConnectionState.CONNECTED && this.pixelMap) {
        Stack() {
          Image(this.pixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .onComplete(() => {
              console.info(`${TAG}: Image onComplete`);
            })
            .onError(() => {
              console.error(`${TAG}: Image onError`);
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .onAreaChange((oldValue: Area, newValue: Area) => {
          // Track screen dimensions for coordinate conversion
          this.screenWidth = newValue.width as number;
          this.screenHeight = newValue.height as number;
          console.info(`${TAG}: Screen size: ${this.screenWidth}x${this.screenHeight}`);
        })
        .hitTestBehavior(HitTestMode.Block)
        .onTouch((event: TouchEvent) => {
          if (!this.session || this.session.getInstance() === 0) {
            return;
          }

          if (!event.touches || event.touches.length === 0) {
            return;
          }

          try {
            const touch = event.touches[0];
            const touchX = touch.x;
            const touchY = touch.y;

            // Calculate coordinate conversion for ImageFit.Contain
            const scaleX = this.screenWidth / this.desktopWidth;
            const scaleY = this.screenHeight / this.desktopHeight;
            const scale = Math.min(scaleX, scaleY);

            const displayedWidth = this.desktopWidth * scale;
            const displayedHeight = this.desktopHeight * scale;

            const offsetX = (this.screenWidth - displayedWidth) / 2;
            const offsetY = (this.screenHeight - displayedHeight) / 2;

            const desktopX = Math.floor((touchX - offsetX) / scale);
            const desktopY = Math.floor((touchY - offsetY) / scale);

            const x = Math.max(0, Math.min(desktopX, this.desktopWidth - 1));
            const y = Math.max(0, Math.min(desktopY, this.desktopHeight - 1));

            const PTR_FLAGS_MOVE = 0x0800;
            const PTR_FLAGS_DOWN = 0x8000;
            const PTR_FLAGS_BUTTON1 = 0x1000;

            if (event.type === TouchType.Down) {
              console.info(`${TAG}: Touch DOWN screen(${touchX.toFixed(0)}, ${touchY.toFixed(0)}) -> desktop(${x}, ${y})`);
              LibFreeRDP.sendCursorEvent(this.session.getInstance(), x, y, PTR_FLAGS_DOWN | PTR_FLAGS_BUTTON1);

              // Mark as focused
              this.remoteDesktopHasFocus = true;
            } else if (event.type === TouchType.Up) {
              console.info(`${TAG}: Touch UP screen(${touchX.toFixed(0)}, ${touchY.toFixed(0)}) -> desktop(${x}, ${y})`);
              LibFreeRDP.sendCursorEvent(this.session.getInstance(), x, y, PTR_FLAGS_BUTTON1);
            } else if (event.type === TouchType.Move) {
              LibFreeRDP.sendCursorEvent(this.session.getInstance(), x, y, PTR_FLAGS_MOVE);
            }
          } catch (error) {
            console.error(`${TAG}: Touch handling error:`, error);
          }

          // Consume event to prevent propagation
          event.stopPropagation();
        })
      } else {
        // Connection status view
        Column() {
          if (this.connectionState === ConnectionState.CONNECTING ||
              this.connectionState === ConnectionState.RECONNECTING) {
            LoadingProgress()
              .width(64)
              .height(64)
              .color('#2196F3')
          } else {
            Image($r('sys.media.ohos_ic_public_fail'))
              .width(64)
              .height(64)
              .fillColor('#F44336')
          }
          
          Text(this.statusMessage)
            .fontSize(18)
            .fontColor('#FFFFFF')
            .margin({ top: 24 })
            .textAlign(TextAlign.Center)
          
          if (this.connectionState === ConnectionState.DISCONNECTED) {
            Button('返回')
              .width(120)
              .height(44)
              .backgroundColor('#2196F3')
              .margin({ top: 24 })
              .onClick(() => {
                router.back();
              })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#121212')
        .justifyContent(FlexAlign.Center)
      }
      
      // Touch pointer (when connected)
      if (this.connectionState === ConnectionState.CONNECTED) {
        TouchPointerView({
          instance: this.session?.getInstance() ?? 0,
          viewWidth: 0, // Will be set by SessionView
          viewHeight: 0,
          desktopWidth: this.desktopWidth,
          desktopHeight: this.desktopHeight,
          viewScale: this.viewScale,
          offsetX: this.offsetX,
          offsetY: this.offsetY
        })
      }
      
      // Toolbar
      if (this.showToolbar) {
        Column() {
          this.Toolbar()
        }
        .width('100%')
        .position({ x: 0, y: 0 })
      }
      
      // Virtual keyboard
      if (this.showKeyboard) {
        Column() {
          VirtualKeyboard({
            instance: this.session?.getInstance() ?? 0
          })
        }
        .width('100%')
        .position({ x: 0, y: '100%' })
        .translate({ y: -200 })
      }

      // Hidden TextInput for keyboard input (used only to capture focus and IME Chinese input)
      if (this.connectionState === ConnectionState.CONNECTED) {
        TextInput({ text: $$this.keyboardInputText, controller: this.keyboardInputController })
          .width(1)
          .height(1)
          .position({ x: -100, y: -100 })
          .opacity(0)
          .focusable(true)
          .defaultFocus(true)
          .id('hiddenKeyboardInput')
          .onChange((value: string) => {
            if (!this.session || this.session.getInstance() === 0) {
              return;
            }

            this.lastKeyPressTime = Date.now();
            this.remoteDesktopHasFocus = true;

            // If key was already handled by onKeyEvent, skip
            if (this.keyEventHandled) {
              this.keyEventHandled = false;
              this.lastInputLength = value.length;
              return;
            }

            console.info(`${TAG}: TextInput onChange (IME): "${value}", lastLength=${this.lastInputLength}`);

            const instance = this.session.getInstance();

            // Only handle NEW characters added (IME composition results like Chinese)
            if (value.length > this.lastInputLength) {
              const newChars = value.substring(this.lastInputLength);
              console.info(`${TAG}: IME new chars: "${newChars}"`);

              for (let i = 0; i < newChars.length; i++) {
                const charCode = newChars.charCodeAt(i);
                // Skip control characters
                if (charCode < 32) {
                  continue;
                }
                console.info(`${TAG}: IME sending Unicode: ${charCode}`);
                LibFreeRDP.sendUnicodeKeyEvent(instance, charCode, true);
                LibFreeRDP.sendUnicodeKeyEvent(instance, charCode, false);
              }
            }
            // Do NOT handle Backspace/deletion here - handled entirely by onKeyEvent

            this.lastInputLength = value.length;
          })
          .onKeyEvent((event: KeyEvent) => {
            if (!this.session || this.session.getInstance() === 0) {
              return;
            }

            // Record key press time to prevent onClick from triggering
            this.lastKeyPressTime = Date.now();

            const keyText = event.keyText || '';
            console.info(`${TAG}: onKeyEvent: type=${event.type}, keyCode=${event.keyCode}, keyText="${keyText}"`);

            // Only process KeyType.Down events (send immediate down+up pair, like Android aFreeRDP)
            if (event.type !== KeyType.Down) {
              return;
            }

            this.remoteDesktopHasFocus = true;

            const instance = this.session.getInstance();
            const keyCode = event.keyCode;

            // KBDEXT flag (0x100) - must be set for extended keys (arrows, delete, etc.)
            // The native GetVirtualScanCodeFromVirtualKeyCode checks vkcode & KBDEXT
            // to decide which lookup table to use (KBD4T for standard, KBD4X for extended)
            const KBDEXT = 0x100;

            // Helper: send immediate key down + up pair (matches Android aFreeRDP behavior)
            const sendKeyImmediate = (vk: number): void => {
              LibFreeRDP.sendKeyEvent(instance, vk, true);
              LibFreeRDP.sendKeyEvent(instance, vk, false);
            };

            // ---- Enter (standard key, no KBDEXT needed) ----
            if (keyCode === 2054 || keyCode === 66 || keyText === 'Enter' || keyText === '\n') {
              console.info(`${TAG}: Enter key (keyCode=${keyCode})`);
              sendKeyImmediate(0x0D);
              this.keyEventHandled = true;
              this.keyboardInputText = '';
              this.lastInputLength = 0;
              event.stopPropagation();
              return;
            }

            // ---- Backspace (standard key, no KBDEXT needed) ----
            if (keyCode === 2055 || keyCode === 67 || keyText === 'Backspace') {
              console.info(`${TAG}: Backspace key (keyCode=${keyCode})`);
              sendKeyImmediate(0x08);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Delete (EXTENDED key - needs KBDEXT flag!) ----
            if (keyCode === 2056 || keyCode === 112 || keyCode === 2061 || keyText === 'Delete' || keyText === 'Del') {
              console.info(`${TAG}: Delete key (keyCode=${keyCode}), VK=0x${(0x2E | KBDEXT).toString(16)}`);
              sendKeyImmediate(0x2E | KBDEXT);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Arrow Up (EXTENDED key) ----
            if (keyCode === 2012 || keyCode === 19 || keyCode === 2051 || keyText === 'ArrowUp' || keyText === 'Up') {
              console.info(`${TAG}: ArrowUp key (keyCode=${keyCode}), VK=0x${(0x26 | KBDEXT).toString(16)}`);
              sendKeyImmediate(0x26 | KBDEXT);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Arrow Down (EXTENDED key) ----
            if (keyCode === 2013 || keyCode === 20 || keyCode === 2052 || keyText === 'ArrowDown' || keyText === 'Down') {
              console.info(`${TAG}: ArrowDown key (keyCode=${keyCode}), VK=0x${(0x28 | KBDEXT).toString(16)}`);
              sendKeyImmediate(0x28 | KBDEXT);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Arrow Left (EXTENDED key) ----
            if (keyCode === 2014 || keyCode === 21 || keyCode === 2050 || keyText === 'ArrowLeft' || keyText === 'Left') {
              console.info(`${TAG}: ArrowLeft key (keyCode=${keyCode}), VK=0x${(0x25 | KBDEXT).toString(16)}`);
              sendKeyImmediate(0x25 | KBDEXT);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Arrow Right (EXTENDED key) ----
            if (keyCode === 2015 || keyCode === 22 || keyCode === 2053 || keyText === 'ArrowRight' || keyText === 'Right') {
              console.info(`${TAG}: ArrowRight key (keyCode=${keyCode}), VK=0x${(0x27 | KBDEXT).toString(16)}`);
              sendKeyImmediate(0x27 | KBDEXT);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Tab (standard key) ----
            if (keyCode === 2049 || keyCode === 61 || keyText === 'Tab') {
              console.info(`${TAG}: Tab key (keyCode=${keyCode})`);
              sendKeyImmediate(0x09);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Escape (standard key) ----
            if (keyCode === 111 || keyCode === 2070 || keyText === 'Escape' || keyText === 'Esc') {
              console.info(`${TAG}: Escape key (keyCode=${keyCode})`);
              sendKeyImmediate(0x1B);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Space - send via Unicode ----
            if (keyCode === 2044 || keyCode === 62 || keyText === ' ') {
              console.info(`${TAG}: Space key (keyCode=${keyCode})`);
              LibFreeRDP.sendUnicodeKeyEvent(instance, 32, true);
              LibFreeRDP.sendUnicodeKeyEvent(instance, 32, false);
              this.keyEventHandled = true;
              event.stopPropagation();
              return;
            }

            // ---- Printable characters: send via Unicode ----
            if (keyText.length === 1) {
              const charCode = keyText.charCodeAt(0);
              if (charCode >= 32) {
                console.info(`${TAG}: Printable char '${keyText}' (${charCode}) via onKeyEvent`);
                LibFreeRDP.sendUnicodeKeyEvent(instance, charCode, true);
                LibFreeRDP.sendUnicodeKeyEvent(instance, charCode, false);
                this.keyEventHandled = true;
                return;
              }
            }

            // Log unhandled keys
            console.warn(`${TAG}: Unhandled key: keyCode=${keyCode}, keyText="${keyText}"`);
          })
          .onSubmit(() => {
            // Consume Enter submit event to prevent TextInput from losing focus
            // The actual Enter key is handled in onKeyEvent above
            console.info(`${TAG}: TextInput onSubmit consumed (preventing focus loss)`);
          })
          .onFocus(() => {
            this.remoteDesktopHasFocus = true;
            console.info(`${TAG}: Keyboard input focused`);
          })
          .onBlur(() => {
            this.remoteDesktopHasFocus = false;
            console.info(`${TAG}: Keyboard input blurred`);
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .onKeyEvent((event: KeyEvent) => {
      // Fallback handler on Stack: catches keys that TextInput might miss
      // (e.g., Delete/Arrows consumed by TextInput's internal text editing)
      if (!this.session || this.session.getInstance() === 0 || this.connectionState !== ConnectionState.CONNECTED) {
        return;
      }

      // Only process Down events
      if (event.type !== KeyType.Down) {
        return;
      }

      // If TextInput already handled this key, skip
      if (this.keyEventHandled) {
        this.keyEventHandled = false;
        return;
      }

      const instance = this.session.getInstance();
      const keyCode = event.keyCode;
      const keyText = event.keyText || '';

      // KBDEXT flag for extended keys
      const KBDEXT = 0x100;
      const sendKeyImmediate = (vk: number): void => {
        LibFreeRDP.sendKeyEvent(instance, vk, true);
        LibFreeRDP.sendKeyEvent(instance, vk, false);
      };

      console.info(`${TAG}: Stack onKeyEvent fallback: keyCode=${keyCode}, keyText="${keyText}"`);

      // Enter
      if (keyCode === 2054 || keyCode === 66 || keyText === 'Enter' || keyText === '\n') {
        sendKeyImmediate(0x0D);
        this.keyboardInputText = '';
        this.lastInputLength = 0;
        event.stopPropagation();
        return;
      }
      // Delete (extended)
      if (keyCode === 2056 || keyCode === 112 || keyCode === 2061 || keyText === 'Delete' || keyText === 'Del') {
        sendKeyImmediate(0x2E | KBDEXT);
        event.stopPropagation();
        return;
      }
      // Arrow Up (extended)
      if (keyCode === 2012 || keyCode === 19 || keyCode === 2051 || keyText === 'ArrowUp' || keyText === 'Up') {
        sendKeyImmediate(0x26 | KBDEXT);
        event.stopPropagation();
        return;
      }
      // Arrow Down (extended)
      if (keyCode === 2013 || keyCode === 20 || keyCode === 2052 || keyText === 'ArrowDown' || keyText === 'Down') {
        sendKeyImmediate(0x28 | KBDEXT);
        event.stopPropagation();
        return;
      }
      // Arrow Left (extended)
      if (keyCode === 2014 || keyCode === 21 || keyCode === 2050 || keyText === 'ArrowLeft' || keyText === 'Left') {
        sendKeyImmediate(0x25 | KBDEXT);
        event.stopPropagation();
        return;
      }
      // Arrow Right (extended)
      if (keyCode === 2015 || keyCode === 22 || keyCode === 2053 || keyText === 'ArrowRight' || keyText === 'Right') {
        sendKeyImmediate(0x27 | KBDEXT);
        event.stopPropagation();
        return;
      }
    })
    .onClick(() => {
      // Check if this click is from keyboard (space/enter)
      const now = Date.now();
      const timeSinceLastKey = now - this.lastKeyPressTime;

      console.info(`${TAG}: Stack onClick, timeSinceLastKey=${timeSinceLastKey}ms, hasFocus=${this.remoteDesktopHasFocus}`);

      // If key was pressed recently (within 500ms), ignore this click
      // Increased from 200ms to 500ms to better handle Enter key
      if (timeSinceLastKey < 500) {
        console.info(`${TAG}: Ignoring click triggered by keyboard`);
        return;
      }

      // Only toggle toolbar if remote desktop doesn't have focus
      if (!this.remoteDesktopHasFocus) {
        this.toggleToolbar();
      }
    })
  }
}
