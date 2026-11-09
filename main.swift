// Memory Butler · Game Mode  /  内存管家 · 游戏模式
// A native macOS menu-bar utility for small-RAM Macs:
// see who is eating memory, free it before gaming, restore everything afterwards.
// Single file, no dependencies — AppKit + Mach + libproc only.

import Cocoa
import Darwin

// MARK: - Localization

enum Lang: String {
    case zh = "zh"
    case en = "en"
}

var gLang: Lang = {
    if let saved = UserDefaults.standard.string(forKey: "lang"), let l = Lang(rawValue: saved) {
        return l
    }
    // 未本地化的二进制会让 Locale.preferredLanguages 回落成 en，所以读全局 AppleLanguages；
    // 只要系统语言列表里出现中文就用中文（比只看第一顺位更符合中文用户预期）
    let langs = UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages
    return langs.contains { $0.lowercased().hasPrefix("zh") } ? .zh : .en
}()

let kStrings: [Lang: [String: String]] = [
    .zh: [
        "panel.title": "Memory Butler · 内存管家",
        "panel.used": "已用 %@ / %@　可用 %@",
        "panel.detail": "App %@　压缩 %@　缓存 %@　Swap %@",
        "section.apps": "正在运行的应用",
        "section.appsHint": "按内存从大到小，勾选要退出的应用",
        "section.daemons": "后台服务",
        "section.daemonsHint": "没有窗口但一直在吃内存的常驻服务",
        "btn.boost": "退出勾选的应用",
        "btn.restore": "恢复我退出的应用",
        "btn.purge": "清理缓存",
        "btn.refresh": "刷新列表",
        "btn.selectRec": "全选推荐项",
        "empty.apps": "没有可退出的应用。",
        "empty.daemons": "当前没有可清理的后台服务。",
        "item.app": "应用",
        "banner.red": "内存非常紧张，Swap 已经在拖慢速度 —— 先退掉上面的大户再开游戏。",
        "banner.orange": "内存偏紧。开游戏前建议腾一下，否则容易掉帧。",
        "banner.green": "内存状态良好，可以直接开游戏。",
        "banner.noneSelected": "还没有勾选任何项目，先勾几项再点。",
        "banner.refreshed": "列表已刷新。",
        "banner.boostRunning": "正在退出 %d 个进程，预计腾出 %@…",
        "banner.boostDone": "完成。可用 %@ → %@，实际多出 %@。",
        "banner.adminNeeded": "部分后台服务属于系统进程，需要管理员密码…",
        "banner.noRecords": "还没有记录到被退出的应用。",
        "banner.restored": "已重新打开 %d 个应用。",
        "banner.purgeDone": "缓存已清理，当前可用 %@。",
        "banner.purgeFail": "清理缓存需要管理员密码，已取消。",
        "menu.open": "打开面板…",
        "menu.quick": "快速退出推荐项",
        "menu.purge": "清理缓存（需输入密码）",
        "menu.lang": "语言 / Language",
        "menu.quit": "退出内存管家",
        "menu.status": "可用 %@ ｜ 压缩 %@ ｜ Swap %@",
        "quick.none": "没有需要退出的推荐项",
        "quick.done": "已退出推荐项，约腾出 %@",
        "quick.info": "需要的话可以在面板里点「恢复我退出的应用」。",
        "alert.purgeOk": "缓存已清理",
        "alert.purgeOkBody": "当前可用 %@。注意：系统会重新把文件缓存填回来，这一步只让瞬时可用内存变多，长期收益有限。",
        "alert.purgeFail": "清理被取消或失败",
        "alert.purgeFailBody": "需要在系统弹窗里输入管理员密码才能执行。",
        "welcome.title": "内存管家已就绪",
        "welcome.body": "屏幕右上角菜单栏有一个显示剩余内存的小图标，点它能打开面板。\n\n用法：勾选要退出的应用 → 点「退出勾选的应用」→ 开游戏 → 玩完点「恢复我退出的应用」。\n「清理缓存」按钮可以清文件缓存，但长期收益有限。",
        "btn.ok": "好",
        "btn.gotit": "知道了"
    ],
    .en: [
        "panel.title": "Memory Butler · Game Mode",
        "panel.used": "Used %@ of %@　%@ free",
        "panel.detail": "App %@　Compressed %@　Cached %@　Swap %@",
        "section.apps": "Running Apps",
        "section.appsHint": "Largest first — check the apps you want to quit",
        "section.daemons": "Background Services",
        "section.daemonsHint": "Windowless helpers that keep eating memory",
        "btn.boost": "Quit Checked Apps",
        "btn.restore": "Reopen Closed Apps",
        "btn.purge": "Clear Cache",
        "btn.refresh": "Refresh",
        "btn.selectRec": "Select Recommended",
        "empty.apps": "No apps to quit.",
        "empty.daemons": "No background services to clean.",
        "item.app": "App",
        "banner.red": "Memory is critically low and swap is slowing everything down. Quit the heavy apps above before gaming.",
        "banner.orange": "Memory is tight. Free some up before gaming to avoid stutter.",
        "banner.green": "Memory looks healthy — you are good to play.",
        "banner.noneSelected": "Nothing is checked yet — pick a few items first.",
        "banner.refreshed": "List refreshed.",
        "banner.boostRunning": "Quitting %d processes, about %@ expected…",
        "banner.boostDone": "Done. Free memory %@ → %@, that's %@ more.",
        "banner.adminNeeded": "Some services run as system processes — admin password required…",
        "banner.noRecords": "No closed apps recorded yet.",
        "banner.restored": "Reopened %d apps.",
        "banner.purgeDone": "Cache cleared — now %@ free.",
        "banner.purgeFail": "Clearing cache needs an admin password — cancelled.",
        "menu.open": "Open Panel…",
        "menu.quick": "Quick Quit Recommended",
        "menu.purge": "Clear Cache (needs password)",
        "menu.lang": "语言 / Language",
        "menu.quit": "Quit Memory Butler",
        "menu.status": "Free %@ ｜ Compressed %@ ｜ Swap %@",
        "quick.none": "Nothing to quit",
        "quick.done": "Quit recommended items, freed about %@",
        "quick.info": "Use “Reopen Closed Apps” in the panel to bring them back.",
        "alert.purgeOk": "Cache cleared",
        "alert.purgeOkBody": "Now %@ free. Note: macOS refills the file cache quickly, so this only helps for a short while.",
        "alert.purgeFail": "Cancelled or failed",
        "alert.purgeFailBody": "An admin password is required in the system dialog.",
        "welcome.title": "Memory Butler is ready",
        "welcome.body": "A small icon in the menu bar (top-right) shows how much memory is free — click it to open the panel.\n\nHow to use: check the apps to quit → “Quit Checked Apps” → play → “Reopen Closed Apps” when done.\n“Clear Cache” flushes the file cache, but its benefit is short-lived.",
        "btn.ok": "OK",
        "btn.gotit": "Got it"
    ]
]

