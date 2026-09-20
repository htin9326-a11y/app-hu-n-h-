import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = FileStore()
    @State private var showImporter = false
    @State private var search = ""
    @State private var selected: FileItem?
    @State private var showDelete = false

    private var filtered: [FileItem] {
        guard !search.isEmpty else { return store.items }
        return store.items.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        locationCard
                        fileList
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selected) { item in
                SharePreview(item: item)
                    .presentationDetents([.medium])
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                guard case .success(let urls) = result else { return }
                for url in urls {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    try? store.importFile(from: url)
                }
            }
            .confirmationDialog("Xóa file này?", isPresented: $showDelete, presenting: selected) { item in
                Button("Xóa", role: .destructive) { try? store.delete(item); selected = nil }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aujunpeak")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("File Manager")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showImporter = true } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .frame(width: 46, height: 46)
                    .background(Color.primary)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Files").font(.headline)
                    Text("App Documents").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { store.goUp() } label: {
                    Image(systemName: "chevron.up")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Tìm file...", text: $search)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }

    private var fileList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Files").font(.title3.bold())
                Spacer()
                Text("\(filtered.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 38))
                        .foregroundStyle(.secondary)
                    Text("Chưa có file")
                        .font(.headline)
                    Text("Nhấn + để nhập file từ ứng dụng Files")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 45)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { item in
                        FileRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { store.open(item) }
                            .contextMenu {
                                if !item.isDirectory {
                                    Button("Xem / Chia sẻ") { selected = item }
                                    Button("Xóa", role: .destructive) { selected = item; showDelete = true }
                                }
                            }
                    }
                }
                .padding(.vertical, 5)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
    }
}

private struct FileRow: View {
    let item: FileItem
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: item.isDirectory ? "folder.fill" : icon)
                .font(.title3)
                .foregroundStyle(item.isDirectory ? .blue : .primary)
                .frame(width: 42, height: 42)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(item.isDirectory ? "Folder" : sizeText)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: item.isDirectory ? "chevron.right" : "ellipsis")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
    private var icon: String {
        switch item.url.pathExtension.lowercased() {
        case "zip", "3105": return "archivebox.fill"
        case "plist", "json": return "doc.text.fill"
        case "png", "jpg", "jpeg", "heic": return "photo.fill"
        case "pdf": return "doc.richtext.fill"
        default: return "doc.fill"
        }
    }
    private var sizeText: String {
        guard let size = item.size else { return "File" }
        if size < 1024 { return "\(size) B" }
        if size < 1024 * 1024 { return String(format: "%.1f KB", Double(size) / 1024) }
        return String(format: "%.1f MB", Double(size) / 1048576)
    }
}

private struct SharePreview: View {
    let item: FileItem
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 54))
                Text(item.name).font(.title3.bold()).multilineTextAlignment(.center)
                ShareLink(item: item.url) {
                    Label("Chia sẻ file", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.primary).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
            .navigationTitle("File")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Đóng") { dismiss() } } }
        }
    }
}
