# Tern Grid Layout

[English](./README.md) | [简体中文](./README.zh-CN.md)

[安装](#安装) · [快速开始](#快速开始) · [配置](#配置) · [参考文档](./docs/reference.zh-CN.md)

在 Tern 窗口 resize 或主动执行命令时，将当前 tab 的 pane 整理为等宽列，让多分屏保持可读。两次窗口 resize 之间，保留你手动设置的分隔比例。

**Cmd+K → Grid → Grid Layout: Arrange Responsive Panes**  
快捷键：**Control + Option + Shift + G**。

当前为 **0.5.0 实验性插件**，已验证 **macOS / Tern 0.8.3**。以本地源码分发，尚未配置托管仓库或发行版。

## 布局方式

连续分屏可能让某个 pane 越来越小。Grid Layout 根据当前 tab 的可用宽度选择列数，再把 pane 分配到各列。列宽相等，列内高度均分，pane 中运行的程序保持运行。

只有**窗口宽度或高度变化**会请求自动整理。加载插件、新增或关闭 pane、切换 tab、调整分隔线或侧栏，本身均不触发。只整理当前聚焦 tab；单 pane 或放大状态下仅更新尺寸基线，不自动整理。

## 安装

需要 Tern 桌面应用和可用的 CLI。先在终端运行：

```sh
tern --version
```

已验证的宿主为 **Tern 0.8.3**。macOS 默认调用标准安装位置中的 `/Applications/Tern.app/Contents/MacOS/tern`；安装在其他位置时，按[完整配置参考](./docs/reference.zh-CN.md#配置)设置 `executable`。其他平台和宿主版本未验证。运行插件不需要 Node.js 或 npm。

取得源码目录或解压源码归档，在**包含 `plugin.toml` 的根目录**打开终端，执行：

```sh
tern plugin install "$PWD" --json
tern plugin list --json
```

确认列表中的 ID 为 `grid-layout`、版本为 `0.5.0`、状态为 `ready`，且没有插件问题。标准 macOS 安装无需配置即可使用。Tern 会复制整个目录，建议使用不含开发依赖的干净源码归档；开发者可按[贡献指南链接 checkout](./CONTRIBUTING.md#local-checks)。

## 快速开始

1. 在临时 Tern tab 中向右分屏两次，得到三个 pane。
2. 按 **Control + Option + Shift + G**，或按 **Cmd+K** 搜索 **Grid**，执行 **Grid Layout: Arrange Responsive Panes**。
3. 确认结果：pane 排成等宽列；窗口较窄时，部分 pane 会在列内均分高度。默认配置下，tab 的可用布局区域至少 1920 逻辑像素宽时，三个 pane 可排成三列；侧栏占用不计入可用宽度。
4. 拖动分隔线设置自定义比例。经过多次轮询后它仍会保持；调整窗口大小或再次执行命令，才恢复均匀布局。

插件每 500ms 观察窗口尺寸，在观察到变化后至少等待 200ms 再整理，实际延迟还包含查询耗时。插件没有撤销功能，第一次使用请在临时 tab 中操作。

## 配置

希望较窄窗口容纳更多列时，可以降低选列宽度阈值，例如改为 540 逻辑像素：

```json
{
  "min_width": 540
}
```

将文件保存到 Tern 配置目录下的 `plugin-data/grid-layout/config.json`。macOS 默认配置目录为 `~/Library/Application Support/Tern`，自定义 `TERN_CONFIG_DIR` 优先。没有配置文件时，阈值默认 **640**。

主动执行命令可立即应用，也可等待下次窗口 resize。编辑配置本身不会请求整理。[完整配置与布局规则](./docs/reference.zh-CN.md#配置)包含有效值、非标准 CLI 路径和多窗口路由设置。

## 更新与卸载

在新版源码归档解压后的根目录，更新复制安装：

```sh
tern plugin install "$PWD" --force
```

复制安装用 `tern plugin remove grid-layout` 卸载。链接 checkout 用 `tern plugin reload` 加载更新，用 `tern plugin unlink grid-layout` 解除链接。Tern 不会覆盖已链接插件；切换方式见[安装模式](./docs/reference.zh-CN.md#安装模式)。

## 限制与信任

插件依赖 Tern 开发控制接口，宿主升级可能影响兼容性。每次观察最多启动两个短生命周期 CLI 进程，单 pane 和放大状态也会查询；多窗口可能需要显式控制端点。自动查询失败静默，主动执行命令可查看错误。详见[运行与排障](./docs/reference.zh-CN.md#运行与排障)。

插件读取自身配置、选定的 Tern 环境变量与窗口/pane 几何信息，并调用指定 CLI。不发起网络请求、不发送遥测、不存储 pane 内容或诊断日志。配置的程序和控制端点属于需要信任的本地执行权限。[安全说明](./SECURITY.md)包含详细边界及当前报告渠道限制。

## 参与贡献

[贡献指南](./CONTRIBUTING.md)提供开发检查、原生 smoke 与版本策略。[变更记录](./CHANGELOG.md)记录演进；[就绪证据](./docs/readiness.md)区分已验证的本地能力与公开发布前的剩余事项。

采用 [MIT 许可证](./LICENSE)。
