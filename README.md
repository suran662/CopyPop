# CopyPop 复制提示器

复制完成时，在鼠标附近轻轻提示一下。

![CopyPop 使用示意图](docs/usage.svg)

CopyPop 常驻菜单栏或任务栏通知区域。它只在剪贴板发生变化时读取一次内容类型，并短暂显示提示，不会打断当前操作。

## macOS 下载与使用

1. 打开仓库右侧的 **Releases**，进入最新发布。
2. 下载 `CopyPop-macOS-arm64.zip` 并解压。
3. 将 `CopyPop.app` 拖入“应用程序”文件夹。
4. 第一次启动时，右键点击 `CopyPop.app`，选择“打开”。
5. 看到菜单栏中的 CopyPop 图标后，复制任意文本、图片或文件即可。

发布包支持 Apple 芯片 Mac（M1、M2、M3、M4 及后续型号），需要 macOS 11 或更高版本。

## Windows 使用

Windows 版本已经包含在仓库中，需要在 Windows 电脑上构建一次：

1. 安装 Microsoft C++ Build Tools，并选择“使用 C++ 的桌面开发”。
2. 下载仓库源码并解压。
3. 右键 `scripts\首次运行-Windows.ps1`，选择“使用 PowerShell 运行”。
4. 看到任务栏通知区域中的 CopyPop 图标后即可使用。

生成的程序位于 `build\windows\CopyPop.exe`。

## 会显示什么

| 复制的内容 | 鼠标附近的提示 |
| --- | --- |
| 文本 | 显示一小段内容预览 |
| 图片 | 显示“已复制图片” |
| 单个文件 | 显示文件名 |
| 多个文件 | 显示文件数量 |

提示约 0.65 秒后自动消失。它不会抢走输入焦点，也不会挡住鼠标点击；靠近屏幕边缘时会自动换到鼠标另一侧。

## 退出 CopyPop

- macOS：点击菜单栏中的 CopyPop 图标，选择“退出 CopyPop”。
- Windows：右键任务栏通知区域中的 CopyPop 图标，选择“退出 CopyPop”。

## 隐私与轻量设计

- 所有判断都在本机完成，不联网。
- 不保存剪贴板历史。
- 不修改剪贴板内容。
- 文本只读取当次提示所需的短预览。
- macOS 和 Windows 使用各自的原生系统接口，没有内置浏览器运行环境。

## 自己构建

macOS 需要 Xcode Command Line Tools，然后运行：

```bash
scripts/构建-macOS.command
```

Windows 需要 Microsoft C++ Build Tools 或 MinGW-w64，然后在 PowerShell 中运行：

```powershell
.\scripts\构建-Windows.ps1
```

## 许可证

[MIT](LICENSE)