func t(_ key: String) -> String {
    if let v = kStrings[gLang]?[key] { return v }
    return kStrings[.en]?[key] ?? key
}

// MARK: - Basic config

let kBundleID = "com.bs0116.gamemode"
let kNeverQuit: Set<String> = [
    "com.apple.finder", "com.apple.dock", "com.apple.loginwindow",
    "com.apple.systemuiserver", "com.apple.WindowManager",
    "com.apple.controlcenter", "com.apple.notificationcenterui",
    kBundleID
]
let kNeverQuitNames: Set<String> = [
    "WindowServer", "kernel_task", "launchd", "loginwindow", "Dock", "Finder",
    "coreaudiod", "bluetoothd", "logind", "opendirectoryd", "configd",
    "syslogd", "powerd", "watchdogd", "GameMode", "内存管家"
]

/// Apps that are usually safe to quit before gaming
let kHeavyApps: Set<String> = [
    "com.google.Chrome", "com.google.Chrome.canary", "com.microsoft.edgemac",
    "com.brave.Browser", "company.thebrowser.Browser", "org.mozilla.firefox",
    "com.tinyspeck.slackmacgap", "com.microsoft.teams2", "com.microsoft.teams",
    "com.docker.docker", "com.apple.dt.Xcode", "com.microsoft.VSCode",
    "com.todesktop.230313mzl4w4u92", "com.adobe.Photoshop",
    "com.adobe.PremierePro.24", "com.adobe.illustrator", "notion.id",
    "md.obsidian", "com.tencent.xinWeChat", "com.tencent.qq",
    "com.alibaba.DingTalkMac", "com.bytedance.macos.feishu"
]

// MARK: - Memory sampling (same math as Activity Monitor)

struct MemSample {
    var total: UInt64 = 0
    var appMemory: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0
    var cached: UInt64 = 0
    var free: UInt64 = 0
    var swapUsed: UInt64 = 0
    var swapTotal: UInt64 = 0

    /// App + wired + compressed, matching Activity Monitor's "Memory Used"
    var used: UInt64 { appMemory + wired + compressed }
    var available: UInt64 { total > used ? total - used : 0 }
    var usedRatio: Double { total == 0 ? 0 : Double(used) / Double(total) }
    var pressure: Double {
        let swapPart = swapTotal == 0 ? 0 : min(1.0, Double(swapUsed) / Double(swapTotal))
        let compPart = total == 0 ? 0 : min(1.0, Double(compressed) / Double(total))
        return min(1.0, usedRatio * 0.6 + compPart * 0.15 + swapPart * 0.25)
    }
}

func gb(_ bytes: UInt64) -> String {
    String(format: "%.2f GB", Double(bytes) / 1_073_741_824.0)
}
func mb(_ bytes: UInt64) -> String {
    let v = Double(bytes) / 1_048_576.0
    return v >= 1024 ? String(format: "%.2f GB", v / 1024.0) : String(format: "%.0f MB", v)
}

