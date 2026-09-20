import Foundation
import UniformTypeIdentifiers

@MainActor
final class FileStore: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        currentURL = documents
        reload()
    }

    func reload() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: currentURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        items = urls.sorted {
            let a = (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let b = (try? $1.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if a != b { return a && !b }
            return $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }.map { url in
            let directory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return FileItem(url: url, isDirectory: directory)
        }
    }

    func open(_ item: FileItem) {
        guard item.isDirectory else { return }
        currentURL = item.url
        reload()
    }

    func goUp() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard currentURL != documents else { return }
        currentURL = currentURL.deletingLastPathComponent()
        reload()
    }

    func importFile(from url: URL) throws {
        let destination = currentURL.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        reload()
    }

    func delete(_ item: FileItem) throws {
        try FileManager.default.removeItem(at: item.url)
        reload()
    }
}
