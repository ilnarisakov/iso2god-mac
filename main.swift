import SwiftUI
import UniformTypeIdentifiers

@main
struct ISO2GODApp: App {
    var body: some Scene {
        WindowGroup { ContentView().frame(width: 520, height: 700) }
            .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var iso: URL?
    @State private var out: URL?
    @State private var log = ""
    @State private var running = false
    @State private var targeted = false
    @State private var showHelp = false
    @AppStorage("coversDir") private var coversDir = ""

    private var ready: Bool { iso != nil && out != nil && !running }

    var body: some View {
        VStack(spacing: 14) {
            header

            step(1, done: iso != nil, title: "Образ игры") {
                dropZone
            }

            step(2, done: out != nil, title: "Куда сохранить") {
                pathRow(out?.path ?? "Папка не выбрана", button: "Выбрать…") { pick(folder: true) }
                Text("Внутри появится папка с именем игры").font(.caption).foregroundStyle(.secondary)
            }

            Button(action: generate) {
                HStack(spacing: 8) {
                    if running { ProgressView().controlSize(.small) }
                    else { Image(systemName: "wand.and.stars") }
                    Text(running ? "Идёт генерация…" : "Генерация").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .disabled(!ready)

            card {
                HStack {
                    Label("Обложки для Aurora", systemImage: "photo.on.rectangle.angled").font(.headline)
                    Spacer()
                    Button { showHelp = true } label: { Label("Инструкция", systemImage: "questionmark.circle") }
                        .controlSize(.small)
                }
                pathRow(coversDir.isEmpty ? "Папка обложек не выбрана" : coversDir, button: "Изменить…") { _ = chooseCoversDir() }
                Button { addCovers() } label: {
                    Label("Добавить обложки на флешку…", systemImage: "externaldrive.badge.plus").frame(maxWidth: .infinity)
                }.disabled(running)
                Text("Сначала дайте Aurora просканировать игру на консоли").font(.caption).foregroundStyle(.secondary)
            }

            if !log.isEmpty {
                ScrollView {
                    Text(log).font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(8)
                }
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                .frame(minHeight: 70, maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .background(.background)
        .sheet(isPresented: $showHelp) { HelpView() }
    }

    // MARK: - pieces

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "opticaldisc.fill").font(.system(size: 30)).foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("ISO → Games on Demand").font(.title2.bold())
                Text("Xbox 360 · Freeboot · Aurora").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(targeted ? Color.accentColor : Color.secondary.opacity(0.5),
                          style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            .background((targeted ? Color.accentColor.opacity(0.1) : .clear), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: iso == nil ? "arrow.down.doc" : "checkmark.circle.fill")
                        .font(.title2).foregroundStyle(iso == nil ? Color.secondary : .green)
                    Text(iso?.lastPathComponent ?? "Перетащите .iso сюда")
                        .lineLimit(2).truncationMode(.middle).multilineTextAlignment(.center)
                    if let iso { Text(size(of: iso)).font(.caption).foregroundStyle(.secondary) }
                    Button(iso == nil ? "Выбрать ISO…" : "Выбрать другой…") { pick(folder: false) }.controlSize(.small)
                }.padding(10)
            }
            .frame(height: 118)
            .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
                providers.first?.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let d = item as? Data, let u = URL(dataRepresentation: d, relativeTo: nil),
                       u.pathExtension.lowercased() == "iso" {
                        DispatchQueue.main.async { iso = u }
                    }
                }
                return true
            }
    }

    private func pathRow(_ text: String, button: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "folder").foregroundStyle(.secondary)
            Text(text).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
            Spacer()
            Button(button, action: action).controlSize(.small)
        }
    }

    private func step<C: View>(_ n: Int, done: Bool, title: String, @ViewBuilder content: () -> C) -> some View {
        card {
            HStack(spacing: 8) {
                Image(systemName: done ? "checkmark.circle.fill" : "\(n).circle")
                    .foregroundStyle(done ? .green : .secondary)
                Text(title).font(.headline)
            }
            content()
        }
    }

    private func card<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private func size(of url: URL) -> String {
        let n = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
    }

    func pick(folder: Bool) {
        let p = NSOpenPanel()
        p.canChooseDirectories = folder
        p.canChooseFiles = !folder
        p.canCreateDirectories = folder
        if !folder { p.allowedContentTypes = [UTType(filenameExtension: "iso") ?? .data] }
        if p.runModal() == .OK { if folder { out = p.url } else { iso = p.url } }
    }

    func generate() {
        guard let iso, let out, let covers = coversURL() else { return }
        let dest = out.appendingPathComponent(iso.deletingPathExtension().lastPathComponent)
        do { try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true) }
        catch { log = "\(error)"; return }
        running = true; log = ""
        run("iso2god", ["-j", "4", iso.path, dest.path]) { code in
            guard code == 0 else { log += "\nОшибка (код \(code))"; running = false; return }
            // iso2god prints "Title ID: XXXXXXXX"; the cover is looked up by it
            guard let r = log.range(of: "Title ID: [0-9A-Fa-f]{8}", options: .regularExpression) else {
                log += "\nГотово ✓ (Title ID не найден, обложка пропущена)"; running = false; return
            }
            let tid = String(log[r].suffix(8))
            log += "\nОбложка для \(tid)…\n"
            fetchCover(tid, into: covers) { ok in
                log += ok ? "\nГотово ✓ (обложка в \(covers.path))" : "\nКонвертация готова, но обложку загрузить не удалось"
                running = false
            }
        }
    }

    /// Covers folder is chosen once and remembered; "Изменить…" re-opens the picker.
    func coversURL() -> URL? {
        if coversDir.isEmpty && !chooseCoversDir() { return nil }
        return URL(fileURLWithPath: coversDir)
    }

    func chooseCoversDir() -> Bool {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.canCreateDirectories = true
        p.message = "Папка, куда складывать обложки (GC<TitleID>.asset)"
        guard p.runModal() == .OK, let u = p.url else { return false }
        coversDir = u.path
        return true
    }

    /// Makes sure <covers>/GC<tid>.asset exists, downloading it only if missing.
    func fetchCover(_ tid: String, into covers: URL, done: @escaping (Bool) -> Void) {
        let file = covers.appendingPathComponent("GC\(tid).asset")
        if FileManager.default.fileExists(atPath: file.path) { done(true); return }
        run("cover", [tid, covers.path]) { done($0 == 0) }
    }

    /// Aurora creates GameData/<TitleID>_<DbId> only after it scanned the game on the console,
    /// so covers are added in a second step: pick the flash drive, every such folder gets its GC<TitleID>.asset.
    func addCovers() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false
        p.message = "Выберите флешку (или папку Aurora)"
        guard let covers = coversURL(), p.runModal() == .OK, let root = p.url else { return }
        let fm = FileManager.default
        log = ""
        // GameData is usually <root>/Aurora/Data/GameData; fall back to a bounded search
        var gameData = ["Aurora/Data/GameData", "Data/GameData", "GameData"]
            .map { root.appendingPathComponent($0) }
            .first { fm.fileExists(atPath: $0.path) }
        if gameData == nil, let en = fm.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for case let u as URL in en {
                if en.level > 4 { en.skipDescendants() }
                else if u.lastPathComponent == "GameData" { gameData = u; break }
            }
        }
        guard let gameData else { log = "Папка GameData не найдена. Сначала запустите игру в Aurora, чтобы она просканировала её."; return }
        let todo: [(tid: String, dir: URL)] = ((try? fm.contentsOfDirectory(at: gameData, includingPropertiesForKeys: nil)) ?? [])
            .compactMap { d in
                guard d.lastPathComponent.range(of: "^[0-9A-Fa-f]{8}_[0-9A-Fa-f]{8}$", options: .regularExpression) != nil else { return nil }
                let tid = String(d.lastPathComponent.prefix(8)).uppercased()
                return fm.fileExists(atPath: d.appendingPathComponent("GC\(tid).asset").path) ? nil : (tid, d)
            }
        if todo.isEmpty { log = "Нечего добавлять: у всех игр в \(gameData.path) обложка уже есть (или игр нет)."; return }
        running = true
        var queue = todo[...]
        func next() {
            guard let item = queue.popFirst() else { log += "\nГотово ✓"; running = false; return }
            log += "\(item.tid): "
            fetchCover(item.tid, into: covers) { ok in
                let src = covers.appendingPathComponent("GC\(item.tid).asset")
                let dst = item.dir.appendingPathComponent("GC\(item.tid).asset")
                if ok, (try? fm.copyItem(at: src, to: dst)) != nil { log += "готово\n" }
                else { log += "обложка не найдена\n" }
                next()
            }
        }
        next()
    }

    /// Runs a tool bundled in Resources, streams its output into the log, calls `done` on the main thread.
    func run(_ name: String, _ args: [String], done: @escaping (Int32) -> Void) {
        guard let bin = Bundle.main.url(forResource: name, withExtension: nil) else {
            log += "\(name) не найден внутри приложения"; running = false; return
        }
        let proc = Process()
        proc.executableURL = bin
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe; proc.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { h in
            let s = String(decoding: h.availableData, as: UTF8.self)
            DispatchQueue.main.async { log += s }
        }
        proc.terminationHandler = { p in
            pipe.fileHandleForReading.readabilityHandler = nil
            // let the last log chunks land before `done` reads the log
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { done(p.terminationStatus) }
        }
        do { try proc.run() } catch { log += "\(error)"; running = false }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(String, String, String)] = [
        ("1", "Конвертация", "Перетащите .iso, выберите папку и нажмите «Генерация». Обложка скачается сама и сохранится в папку обложек. Готовую папку игры скопируйте на флешку."),
        ("2", "Сканирование в Aurora", "Вставьте флешку в Xbox, запустите Aurora и просканируйте игры. На флешке появится папка Aurora/Data/GameData/<TitleID>_<номер>. Без этого шага класть обложку некуда: номер присваивает сама Aurora."),
        ("3", "Обложки на флешку", "Вставьте флешку в Mac, нажмите «Добавить обложки на флешку…» и выберите её. Приложение найдёт GameData и положит GC<TitleID>.asset в папку каждой игры, у которой его нет."),
        ("4", "Готово", "Верните флешку в Xbox и перезапустите Aurora. Обложки появятся в списке игр."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Как добавить обложки в Aurora").font(.title2.bold())
            ForEach(steps, id: \.0) { n, title, text in
                HStack(alignment: .top, spacing: 10) {
                    Text(n).font(.headline).frame(width: 26, height: 26)
                        .background(Color.accentColor.opacity(0.2), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        Text(text).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Divider()
            Text("Если пишет «обложка не найдена»: на xboxunity.net её нет. Положите свой GC<TitleID>.asset в папку обложек. «Папка GameData не найдена»: игра ещё не просканирована или флешка не FAT32. Если консоль в интернете, Aurora может скачать обложки сама.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack { Spacer(); Button("Закрыть") { dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding(22).frame(width: 460)
    }
}