func readMemory() -> MemSample {
    var s = MemSample()
    s.total = ProcessInfo.processInfo.physicalMemory

    var pageSize: vm_size_t = 0
    host_page_size(mach_host_self(), &pageSize)
    let ps = UInt64(pageSize)

    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    let kr = withUnsafeMutablePointer(to: &stats) { p -> kern_return_t in
        p.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ip in
            host_statistics64(mach_host_self(), HOST_VM_INFO64, ip, &count)
        }
    }
    if kr == KERN_SUCCESS {
        s.free = (UInt64(stats.free_count) + UInt64(stats.speculative_count)) * ps
        s.wired = UInt64(stats.wire_count) * ps
        s.compressed = UInt64(stats.compressor_page_count) * ps
        let purgeable = UInt64(stats.purgeable_count) * ps
        let internalPages = UInt64(stats.internal_page_count) * ps
        let externalPages = UInt64(stats.external_page_count) * ps
        s.appMemory = internalPages > purgeable ? internalPages - purgeable : 0
        s.cached = externalPages + purgeable
    }

    var swap = xsw_usage()
    var sz = MemoryLayout<xsw_usage>.size
    var mib: [Int32] = [CTL_VM, VM_SWAPUSAGE]
    if sysctl(&mib, 2, &swap, &sz, nil, 0) == 0 {
        s.swapUsed = swap.xsu_used
        s.swapTotal = swap.xsu_total
    }
    return s
}

// MARK: - Process scanning

struct ProcEntry {
    let pid: pid_t
    let path: String
    let name: String
    let memory: UInt64
}

func processPath(_ pid: pid_t) -> String {
    var buf = [UInt8](repeating: 0, count: 4096)
    let r = proc_pidpath(pid, &buf, UInt32(buf.count))
    guard r > 0 else { return "" }
    return String(cString: buf)
}

func processFootprint(_ pid: pid_t) -> UInt64 {
    var info = rusage_info_current()
    let r = withUnsafeMutablePointer(to: &info) { p -> Int32 in
        p.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { rp in
            proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, rp)
        }
    }
    return r == 0 ? UInt64(info.ri_phys_footprint) : 0
}

/// Root-owned processes expose no footprint via libproc, so fall back to ps
func psSnapshot() -> (rss: [pid_t: UInt64], comm: [pid_t: String]) {
    var rss: [pid_t: UInt64] = [:]
    var comm: [pid_t: String] = [:]
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/ps")
    task.arguments = ["-axo", "pid=,rss=,comm="]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do { try task.run() } catch { return (rss, comm) }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard let text = String(data: data, encoding: .utf8) else { return (rss, comm) }
    for line in text.split(separator: "\n") {
        let trimmed = line.drop { $0 == " " }
        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2, let pid = pid_t(parts[0]), let kb = UInt64(parts[1]) else { continue }
        rss[pid] = kb * 1024
        if parts.count == 3 { comm[pid] = String(parts[2]) }
    }
    return (rss, comm)
}

func scanAllProcesses() -> [ProcEntry] {
    var pidBuf = [pid_t](repeating: 0, count: 8192)
    let bytes = proc_listallpids(&pidBuf, Int32(pidBuf.count * MemoryLayout<pid_t>.size))
    let n = max(0, Int(bytes) / MemoryLayout<pid_t>.size)
    let ps = psSnapshot()

    var out: [ProcEntry] = []
    out.reserveCapacity(n)
    for i in 0..<n {
        let pid = pidBuf[i]
        if pid <= 0 { continue }
        var mem = processFootprint(pid)
        var path = processPath(pid)
        var name = (path as NSString).lastPathComponent
        if mem == 0 { mem = ps.rss[pid] ?? 0 }
        if path.isEmpty {
            path = ps.comm[pid] ?? ""
            name = (path as NSString).lastPathComponent
        }
        if mem == 0 || name.isEmpty { continue }
        out.append(ProcEntry(pid: pid, path: path, name: name, memory: mem))
    }
    return out
}

// MARK: - Cleanable items

enum ItemKind { case app, daemon }

struct DaemonDef {
    let exe: String
    let zhTitle: String
    let zhNote: String
    let enTitle: String
    let enNote: String
    let onByDefault: Bool

    var title: String { gLang == .zh ? zhTitle : enTitle }
    var note: String { gLang == .zh ? zhNote : enNote }
}

