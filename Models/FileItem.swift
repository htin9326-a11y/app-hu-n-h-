import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool

    var name: String { url.lastPathComponent }
    var size: Int64? {
        try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)
    }
}
