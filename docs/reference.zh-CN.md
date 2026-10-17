# 配置与运行参考

[English](./reference.md) | [简体中文](./reference.zh-CN.md) · [README](../README.zh-CN.md)

## 配置

配置文件为 Tern 配置目录下的 `plugin-data/grid-layout/config.json`。macOS 默认配置目录为 `~/Library/Application Support/Tern`，自定义 `TERN_CONFIG_DIR` 优先。使用默认值时不需要创建文件。

| 字段 | 要求 | 默认值与含义 |
| --- | --- | --- |
| `min_width` | 文件存在时必填，正有限数 | 640 逻辑像素，用于选择列数的阈值。 |
| `executable` | 可选，非空字符串 | macOS 默认 `/Applications/Tern.app/Contents/MacOS/tern`，其他系统默认 `tern`。桌面启动 PATH 不同时建议填写绝对路径；其他系统未验证。 |
| `control` | 可选，非空字符串 | 默认不显式覆盖。默认路由查询到其他窗口时，指定目标窗口的控制端点。 |

显式指定 CLI 路径的例子：

```json
{
  "min_width": 640,
  "executable": "/Applications/Tern.app/Contents/MacOS/tern"
}
```

示例为标准安装位置；非标准安装需替换成实际 CLI 的绝对路径。JSON 值中的 shell 变量和 `~` 不会展开。配置读取上限为 16 KiB；JSON 或字段无效时暂停整理，主动执行命令会显示错误。

每次观察均读取配置。主动执行命令或调整窗口大小可应用布局设置，编辑文件本身不会请求整理。

### 布局规则

列数计算方式：

```text
max(1, min(pane_count, floor(available_stage_width / min_width)))
```

可用宽度不含侧栏。按照分屏树遍历顺序收集 pane，多余 pane 从左列开始分配。列宽相等，列内高度均分。窗口比 `min_width` 窄时仍使用一列，因此它并非 pane 尺寸的硬下限。没有最小高度限制，也不会将溢出 pane 自动移到新 tab。

首次自动观察只建立基线。整个窗口 viewport 的宽或高变化时，请求整理当前聚焦 tab。单 pane 或放大状态只更新自动基线，因此退出放大本身不会重放先前的 resize。修改分屏树、新增或关闭 pane、切换 tab、调整侧栏、编辑配置，本身均不请求整理。主动命令在可获得几何信息时整理；已有查询进行中时，保留手动请求，等当前操作结束后执行。

### 多窗口

插件查询 `tern ls --json`、`tern ctl state` 与 `dump .tn-stage`。原生 CLI JSON 保留 SDK 可能截断的完整 pane/tab ID。转发选定的 Tern 路由变量时，显式 daemon socket 优先于继承的 pane socket，否则可从 macOS 配置目录推导。以无损字符串 pane 选择器检查焦点，几何查询中的原生聚焦 ID 不匹配时拒绝操作；移动前再次核对原生 tab 与分屏树。焦点变化会取消剩余移动。

主动命令提示查询到其他窗口时，用 `tern --control <endpoint>` 启动目标窗口，`<endpoint>` 为你选择的本地控制端点，再将同一端点填入配置的 `control`，同时保留 `min_width`。不要向不受信任的用户暴露控制端点。插件不自动发现每个窗口的端点；多个窗口共用配置但使用不同端点时，需要明确设置路由。不要假定同一个共享 `control` 能分别指向所有窗口。

## 安装模式

在干净源码目录根部执行：

```sh
tern plugin install "$PWD" --json
```

这会把整个目录复制到 Tern 插件区域，不会实时关联 checkout。更新复制安装时，在新版源码目录执行 `tern plugin install "$PWD" --force`，卸载用 `tern plugin remove grid-layout`。

开发时使用 `tern plugin link "$PWD"` 链接源码，修改后用 `tern plugin reload` 重新加载。`tern plugin unlink grid-layout` 移除链接注册，不移除源码 checkout。Tern 不会覆盖已链接插件。由链接切换为复制安装时先 unlink 再 install；由复制切换为链接时先 remove 已安装副本再 link。切换前保留已知可用的归档和配置。

插件配置与源码 checkout 分开存放。卸载及配置清理由 Tern 管理；未核对宿主版本前，不应假定卸载会删除或保留所有宿主数据。

## 运行与排障

每 500ms 观察一次，每次最多启动三个短生命周期 CLI 进程，单 pane 和放大状态也会查询。整理前重新核对分屏树，再依次调用 `tern move`，最后执行当前窗口的 `equalize` 动作。每个 CLI 调用超时为 3 秒。观察到尺寸变化后至少稳定 200ms 才整理，实际还包含轮询、查询和 pane 移动时间。移动是顺序操作而非原子操作；中途失败或切换焦点可能留下部分整理的布局，解决故障后可重新执行命令。轮询周期不代表端到端延迟保证。

| 现象 | 检查方式 |
| --- | --- |
| 找不到命令 | 运行 `tern plugin list --json`，确认 `grid-layout` 状态为 `ready`；运行 `tern plugin reload`，在 Cmd+K 搜索 `Grid`。 |
| 自动布局似乎没有生效 | 主动执行命令查看错误，核对配置、CLI 路径和控制路由。仅加载插件或新增分屏，本就不会整理。 |
| 列数比预期少 | 比较扣除侧栏后的可用布局宽度与 `min_width`，编辑配置后主动执行命令。 |
| 自定义比例发生变化 | 窗口宽或高变化会按设计恢复均匀布局，插件没有撤销功能。 |
| `unknown tab … in session …`，或当前高 ID pane 执行命令无反应 | Tern 0.9.1 的 SDK 桥接仍会截断较大 ID。更新并 reload 本源码：通过 CLI 查询分屏树、以完整原生 ID 移动 pane，并用当前窗口动作均分。不需要重启 daemon 或给 ID 加掩码。 |
| 升级宿主后查询失效 | 完整验收记录基于 Tern 0.8.3；当前兼容 smoke 覆盖 0.9.1 的聚焦高 ID pane、主动整理及窗口 resize。开发控制接口格式可能变化，请保留已知可用的源码归档。 |

插件读取配置、选定的 Tern 环境变量、session/tab/pane 元数据与几何信息，整理已有 pane，不重启其程序。不发起网络请求、不发送遥测、不存储 pane 内容或日志。错误提示中的 CLI stderr 可能包含本地路径，分享前请脱敏。[安全说明](../SECURITY.md)记录程序与控制端点权限和报告渠道限制，[就绪证据](./readiness.md)记录实际验证范围。
