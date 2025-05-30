# ToastKit

一个现代化的 SwiftUI Toast 通知框架，提供美观的消息提示体验。

## 功能特性

- ✅ **多种通知类型**：成功、错误、警告、信息
- ✅ **丰富的角色类型**：下载、搜索、设备连接等预设角色
- ✅ **自定义配置**：可配置图标、持续时间、样式等
- ✅ **优雅动画**：流畅的进入和退出动画
- ✅ **暗色模式支持**：自动适配系统外观
- ✅ **SwiftUI 原生**：完全基于 SwiftUI 和 Observation 框架构建

## 系统要求

- iOS 17.0+
- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## 快速开始

### 1. 添加修饰器

在你的根视图上添加 `.wsToast()` 修饰器：

```swift
import ToastKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            // 你的视图内容
            Text("Hello, World!")
        }
        .wsToast() // 添加 Toast 支持
    }
}
```

### 2. 显示 Toast

使用全局函数 `showToast()` 来显示通知：

```swift
// 基本用法
showToast(
    title: "操作成功",
    subtitle: "您的操作已完成",
    type: .success
)

// 带角色的 Toast
showToast(
    title: "下载完成",
    subtitle: "文件已保存到下载文件夹",
    type: .success,
    role: .download
)

// 自定义配置
showToast(
    title: "重要通知",
    subtitle: "这个通知会显示 8 秒",
    type: .warning,
    showIcon: true,
    duration: 8.0
)
```

## API 文档

### WSToastType

通知类型枚举：

```swift
public enum WSToastType {
    case success  // 成功 - 绿色
    case error    // 错误 - 红色  
    case warning  // 警告 - 橙色
    case info     // 信息 - 蓝色
}
```

### WSToastRole

角色类型枚举，提供预设的图标和语义：

```swift
public enum WSToastRole {
    case download     // 下载
    case search       // 搜索
    case airpods      // AirPods
    case appleWatch   // Apple Watch
    case printer      // 打印机
    case homePod      // HomePod
    case bad          // 错误状态
    case appleTv      // Apple TV
    case airPodMax    // AirPods Max
    case safari       // Safari
}
```

### showToast 函数

```swift
public func showToast(
    title: String,
    subtitle: String? = nil,
    type: WSToastType = .success,
    role: WSToastRole? = nil,
    showIcon: Bool = true,
    duration: TimeInterval = 3.0
)
```

**参数说明：**
- `title`: 主标题（必需）
- `subtitle`: 副标题（可选）
- `type`: Toast 类型，影响图标和颜色
- `role`: 角色类型，提供特定场景的图标
- `showIcon`: 是否显示图标
- `duration`: 显示持续时间（秒）

## 使用示例

### 基本通知类型

```swift
// 成功通知
showToast(
    title: "保存成功",
    subtitle: "数据已保存",
    type: .success
)

// 错误通知
showToast(
    title: "操作失败",
    subtitle: "网络连接错误",
    type: .error
)

// 警告通知
showToast(
    title: "存储空间不足",
    subtitle: "请清理设备存储",
    type: .warning
)

// 信息通知
showToast(
    title: "新版本可用",
    subtitle: "点击更新到最新版本",
    type: .info
)
```

### 设备和服务相关

```swift
// 设备连接
showToast(
    title: "AirPods 已连接",
    subtitle: "电量 85%",
    type: .success,
    role: .airpods
)

// 下载完成
showToast(
    title: "下载完成",
    subtitle: "movie.mp4 已保存",
    type: .success,
    role: .download
)

// 打印任务
showToast(
    title: "打印任务已发送",
    subtitle: "正在处理中...",
    type: .info,
    role: .printer
)
```

### 在业务逻辑中使用

```swift
struct DataManager {
    func saveData() async {
        do {
            try await performSave()
            showToast(
                title: "保存成功",
                subtitle: "数据已同步到云端",
                type: .success
            )
        } catch {
            showToast(
                title: "保存失败",
                subtitle: error.localizedDescription,
                type: .error
            )
        }
    }
    
    func downloadFile() async {
        showToast(
            title: "开始下载",
            subtitle: "正在连接服务器...",
            type: .info,
            role: .download
        )
        
        // 下载逻辑...
        
        showToast(
            title: "下载完成",
            subtitle: "文件已保存到下载文件夹",
            type: .success,
            role: .download
        )
    }
}
```

### 表单验证

```swift
struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField("用户名", text: $username)
            SecureField("密码", text: $password)
            
            Button("登录") {
                login()
            }
        }
        .wsToast()
    }
    
    private func login() {
        if username.isEmpty {
            showToast(
                title: "用户名不能为空",
                type: .warning
            )
            return
        }
        
        if password.isEmpty {
            showToast(
                title: "密码不能为空",
                type: .warning
            )
            return
        }
        
        // 执行登录...
        showToast(
            title: "登录成功",
            subtitle: "欢迎回来！",
            type: .success
        )
    }
}
```

## 设计特性

### 视觉设计
- **现代圆角设计**：28px 圆角，符合现代 UI 设计趋势
- **适配暗色模式**：自动根据系统外观切换背景色
- **微妙阴影效果**：提供层次感和深度
- **一致的间距**：16px 内边距，56px 固定高度

### 动画效果
- **流畅进入动画**：从顶部滑入配合透明度变化
- **Spring 动画**：使用 SwiftUI 的 spring 动画提供自然的感觉
- **自动消失**：根据设定的持续时间自动消失

### 响应式布局
- **灵活图标系统**：支持 SF Symbols，28x28 标准尺寸
- **文字自适应**：标题和副标题自动适配内容长度
- **居中对齐**：保证在不同屏幕尺寸下的视觉平衡

## 最佳实践

1. **及时反馈**：在用户操作后立即显示相应的 Toast
2. **信息简洁**：保持标题简短有力，副标题提供必要的详细信息
3. **类型一致**：在整个应用中保持相同类型操作使用相同的 Toast 类型
4. **时长适中**：成功和信息类 Toast 使用默认 3 秒，错误类可以适当延长
5. **避免过度使用**：不要为每个微小操作都显示 Toast

## 许可证

MIT License

## 贡献

欢迎提交 Issues 和 Pull Requests！ 