let kDaemonDefs: [DaemonDef] = [
    DaemonDef(exe: "photoanalysisd",
              zhTitle: "照片分析", zhNote: "后台识别人脸/场景，可退出",
              enTitle: "Photos Analysis", enNote: "Scans faces and scenes in background",
              onByDefault: true),
    DaemonDef(exe: "mediaanalysisd",
              zhTitle: "媒体分析", zhNote: "后台分析照片视频，可退出",
              enTitle: "Media Analysis", enNote: "Analyzes photos and videos in background",
              onByDefault: true),
    DaemonDef(exe: "backupd",
              zhTitle: "Time Machine 备份", zhNote: "时光机正在备份，吃内存和磁盘",
              enTitle: "Time Machine Backup", enNote: "Backup in progress — heavy on RAM and disk",
              onByDefault: true),
    DaemonDef(exe: "bird",
              zhTitle: "iCloud 云盘同步", zhNote: "文件同步，会自己恢复",
              enTitle: "iCloud Drive Sync", enNote: "File sync, restarts by itself",
              onByDefault: true),
    DaemonDef(exe: "cloudd",
              zhTitle: "iCloud 同步后台", zhNote: "云同步守护，会自己恢复",
              enTitle: "iCloud Sync Daemon", enNote: "Cloud sync daemon, restarts by itself",
              onByDefault: true),
    DaemonDef(exe: "Dropbox",
              zhTitle: "Dropbox 同步", zhNote: "网盘同步",
              enTitle: "Dropbox Sync", enNote: "Cloud storage sync",
              onByDefault: true),
    DaemonDef(exe: "OneDrive",
              zhTitle: "OneDrive 同步", zhNote: "网盘同步",
              enTitle: "OneDrive Sync", enNote: "Cloud storage sync",
              onByDefault: true),
    DaemonDef(exe: "BaiduNetdisk",
              zhTitle: "百度网盘", zhNote: "网盘同步",
              enTitle: "Baidu Netdisk", enNote: "Cloud storage sync",
              onByDefault: true),
    DaemonDef(exe: "aDrive",
              zhTitle: "阿里云盘", zhNote: "网盘同步",
              enTitle: "Aliyun Drive", enNote: "Cloud storage sync",
              onByDefault: true),
    DaemonDef(exe: "mds_stores",
              zhTitle: "Spotlight 索引", zhNote: "重建索引时很吃性能",
              enTitle: "Spotlight Indexing", enNote: "Heavy while reindexing",
              onByDefault: false),
    DaemonDef(exe: "mdworker_shared",
              zhTitle: "Spotlight 索引子进程", zhNote: "重建索引时很吃性能",
              enTitle: "Spotlight Index Worker", enNote: "Heavy while reindexing",
              onByDefault: false),
    DaemonDef(exe: "softwareupdated",
              zhTitle: "系统更新服务", zhNote: "后台下载更新",
              enTitle: "Software Update", enNote: "Downloads updates in background",
              onByDefault: false),
    DaemonDef(exe: "nsurlsessiond",
              zhTitle: "后台下载", zhNote: "iCloud/系统后台下载",
              enTitle: "Background Downloads", enNote: "System and iCloud downloads",
              onByDefault: false),
    DaemonDef(exe: "Adobe Desktop Service",
              zhTitle: "Adobe 后台服务", zhNote: "Creative Cloud 常驻",
              enTitle: "Adobe Background Service", enNote: "Creative Cloud resident helper",
              onByDefault: true),
    DaemonDef(exe: "SourceKitService",
              zhTitle: "Xcode 索引服务", zhNote: "代码索引，写完代码再关",
              enTitle: "Xcode Indexing", enNote: "Code indexing — quit after coding",
              onByDefault: false)
]

struct Item {
    let key: String
    let kind: ItemKind
    let title: String
    let subtitle: String
    let pids: [pid_t]
    let memory: UInt64
    let defaultOn: Bool
    let bundleID: String?
    let appPath: String?
}

/// Helper apps live inside another bundle (Chrome Helpers, WebKit GPU processes…).
/// They are already counted in the parent app's total, so don't list them twice.
/// 翻转坐标系的容器：保证列表内容永远从顶部开始排（解决 NSClipView 垂直居中的空白问题）
final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}

func isHelperBundle(_ url: URL, allPaths: [String]) -> Bool {
    let p = url.path
    let markers = ["/Contents/Frameworks/", "/Contents/XPCServices/", "/Contents/PlugIns/",
                   "/Contents/Library/", "/Contents/Helpers/",
                   "/Frameworks/", "/XPCServices/", "/PlugIns/", "/Helpers/", ".xpc/", ".appex"]
    for m in markers where p.contains(m) { return true }
    for other in allPaths where other != p && p.hasPrefix(other + "/") { return true }
    return false
}

func buildItems() -> (apps: [Item], daemons: [Item]) {
    let procs = scanAllProcesses()
    let running = NSWorkspace.shared.runningApplications
    let allPaths = running.compactMap { $0.bundleURL?.path }

    var apps: [Item] = []
    var attributed = Set<pid_t>()

    for app in running {
        guard app.activationPolicy != .prohibited else { continue }
        let bid = app.bundleIdentifier ?? ""
        let name = app.localizedName ?? bid
        if kNeverQuit.contains(bid) || kNeverQuitNames.contains(name) { continue }
        // 浏览器扩展 / helper 进程的名字里几乎都带 Helper，用户不会想单独退它们
        if name.lowercased().contains("helper") || bid.lowercased().contains("helper") { continue }
        guard let url = app.bundleURL, !isHelperBundle(url, allPaths: allPaths) else { continue }
        let prefix = url.path + "/"

        var total: UInt64 = 0
        var pids: [pid_t] = []
        for p in procs where p.path.hasPrefix(prefix) {
            total += p.memory
            pids.append(p.pid)
            attributed.insert(p.pid)
        }
        if pids.isEmpty { continue }
        apps.append(Item(key: bid.isEmpty ? prefix : bid,
                         kind: .app,
                         title: name,
                         subtitle: bid.isEmpty ? t("item.app") : bid,
                         pids: pids,
                         memory: total,
                         defaultOn: kHeavyApps.contains(bid),
                         bundleID: app.bundleIdentifier,
                         appPath: url.path))
    }
    apps.sort { $0.memory > $1.memory }

    var daemons: [Item] = []
    for def in kDaemonDefs {
        var total: UInt64 = 0
        var pids: [pid_t] = []
        for p in procs where p.name == def.exe {
            if attributed.contains(p.pid) { continue }
            total += p.memory
            pids.append(p.pid)
        }
        if pids.isEmpty || total < 15 * 1_048_576 { continue }
        daemons.append(Item(key: def.exe, kind: .daemon, title: def.title,
                            subtitle: def.note, pids: pids, memory: total,
                            defaultOn: def.onByDefault, bundleID: nil, appPath: nil))
    }
    daemons.sort { $0.memory > $1.memory }
    return (apps, daemons)
}

