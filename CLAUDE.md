# CLAUDE.md — ToastKit

本仓库是全线 Apple App 的瞬态反馈（toast）正身。范围裁决与不变式记录在此；README 是使用文档。

## 不变式（改动前先读）

1. **零配置是产品决策，不是省事。** 视觉（capsule、系统语义色、无 icon）、位置
   （顶部，安全区下 8pt，对齐系统自身瞬态提示的位置；⛔ 不要恢复旧实现的 50pt 魔数）、
   动画（spring 0.5/0.8）、默认时长（2s）、同屏上限（3 条，最旧让位）全部写死在 kit。
   ⛔ 不给宿主加主题 / 位置 / 动画配置参数——每多一个参数就是每个项目多一个写错的机会。
   唯一的逐调用点自由度是 `duration`（有真实需求：CodeCat 的登录警告需要 10s 阅读时间）。
2. **toast 不可交互是契约**：iOS 承载窗口 `hitTest` 恒返回 nil，所有点击穿透给下层。
   需要用户决策的信息不属于 toast——⛔ 不接受给 toast 加按钮 / 手势 / 点击回调的 PR，
   那类需求走 alert / sheet（经宿主 SheetCoordinator / SurfaceCoordinatorKit 仲裁）。
3. **iOS 必须用独立穿透 UIWindow（`.alert + 1`），不能退回根视图 overlay**——
   overlay 会被任何 sheet / fullScreenCover 遮住（模态是独立于根视图之上的呈现层）。
   窗口按 `UIWindowScene` 维度管理（iPad 多窗口 / Stage Manager），scene 断开即释放。
   macOS 无此层级问题，保持 overlay。
4. **独立窗口必须镜像宿主的有效配色**（含 `preferredColorScheme` 手动覆盖）——
   独立窗口默认只跟系统，不同步会在 App 内手动切主题时错色。
   两处 `overrideUserInterfaceStyle` 赋值挂着 `theme-policy-exempt: force`，⛔ 不要删。
5. **kit 内无用户可见字符串**：文案全部由宿主传入（`String` 或
   `LocalizedStringResource`，后者在宿主 catalog 解析）。所以本仓库没有
   Localizable.xcstrings、没有 l10n-manifest——⛔ 不要"补齐"它们。
6. **发布 `[ToastItem]` 是安全的**（值类型 + 每次变更都改变数组值），
   不适用 house 的「⛔ 不直接发布 `[SomeModel]`」禁令——那条针对的是
   SwiftData model 的身份相等吞通知（#316）。但新增对外状态时仍要过一遍该判据。
7. **每个 toast 发 VoiceOver announcement**：toast 瞬态且不可交互，
   不播报 VoiceOver 用户会完全错过。
8. **scene 归属只在无歧义时判定**（恰好一个 foregroundActive scene 才 stamp）。
   iPad 多前台窗口下没有可靠的 App 级信号能反推「这次 show 来自哪个窗口」
   （key window 是 per-scene 的），⛔ 不要按 keyWindow / 首个匹配去猜——
   猜错是把反馈显示到错误窗口，fail-open（nil = 处处显示）最坏只是重复显示。
   同屏上限（3 条）是**逐屏不变量**：一块屏幕的可见集 = 本 scene 组 + nil 广播组，
   驱逐按新 toast 落到的每块屏幕的可见集执行——既不允许混组后单屏超过 3 条，
   也不允许一个 scene 的爆发驱逐另一个 scene 的反馈。
9. **`dismissAll()` 是进程级操作**（登出、账号切换等 App 级重置用），
   有意不做 per-scene 版本——需要时再加，⛔ 不要预防性实现。

## CI 契约

`product-playbook` 的 `toast-kit-lint` 以以下证据判定接入（条件闸：仓库出现
toast 痕迹才要求，toast 不是每个 App 的必备能力）：

- canonical 依赖 `https://github.com/Jewel591/ToastKit` + 自动兼容版本范围（`from:`）
- application target 生产源码 `import ToastKit`
- 生产源码安装 `.toastHost()`
- ⛔ 生产源码自建 toast 实现（`ToastViewModel` / 自研 `ToastItem` 等）直接报红

改公开 API 名（`ToastCenter` / `toastHost`）必须同步改 lint，否则全线红灯。
