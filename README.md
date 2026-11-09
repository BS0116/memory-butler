<div align="center">

# Memory Butler · Game Mode / 内存管家 · 游戏模式

**Free up real memory for gaming on small-RAM Macs.**
**为小内存 Mac 游戏腾出真实可用内存的原生小工具。**

[English](#english) ｜ [简体中文](#简体中文)

<img src="docs/screenshot-zh.png" width="420" alt="中文界面"> <img src="docs/screenshot-en.png" width="420" alt="English UI">

</div>

---

<a name="简体中文"></a>

## 简体中文

一个住在菜单栏里的原生 macOS 工具（Swift 编写，**单文件、零依赖、纯系统 API**），
专为 **8GB 及以下内存的 Mac** 玩游戏设计：随时看清谁在吃内存，开游戏前一键把不需要的程序退掉，玩完一键恢复。

> 为什么它和市面上的"内存清理大师"不一样？
> macOS 会主动压缩、交换内存，"一键清理"大多是安慰剂。
> 真正有效的只有一件事：**把真正在吃内存的程序退掉**。这个工具就是干这个的。

### ✨ 功能

- 🟢🟠🔴 菜单栏实时显示可用内存，红/橙/绿三档提示内存压力
- 📋 面板按内存**从大到小**列出运行中的应用和后台服务（Chrome 的 Helper 子进程自动并入主程序，不重复计数）
- ✅ 智能预勾选：浏览器、微信/QQ、Docker、网盘同步、照片分析等"开游戏用不着"的程序
- 🚀 **一键腾内存**：退出勾选项，并报告"可用内存 X → Y，实际多出 Z"
- ↩️ **一键恢复**：玩完游戏把退掉的应用全部重新打开（记录会持久化，重启也不丢）
- 🌐 **内置中英双语**：菜单栏「语言 / Language」随时切换，无需重启
- 🔐 退出系统级后台服务时才需要管理员密码，普通应用完全不需要

### 📦 安装

1. 到 [Releases](../../releases) 下载最新的 `内存管家-x.x.dmg`
2. 打开 DMG，把 **内存管家** 拖进 **Applications**
3. 双击运行，看屏幕右上角菜单栏

> 首次运行提示"无法验证开发者"：在应用程序文件夹里 **右键 → 打开 → 打开** 即可（本地自编译软件没有苹果开发者证书，属正常现象）。

### 🎮 使用流程

```
打开面板 → 勾选要退出的程序 → 「一键腾内存」 → 开游戏
                                    ↓
          玩完 → 「恢复我退出的应用」 → 一切如初
```

### 🔨 从源码构建

```bash
git clone https://github.com/<你的用户名>/memory-butler.git
cd memory-butler
bash build.sh        # 需要 Xcode Command Line Tools（免费）：xcode-select --install
```

产物：`内存管家.app`（带图标、ad-hoc 签名）。命令行自检：`./内存管家.app/Contents/MacOS/GameMode --selftest`

### 💡 诚实的说明

- macOS 的"内存已用 90%"不一定是坏事 —— 系统会把不常用内存压缩起来。真正拖慢游戏的是 **Swap 交换**和**内存压力**，面板里都有显示。
- 「深度清理缓存」（purge）效果是瞬时的，系统很快会把文件缓存填回来，日常用不到。
- 退出应用用的是正常退出流程，有未保存的文档会先弹保存提示，不会丢数据。

### 📄 License

MIT

---

<a name="english"></a>

## English

A native macOS menu-bar utility (written in Swift — **one file, zero dependencies, system APIs only**)
built for **Macs with 8 GB of RAM or less**: see who is eating memory, quit the unneeded apps before you
launch a game, and bring everything back when you are done.

> Why is this different from "memory cleaner" apps?
> macOS compresses and swaps memory on its own, so one-click "cleaners" are mostly placebo.
> The only thing that actually helps is **quitting the apps that really hold memory**. That's exactly what this does.

### ✨ Features

- 🟢🟠🔴 Live free-memory readout in the menu bar with a 3-level pressure indicator
- 📋 Panel lists running apps and background services **largest first** (Chrome helpers are merged into the parent app, no double counting)
- ✅ Smart pre-selection: browsers, messengers, Docker, cloud-sync clients, photo analysis daemons
- 🚀 **Free Memory**: quits the checked items and reports "free memory X → Y, that's Z more"
- ↩️ **Reopen Closed Apps**: restores everything after gaming (the list survives restarts)
- 🌐 **Built-in English / 简体中文** switcher in the menu — no restart needed
- 🔐 Admin password is only ever needed for system-level background services

### 📦 Install

1. Grab the latest `内存管家-x.x.dmg` from [Releases](../../releases)
2. Open the DMG and drag **内存管家** into **Applications**
3. Launch it and look at the top-right of your menu bar

> If macOS says the app "can't be verified": right-click the app in /Applications → **Open** → Open again.
> This is normal for locally-built, unsigned apps.

### 🎮 Workflow

```
Open panel → check apps to quit → "Free Memory" → play
                                        ↓
        when done → "Reopen Closed Apps" → back to normal
```

### 🔨 Build from source

```bash
git clone https://github.com/<your-username>/memory-butler.git
cd memory-butler
bash build.sh        # requires free Xcode Command Line Tools: xcode-select --install
```

Output: `内存管家.app` (with icon, ad-hoc signed). Headless self-test: `./内存管家.app/Contents/MacOS/GameMode --selftest`

### 💡 Honest notes

- "90% memory used" on macOS is not necessarily bad — the system compresses inactive memory.
  What actually slows games down is **swap** and **memory pressure**; the panel shows both.
- "Deep Clean Cache" (purge) is momentary — the system refills the file cache quickly.
- Apps are quit through the normal quit flow; unsaved documents prompt first. No data loss.

### 📄 License

MIT