// MARK: - Admin helper

func runAsAdmin(_ shellCommand: String) -> Bool {
    let src = "do shell script \"\(shellCommand)\" with administrator privileges"
    var err: NSDictionary?
    NSAppleScript(source: src)?.executeAndReturnError(&err)
    return err == nil
}

// MARK: - Memory bar (custom-drawn)

final class MemBar: NSView {
    var ratio: Double = 0 { didSet { needsDisplay = true } }
    var tint: NSColor = .systemGreen { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let h = bounds.height
        let r = h / 2
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: r, yRadius: r).fill()

        let w = max(h, bounds.width * CGFloat(min(1, max(0, ratio))))
        tint.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: h), xRadius: r, yRadius: r).fill()
    }
}

// MARK: - Row view

final class RowView: NSView {
    let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let titleLabel = NSTextField(labelWithString: "")
    let subLabel = NSTextField(labelWithString: "")
    let memLabel = NSTextField(labelWithString: "")
    var item: Item?

    init(item: Item, checked: Bool) {
        self.item = item
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        checkbox.state = checked ? .on : .off
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        // 自定义勾选样式：避免不同系统版本 checkbox 视觉差异过大
        checkbox.title = ""

        titleLabel.stringValue = item.title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subLabel.stringValue = item.subtitle
        subLabel.font = .systemFont(ofSize: 10.5)
        subLabel.textColor = .tertiaryLabelColor
        subLabel.lineBreakMode = .byTruncatingTail
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        memLabel.stringValue = mb(item.memory)
        memLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        memLabel.alignment = .right
        memLabel.textColor = item.memory > 1_500_000_000 ? .systemRed
            : (item.memory > 600_000_000 ? .systemOrange : .secondaryLabelColor)
        memLabel.translatesAutoresizingMaskIntoConstraints = false
        memLabel.setContentHuggingPriority(.required, for: .horizontal)
        memLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(checkbox); addSubview(titleLabel); addSubview(subLabel); addSubview(memLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 34),
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            checkbox.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -1),
            subLabel.trailingAnchor.constraint(lessThanOrEqualTo: memLabel.leadingAnchor, constant: -8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: memLabel.leadingAnchor, constant: -8),
            memLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            memLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            memLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    var isOn: Bool { checkbox.state == .on }
}

// MARK: - Panel

final class PanelController: NSObject {
    var window: NSWindow!
    var statsLabel = NSTextField(labelWithString: "")
    var detailLabel = NSTextField(labelWithString: "")
    var bar = MemBar()
    var scroll = NSScrollView()
    var stack = NSStackView()
    var banner = NSTextField(labelWithString: "")
    var btnBoost: NSButton!
    var btnRestore: NSButton!
    var btnPurge: NSButton!
    var btnRefresh: NSButton!
    var btnSelect: NSButton!
    var rows: [RowView] = []
    var quitRecords: [(bundleID: String, path: String)] = [] {
        didSet { UserDefaults.standard.set(quitRecords.map { $0.path }, forKey: "savedAppPaths") }
    }

    override init() {
        super.init()
        if let saved = UserDefaults.standard.array(forKey: "savedAppPaths") as? [String] {
            quitRecords = saved.map { (bundleID: "", path: $0) }
        }
        buildWindow()
    }

