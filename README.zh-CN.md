# CopyPop 复制提示器

<table>
  <tr>
    <td><a href="README.md">English</a></td>
    <td><strong>简体中文</strong></td>
  </tr>
</table>

> 复制完成时，在鼠标附近轻轻提示一下。

![CopyPop 使用示意图](docs/usage.svg)

CopyPop 是一个轻量的复制提示器。复制文本、图片或文件时，它会在鼠标附近显示一条短提示，程序常驻 Windows 任务栏通知区域或 macOS 菜单栏。

## Windows 下载与使用

1. 打开 [Windows 发布页面](https://github.com/suran662/CopyPop/releases/tag/v0.1.0)。
2. 在 **Assets** 中按界面语言选择：
   - 中文版：`CopyPop-Windows-x64-zh-CN.exe`
   - 英文版：`CopyPop-Windows-x64-en.exe`
3. 下载完成后，双击这个 `.exe` 文件。
4. 如果 Windows SmartScreen 弹出提示，点击**更多信息** → **仍要运行**。
5. 看到时钟旁边的 CopyPop 图标就表示已经运行。现在复制任意内容试试。

支持 64 位 Windows 10 和 Windows 11。
每个安装包的界面语言是固定的。

## macOS 下载与使用

1. 打开[最新发布页面](https://github.com/suran662/CopyPop/releases/latest)。
2. 在 **Assets** 中点击中文版 `CopyPop-macOS-arm64-zh-CN.zip`。
3. 双击 ZIP 解压，再把 `CopyPop.app` 拖进**应用程序**文件夹。
4. 第一次打开时，右键点击 `CopyPop.app`，选择**打开**。
5. 看到菜单栏中的 CopyPop 图标就表示已经运行。现在复制任意内容试试。

支持 Apple 芯片 Mac（M1、M2、M3、M4 及后续型号），需要 macOS 11 或更高版本。
每个安装包的语言是固定的；需要英文版时请选择文件名带 `en` 的安装包。

## 会显示什么

| 复制的内容 | 显示的提示 |
| --- | --- |
| 文本 | 一小段文字预览 |
| 图片 | “已复制图片” |
| 单个文件 | 文件名 |
| 多个文件 | 文件数量 |

提示约 0.65 秒后自动消失，不会抢走键盘焦点，也不会挡住鼠标点击。

## 退出或删除

- **Windows：**右键点击 CopyPop 托盘图标，选择**退出 CopyPop**。不想再用时，直接删除 `.exe` 文件即可。
- **macOS：**点击菜单栏中的 CopyPop 图标，选择**退出 CopyPop**。不想再用时，从**应用程序**文件夹删除它即可。

## 隐私

- 所有处理都在本机完成，不联网。
- 不保存剪贴板历史。
- 不修改剪贴板内容。

## 从源码构建

macOS 安装 Xcode Command Line Tools 后运行：

```bash
scripts/build-macos.command zh-CN
```

Windows 安装 Microsoft C++ Build Tools、MinGW-w64 或 LLVM-MinGW 后，在 PowerShell 中运行：

```powershell
.\scripts\build-windows.ps1 zh-CN
```

需要同时生成两个 macOS 发布包时，运行 `scripts/package-macos.command`。

## 许可证

[MIT](LICENSE)
