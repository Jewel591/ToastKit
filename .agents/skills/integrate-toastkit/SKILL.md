---
name: integrate-toastkit
description: 在任何 Apple App 里实现、迁移或排查「toast / 瞬态提示 / 操作反馈横幅」能力时必须先加载：一律接 ToastKit（Jewel591/ToastKit），⛔ 不再手写 ToastViewModel / ToastView / 穿透窗口。覆盖标准接入姿势、CI lint（toast-kit-lint v1，条件闸）的装配证据、迁移时的删除清单与调用点改写映射。本 skill 是接入索引，范围裁决正文在本仓库 CLAUDE.md。
---

# ToastKit 接入 skill

（本文件是 skill 正身；各机器 `~/.agents/skills/integrate-toastkit/` 只放指向这里的壳。）

全线 Apple App 的瞬态反馈唯一正身是 **[Jewel591/ToastKit](https://github.com/Jewel591/ToastKit)**
（本地 checkout：`~/Documents/DevProjects/Swift Projects/ToastKit`）。
范围裁决与不变式读 kit 仓库 `CLAUDE.md`，用法读 `README.md`——本文件不复制正文。

## 何时触发

- 新项目要加「操作成功/失败提示」「已保存/已复制」这类瞬态反馈
- 存量项目里看到 vendored `ToastViewModel` / `ToastItem` / `ToastView` /
  `ToastWindowManager` 家族（MONO / CodeCat / Filmo 历史上各带一份）
- `toast-kit-lint` 红灯
- 排查 toast 被 sheet 遮挡 / 主题错色 / 堆叠不消失

## 硬性规则

1. ⛔ 不手写 toast。穿透窗口、堆叠、驱逐、自动消失、VoiceOver 播报全在 kit 内。
2. 接入 = lint 证据齐全（`toast-kit-lint` v1 条件闸，validation 起硬闸）：
   - canonical URL + `Up to Next Major Version`（`from:`）依赖声明
   - application target 生产源码 `import ToastKit`
   - scene 根安装 `.toastHost()`（测试 / Preview / DEBUG 不算）
   - ⛔ 生产代码里残留自研 toast 家族声明直接报红（与 kit 并存也报红）
3. 迁移存量项目时**删除** vendored 实现整个目录，调用点机械映射：
   - `ToastViewModel.shared.show(title:subtitle:type:duration:)`
     → `ToastCenter.shared.show(title:subtitle:style:duration:)`
   - `showSuccess / showError / showWarning / showInfo` 同名保留
   - `.withToast()` → `.toastHost()`
4. toast 不可交互是契约：需要用户决策的内容走 alert / sheet
   （经宿主 SheetCoordinator / SurfaceCoordinatorKit 仲裁），⛔ 不给 toast 加按钮。
5. 零配置是不变式：⛔ 不加主题 / 位置 / 动画 / 上限配置参数；
   逐调用点自由度只有 `duration`（默认 2s，长文案可加长）和 `showsIcon`
   （默认不画 icon）。
6. kit 内无用户可见字符串：文案由宿主传 `String` 或 `LocalizedStringResource`，
   本地化在宿主 catalog 完成；⛔ 不要给 kit 仓库"补" xcstrings / l10n-manifest。
