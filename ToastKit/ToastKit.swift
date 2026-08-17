//
//  ToastKit.swift
//  ToastKit
//
//  Created by Ivens Liao on 2025/5/30.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Toast 数据模型

public struct WSToast: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let image: String?
    public let type: WSToastType
    public let role: WSToastRole?
    public let showIcon: Bool
    public let duration: TimeInterval

    public init(
        title: String,
        subtitle: String? = nil,
        image: String? = nil,
        type: WSToastType = .success,
        role: WSToastRole? = nil,
        showIcon: Bool = true,
        duration: TimeInterval = 2.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.type = type
        self.role = role
        self.showIcon = showIcon
        self.duration = duration
    }

    public static func == (lhs: WSToast, rhs: WSToast) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle && lhs.image == rhs.image
            && lhs.type == rhs.type && lhs.role == rhs.role
    }
}

// MARK: - Toast 角色枚举

public enum WSToastRole: Equatable {
    case download, search, airpods, appleWatch, printer, homePod, bad, appleTv,
        airPodMax, safari

    /// 获取角色对应的默认图标名称
    public var iconName: String {
        switch self {
        case .download: return "arrow.down.circle.fill"
        case .search: return "magnifyingglass"
        case .airpods: return "airpods"
        case .appleWatch: return "applewatch"
        case .printer: return "printer"
        case .homePod: return "homepod"
        case .bad: return "xmark.circle"
        case .appleTv: return "appletv"
        case .airPodMax: return "airpods.max"
        case .safari: return "safari.fill"
        }
    }
}

// MARK: - Toast 类型枚举

public enum WSToastType: Equatable {
    case success, error, warning, info

    /// 获取类型对应的默认图标名称
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle"
        case .error: return "exclamationmark.circle"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle"
        }
    }

    /// 获取类型对应的图标颜色
    public var iconColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Toast 管理器

@Observable
public final class WSToastManager {
    // 单例实例
    public static let shared = WSToastManager()

    @MainActor public var toast: WSToast?

    // 私有初始化方法确保只有一个实例
    private init() {}

    @MainActor
    public func show(
        title: String,
        subtitle: String? = nil,
        type: WSToastType = .success,
        role: WSToastRole? = nil,
        showIcon: Bool = true,
        duration: TimeInterval = 3.0
    ) {
        // 使用动画显示 toast
        withAnimation(.spring) {
            toast = WSToast(
                title: title,
                subtitle: subtitle,
                image: nil,
                type: type,
                role: role,
                showIcon: showIcon,
                duration: duration
            )
        }

        Task {
            try? await Task.sleep(for: .seconds(duration))
            withAnimation {
                toast = nil
            }
        }
    }
}

// MARK: - Toast 视图

public struct WSToastView: View {
    @Environment(\.colorScheme) var colorScheme
    let toast: WSToast

    public init(toast: WSToast) {
        self.toast = toast
    }

    public var body: some View {
        HStack(spacing: 16) {
            if toast.showIcon {
                if let image = toast.image {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    // .foregroundColor(toast.type.iconColor)
                } else if let role = toast.role {
                    Image(systemName: role.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    // .foregroundColor(role.iconColor)
                } else {
                    Image(systemName: toast.type.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    // .foregroundColor(toast.type.iconColor)
                }
            }

            VStack(alignment: .center) {
                Text(toast.title)
                    .lineLimit(1)
                    .font(.headline)

                if let subtitle = toast.subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(toast.showIcon ? .trailing : .horizontal)
        }
        .padding(.horizontal)
        .frame(height: 56)
        .background(
            colorScheme == .dark
                ? Color(red: 0.12, green: 0.12, blue: 0.12)  // 暗色模式背景色
                : Color(red: 0.96, green: 0.96, blue: 0.96)  // 亮色模式背景色
        )
        .cornerRadius(28)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Toast 修饰器

public struct WSToastModifier: ViewModifier {
    // 直接使用单例
    @State private var toastManager = WSToastManager.shared

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                WSToastContainerView()
            }
    }
}

// MARK: - Toast 容器视图

private struct WSToastContainerView: View {
    var body: some View {
        Group {
            if let toast = WSToastManager.shared.toast {
                WSToastView(toast: toast)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - View 扩展

extension View {
    public func wsToast() -> some View {
        self.modifier(WSToastModifier())
    }
}

// MARK: - 全局函数

/// 显示 Toast 通知
/// - Parameters:
///   - title: 标题
///   - subtitle: 副标题
///   - type: Toast 类型
///   - role: Toast 角色
///   - showIcon: 是否显示图标
///   - duration: 显示时长
public func showToast(
    title: String,
    subtitle: String? = nil,
    type: WSToastType = .success,
    role: WSToastRole? = nil,
    showIcon: Bool = false,
    duration: TimeInterval = 3.0
) {
    // 创建异步任务在主线程上执行
    Task { @MainActor in
        WSToastManager.shared.show(
            title: title,
            subtitle: subtitle,
            type: type,
            role: role,
            showIcon: showIcon,
            duration: duration
        )
    }
}