    func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 680),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = t("panel.title")
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 9
        root.edgeInsets = NSEdgeInsets(top: 14, left: 18, bottom: 16, right: 18)
        root.translatesAutoresizingMaskIntoConstraints = false

        statsLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor

        bar.ratio = 0
        bar.translatesAutoresizingMaskIntoConstraints = false

        banner.font = .systemFont(ofSize: 11.5)
        banner.textColor = .secondaryLabelColor
        banner.lineBreakMode = .byWordWrapping
        banner.maximumNumberOfLines = 2

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let container = FlippedContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        scroll.documentView = container
        scroll.translatesAutoresizingMaskIntoConstraints = false

        btnBoost = makeButton(t("btn.boost"), action: #selector(doBoost), emphasized: true)
        btnRestore = makeButton(t("btn.restore"), action: #selector(doRestore), emphasized: false)
        btnPurge = makeButton(t("btn.purge"), action: #selector(doPurge), emphasized: false)
        btnRefresh = makeButton(t("btn.refresh"), action: #selector(doRefresh), emphasized: false)
        btnSelect = makeButton(t("btn.selectRec"), action: #selector(doSelectRecommended), emphasized: false)

        let buttons = NSStackView(views: [btnBoost, btnRestore, btnPurge, btnRefresh, btnSelect])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(statsLabel)
        root.addArrangedSubview(bar)
        root.addArrangedSubview(detailLabel)
        root.addArrangedSubview(scroll)
        root.addArrangedSubview(banner)
        root.addArrangedSubview(buttons)

        window.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            root.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            root.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
            bar.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -36),
            bar.heightAnchor.constraint(equalToConstant: 10),
            scroll.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -36),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 320),
            // 容器铺满可视区域，内容不足时也顶对齐
            container.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            container.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualTo: scroll.contentView.heightAnchor),
            // stack 钉在容器顶部
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            banner.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -36)
        ])

        refreshAll()
    }

    func makeButton(_ title: String, action: Selector, emphasized: Bool) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .rounded
        b.font = .systemFont(ofSize: 12.5, weight: emphasized ? .semibold : .regular)
        if emphasized { b.keyEquivalent = "\r" }
        return b
    }

    /// Called when the user switches language at runtime
    func applyLanguage() {
        window.title = t("panel.title")
        btnBoost.title = t("btn.boost")
        btnRestore.title = t("btn.restore")
        btnPurge.title = t("btn.purge")
        btnRefresh.title = t("btn.refresh")
        btnSelect.title = t("btn.selectRec")
        refreshAll()
    }

    // MARK: refresh

    func refreshAll() {
        let built = buildItems()
        rebuildRows(apps: built.apps, daemons: built.daemons)
        tick()
    }

    func rebuildRows(apps: [Item], daemons: [Item]) {
        for v in stack.arrangedSubviews { stack.removeArrangedSubview(v); v.removeFromSuperview() }
        rows.removeAll()

        addSection(t("section.apps"), t("section.appsHint"))
        if apps.isEmpty { addHint(t("empty.apps")) }
        for it in apps {
            // 默认不勾选，用户自己挑；只有点「全选推荐项」才会勾上重内存应用
            let r = RowView(item: it, checked: false)
            rows.append(r)
            stack.addArrangedSubview(r)
            r.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
            r.trailingAnchor.constraint(equalTo: stack.trailingAnchor).isActive = true
        }

        addSection(t("section.daemons"), t("section.daemonsHint"))
        if daemons.isEmpty { addHint(t("empty.daemons")) }
        for it in daemons {
            let r = RowView(item: it, checked: false)
            rows.append(r)
            stack.addArrangedSubview(r)
            r.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
            r.trailingAnchor.constraint(equalTo: stack.trailingAnchor).isActive = true
        }
    }

    func addSection(_ title: String, _ hint: String) {
        let box = NSStackView()
        box.orientation = .vertical
        box.alignment = .leading
        box.spacing = 0
        box.translatesAutoresizingMaskIntoConstraints = false

        let t1 = NSTextField(labelWithString: title)
        t1.font = .systemFont(ofSize: 12, weight: .bold)
        let h = NSTextField(labelWithString: hint)
        h.font = .systemFont(ofSize: 10)
        h.textColor = .tertiaryLabelColor

        box.addArrangedSubview(t1)
        box.addArrangedSubview(h)
        stack.addArrangedSubview(box)
        box.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 4).isActive = true

        let pad = NSView()
        pad.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(pad)
        pad.heightAnchor.constraint(equalToConstant: 6).isActive = true
        pad.widthAnchor.constraint(equalToConstant: 1).isActive = true
        pad.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
    }

    func addHint(_ text: String) {
        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: 11.5)
        l.textColor = .tertiaryLabelColor
        stack.addArrangedSubview(l)
        l.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 24).isActive = true
    }

    func tick() {
        let s = readMemory()
        statsLabel.stringValue = String(format: t("panel.used"), gb(s.used), gb(s.total), gb(s.available))
        detailLabel.stringValue = String(format: t("panel.detail"),
                                         gb(s.appMemory), gb(s.compressed), gb(s.cached), gb(s.swapUsed))
        bar.ratio = s.usedRatio

        if s.usedRatio > 0.88 || s.swapUsed > 4 * 1_073_741_824 {
            bar.tint = .systemRed
            banner.stringValue = t("banner.red")
            banner.textColor = .systemRed
        } else if s.usedRatio > 0.78 {
            bar.tint = .systemOrange
            banner.stringValue = t("banner.orange")
            banner.textColor = .systemOrange
        } else {
            bar.tint = .systemGreen
            banner.stringValue = t("banner.green")
            banner.textColor = .secondaryLabelColor
        }
        StatusBar.shared.update(sample: s)
    }

    // MARK: actions

    @objc func doSelectRecommended() {
        for r in rows where r.item?.defaultOn == true { r.checkbox.state = .on }
    }

    @objc func doRefresh() {
        refreshAll()
        banner.stringValue = t("banner.refreshed")
        banner.textColor = .secondaryLabelColor
    }

    @objc func doBoost() {
        let selected = rows.filter { $0.isOn }.compactMap { $0.item }
        guard !selected.isEmpty else {
            banner.stringValue = t("banner.noneSelected")
            banner.textColor = .systemOrange
            return
        }
        let before = readMemory()
        var estimate: UInt64 = 0
        var fired = 0
        var denied: [pid_t] = []
        var stubborn: [Item] = []   // 温和退出后仍赖着不走的应用

        for it in selected {
            switch it.kind {
            case .app:
                if let bid = it.bundleID,
                   let app = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first {
                    if let path = it.appPath, !quitRecords.contains(where: { $0.path == path }) {
                        quitRecords.append((bid, path))
                    }
                    // 温和退出：等价于点红色关闭按钮，应用会走正常保存流程
                    if app.terminate() { fired += 1 }
                    stubborn.append(it)
                }
            case .daemon:
                for pid in it.pids {
                    if kill(pid, SIGTERM) == 0 { fired += 1 }
                    else if errno == EPERM { denied.append(pid) }
                }
            }
            estimate += it.memory
        }

        if !denied.isEmpty {
            let cmd = "/bin/kill -TERM " + denied.map { String($0) }.joined(separator: " ")
            banner.stringValue = t("banner.adminNeeded")
            banner.textColor = .systemBlue
            DispatchQueue.main.async {
                _ = runAsAdmin(cmd)
                self.finishBoost(before: before, estimate: estimate, fired: fired)
            }
            return
        }
        // 稍等片刻，检查哪些应用温和退出失败，需要的话再问用户是否强退
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            let stillRunning = stubborn.filter { it in
                guard let bid = it.bundleID else { return false }
                return NSRunningApplication.runningApplications(withBundleIdentifier: bid).contains {
                    !$0.isTerminated
                }
            }
            if stillRunning.isEmpty {
                self.finishBoost(before: before, estimate: estimate, fired: fired)
            } else {
                let names = stillRunning.map { $0.title }.joined(separator: "、")
                self.askForceQuit(before: before, estimate: estimate, fired: fired,
                                  items: stillRunning, names: names)
            }
        }
    }

    func askForceQuit(before: MemSample, estimate: UInt64, fired: Int,
                      items: [Item], names: String) {
        let alert = NSAlert()
        let askZh = "以下应用没有正常退出（可能有未保存内容）：\n\n%@\n\n要强制退出它们吗？强制退出可能丢失未保存的数据。"
        let askEn = "These apps did not quit normally (they may have unsaved work):\n\n%@\n\nForce quit them? This may lose unsaved changes."
        alert.messageText = gLang == .zh ? "有些应用没退干净" : "Some apps are still running"
        alert.informativeText = String(format: gLang == .zh ? askZh : askEn, names)
        alert.alertStyle = .warning
        alert.addButton(withTitle: gLang == .zh ? "强制退出" : "Force Quit")
        alert.addButton(withTitle: gLang == .zh ? "算了" : "Leave Them")
        if alert.runModal() == .alertFirstButtonReturn {
            for it in items {
                if let bid = it.bundleID {
                    NSRunningApplication.runningApplications(withBundleIdentifier: bid)
                        .filter { !$0.isTerminated }
                        .forEach { $0.forceTerminate() }
                }
            }
        }
        finishBoost(before: before, estimate: estimate, fired: fired)
    }

    func finishBoost(before: MemSample, estimate: UInt64, fired: Int) {
        banner.stringValue = String(format: t("banner.boostRunning"), fired, mb(estimate))
        banner.textColor = .systemBlue
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            let after = readMemory()
            let real = after.available > before.available ? after.available - before.available : 0
            self.banner.stringValue = String(format: t("banner.boostDone"),
                                             gb(before.available), gb(after.available), mb(real))
            self.banner.textColor = .systemGreen
            self.tick()
        }
    }

    @objc func doPurge() {
        let script = "do shell script \"/usr/sbin/purge\" with administrator privileges"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var err: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&err)
            DispatchQueue.main.async {
                let s = readMemory()
                if err == nil {
                    self.banner.stringValue = String(format: t("banner.purgeDone"), gb(s.available))
                    self.banner.textColor = .systemGreen
                } else {
                    self.banner.stringValue = t("banner.purgeFail")
                    self.banner.textColor = .systemOrange
                }
                self.tick()
            }
        }
    }

    @objc func doRestore() {
        guard !quitRecords.isEmpty else {
            banner.stringValue = t("banner.noRecords")
            banner.textColor = .secondaryLabelColor
            return
        }
        var n = 0
        for r in quitRecords where FileManager.default.fileExists(atPath: r.path) {
            let url = URL(fileURLWithPath: r.path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
            n += 1
        }
        quitRecords.removeAll()
        banner.stringValue = String(format: t("banner.restored"), n)
        banner.textColor = .systemGreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.refreshAll() }
    }

    func show() {
        refreshAll()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

/// Menu-bar quick action: silently quit the recommended items (never touches system processes)
func quickBoost() -> String {
    let built = buildItems()
    var freed: UInt64 = 0
    for it in built.apps where it.defaultOn {
        if let bid = it.bundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first {
            if app.terminate() { freed += it.memory }
        }
    }
    for it in built.daemons where it.defaultOn {
        var ok = true
        for pid in it.pids where kill(pid, SIGTERM) != 0 { ok = false }
        if ok { freed += it.memory }
    }
    return freed > 0 ? String(format: t("quick.done"), mb(freed)) : t("quick.none")
}

// MARK: - Menu bar

final class StatusBar: NSObject {
    static let shared = StatusBar()
    var item: NSStatusItem?
    var menu = NSMenu()
    var infoItem = NSMenuItem()
    var panel: PanelController!

    func setup(panel: PanelController) {
        self.panel = panel
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = item?.button {
            b.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            b.title = "…"
        }
        buildMenu()
        update(sample: readMemory())

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let s = readMemory()
            self.update(sample: s)
            if self.panel.window.isVisible { self.panel.tick() }
        }
    }

    func buildMenu() {
        menu.removeAllItems()
        infoItem = NSMenuItem()
        infoItem.isEnabled = false
        menu.addItem(infoItem)
        menu.addItem(.separator())

        let open = NSMenuItem(title: t("menu.open"), action: #selector(openPanel), keyEquivalent: "o")
        open.target = self
        menu.addItem(open)

        let quick = NSMenuItem(title: t("menu.quick"), action: #selector(quickAction), keyEquivalent: "b")
        quick.target = self
        menu.addItem(quick)

        let purge = NSMenuItem(title: t("menu.purge"), action: #selector(purgeCache), keyEquivalent: "")
        purge.target = self
        menu.addItem(purge)

        menu.addItem(.separator())

        // 语言切换 / language switcher
        let langItem = NSMenuItem(title: t("menu.lang"), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let zh = NSMenuItem(title: "简体中文", action: #selector(setChinese), keyEquivalent: "")
        zh.target = self
        zh.state = gLang == .zh ? .on : .off
        let en = NSMenuItem(title: "English", action: #selector(setEnglish), keyEquivalent: "")
        en.target = self
        en.state = gLang == .en ? .on : .off
        sub.addItem(zh)
        sub.addItem(en)
        langItem.submenu = sub
        menu.addItem(langItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: t("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        item?.menu = menu
    }

    func update(sample s: MemSample) {
        let dot: String
        if s.usedRatio > 0.88 || s.swapUsed > 4 * 1_073_741_824 { dot = "🔴" }
        else if s.usedRatio > 0.78 { dot = "🟠" }
        else { dot = "🟢" }
        let short = String(format: "%.1fG", Double(s.available) / 1_073_741_824.0)
        item?.button?.title = "\(dot) \(short)"
        infoItem.title = String(format: t("menu.status"), gb(s.available), gb(s.compressed), gb(s.swapUsed))
    }

    func switchLanguage(_ l: Lang) {
        gLang = l
        UserDefaults.standard.set(l.rawValue, forKey: "lang")
        buildMenu()
        panel.applyLanguage()
        update(sample: readMemory())
    }

    @objc func setChinese() { switchLanguage(.zh) }
    @objc func setEnglish() { switchLanguage(.en) }

    @objc func openPanel() { panel.show() }

    @objc func quickAction() {
        let msg = quickBoost()
        let alert = NSAlert()
        alert.messageText = msg
        alert.informativeText = t("quick.info")
        alert.alertStyle = .informational
        alert.addButton(withTitle: t("btn.ok"))
        alert.runModal()
        panel.refreshAll()
    }

    @objc func purgeCache() {
        let script = "do shell script \"/usr/sbin/purge\" with administrator privileges"
        DispatchQueue.global(qos: .userInitiated).async {
            var err: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&err)
            DispatchQueue.main.async {
                let s = readMemory()
                let ok = err == nil
                let alert = NSAlert()
                alert.messageText = ok ? t("alert.purgeOk") : t("alert.purgeFail")
                alert.informativeText = ok
                    ? String(format: t("alert.purgeOkBody"), gb(s.available))
                    : t("alert.purgeFailBody")
                alert.addButton(withTitle: t("btn.ok"))
                alert.runModal()
                self.update(sample: readMemory())
            }
        }
    }
}

// MARK: - App lifecycle

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: PanelController!

    func applicationDidFinishLaunching(_ n: Notification) {
        panel = PanelController()
        StatusBar.shared.setup(panel: panel)

        if CommandLine.arguments.contains("--panel") { panel.show() }

        let d = UserDefaults.standard
        if !d.bool(forKey: "didShowWelcome") {
            d.set(true, forKey: "didShowWelcome")
            let alert = NSAlert()
            alert.messageText = t("welcome.title")
            alert.informativeText = t("welcome.body")
            alert.addButton(withTitle: t("btn.gotit"))
            alert.runModal()
            panel.show()
        }
    }
}

// CLI self-test: no UI, prints one sample and the item lists
if CommandLine.arguments.contains("--selftest") {
    let s = readMemory()
    print("lang=\(gLang.rawValue)")
    print("total=\(gb(s.total)) used=\(gb(s.used)) free=\(gb(s.available))")
    print("app=\(gb(s.appMemory)) compressed=\(gb(s.compressed)) cached=\(gb(s.cached)) wired=\(gb(s.wired))")
    print("swap=\(gb(s.swapUsed)) / \(gb(s.swapTotal))")
    let built = buildItems()
    print("--- apps ---")
    for it in built.apps.prefix(10) { print("  \(it.title)  \(mb(it.memory))  checked=\(it.defaultOn)") }
    print("--- daemons ---")
    for it in built.daemons.prefix(10) { print("  \(it.title)  \(mb(it.memory))") }
    exit(0)
}

let app = NSApplication.shared

// single instance only
if let bid = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: bid).count > 1 {
    exit(0)
}

let delegate = AppDelegate()
app.delegate = delegate
// .regular：Dock 里有图标（用户偏好），同时仍保留菜单栏图标
app.setActivationPolicy(.regular)
app.run()
