import SwiftUI

// MARK: - 使用示例

#if DEBUG
@available(iOS 17.0, macOS 14.0, *)
struct ToastKitExampleView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Group {
                        sectionHeader("基本 Toast 类型")
                        basicToastButtons
                    }
                    
                    Group {
                        sectionHeader("角色类型 Toast")
                        roleToastButtons
                    }
                    
                    Group {
                        sectionHeader("自定义配置")
                        customToastButtons
                    }
                }
                .padding()
            }
            .navigationTitle("ToastKit 示例")
        }
        .wsToast() // 添加 Toast 修饰器
    }
    
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var basicToastButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("成功") {
                    showToast(
                        title: "操作成功",
                        subtitle: "您的操作已完成",
                        type: .success
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("错误") {
                    showToast(
                        title: "操作失败",
                        subtitle: "请检查网络连接",
                        type: .error
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            HStack(spacing: 16) {
                Button("警告") {
                    showToast(
                        title: "注意",
                        subtitle: "存储空间不足",
                        type: .warning
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button("信息") {
                    showToast(
                        title: "提示",
                        subtitle: "新版本可用",
                        type: .info
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }
    
    @ViewBuilder
    private var roleToastButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("下载") {
                    showToast(
                        title: "下载完成",
                        subtitle: "文件已保存到下载文件夹",
                        type: .success,
                        role: .download
                    )
                }
                .buttonStyle(.bordered)
                
                Button("搜索") {
                    showToast(
                        title: "搜索完成",
                        subtitle: "找到 42 个结果",
                        type: .info,
                        role: .search
                    )
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 16) {
                Button("AirPods") {
                    showToast(
                        title: "AirPods 已连接",
                        subtitle: "电量 85%",
                        type: .success,
                        role: .airpods
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Apple Watch") {
                    showToast(
                        title: "Apple Watch 已配对",
                        subtitle: "正在同步数据...",
                        type: .info,
                        role: .appleWatch
                    )
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 16) {
                Button("打印机") {
                    showToast(
                        title: "打印任务已发送",
                        subtitle: "正在处理...",
                        type: .info,
                        role: .printer
                    )
                }
                .buttonStyle(.bordered)
                
                Button("HomePod") {
                    showToast(
                        title: "HomePod 已连接",
                        subtitle: "正在播放音乐",
                        type: .success,
                        role: .homePod
                    )
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    @ViewBuilder
    private var customToastButtons: some View {
        VStack(spacing: 12) {
            Button("无图标 Toast") {
                showToast(
                    title: "简洁通知",
                    subtitle: "这是一个无图标的 Toast",
                    type: .info,
                    showIcon: false
                )
            }
            .buttonStyle(.bordered)
            
            Button("长时间显示") {
                showToast(
                    title: "重要通知",
                    subtitle: "这个通知会显示 8 秒",
                    type: .warning,
                    duration: 8.0
                )
            }
            .buttonStyle(.bordered)
            
            Button("仅标题") {
                showToast(
                    title: "简短通知",
                    type: .success
                )
            }
            .buttonStyle(.bordered)
            
            Button("Safari 角色示例") {
                showToast(
                    title: "页面已加载",
                    subtitle: "www.apple.com",
                    type: .success,
                    role: .safari
                )
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - 集成示例

@available(iOS 17.0, macOS 14.0, *)
struct ToastIntegrationExampleView: View {
    @State private var isLoading = false
    @State private var items = ["项目 1", "项目 2", "项目 3"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button("删除") {
                                deleteItem(item)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    Button(isLoading ? "加载中..." : "模拟网络请求") {
                        simulateNetworkRequest()
                    }
                    .disabled(isLoading)
                    .buttonStyle(.borderedProminent)
                    
                    Button("添加新项目") {
                        addNewItem()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("集成示例")
        }
        .wsToast() // 添加 Toast 支持
    }
    
    private func deleteItem(_ item: String) {
        withAnimation {
            items.removeAll { $0 == item }
        }
        
        showToast(
            title: "项目已删除",
            subtitle: "\(item) 已从列表中移除",
            type: .success
        )
    }
    
    private func addNewItem() {
        let newItem = "项目 \(items.count + 1)"
        withAnimation {
            items.append(newItem)
        }
        
        showToast(
            title: "项目已添加",
            subtitle: "已添加 \(newItem)",
            type: .success
        )
    }
    
    private func simulateNetworkRequest() {
        isLoading = true
        
        showToast(
            title: "开始请求",
            subtitle: "正在连接服务器...",
            type: .info
        )
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            
            await MainActor.run {
                isLoading = false
                
                // 模拟成功或失败
                if Bool.random() {
                    showToast(
                        title: "请求成功",
                        subtitle: "数据已更新",
                        type: .success
                    )
                } else {
                    showToast(
                        title: "请求失败",
                        subtitle: "网络连接错误",
                        type: .error
                    )
                }
            }
        }
    }
}

// MARK: - 预览

@available(iOS 17.0, macOS 14.0, *)
#Preview {
    ToastKitExampleView()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("集成示例") {
    ToastIntegrationExampleView()
}
#endif 