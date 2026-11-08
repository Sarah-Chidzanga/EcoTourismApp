import SwiftUI
import PhotosUI
import ImageIO

struct ShareMemory: View {
    @State private var selection: [PhotosPickerItem] = []
    @State private var photos: [MemoryPhoto] = []
    @State private var caption = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var share: MemoryShare?
    @State private var copiedCaption = false

    var body: some View {
        Form {
            Section {
                Text("Bring your Zimbabwe adventure to life.")
                    .font(.title2.bold())
                Text("Choose up to five photos and add your story. Nothing is posted until you confirm in the app you choose.")
                    .foregroundStyle(.secondary)
            }
            Section("Your Photos") {
                PhotosPicker(selection: $selection, maxSelectionCount: 5, matching: .images) {
                    Label(photos.isEmpty ? "Choose Photos" : "Change Photos", systemImage: "photo.on.rectangle")
                }
                if loading { ProgressView("Preparing photos…") }
                ForEach(photos) { photo in
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("Selected memory photo")
                }
                if !selection.isEmpty {
                    Button("Remove Photos", role: .destructive) {
                        selection = []
                        photos = []
                    }
                }
            }
            Section("Your Story") {
                TextField("Where did you go? What made it memorable?", text: $caption, axis: .vertical)
                    .lineLimit(4...10)
                Button(copiedCaption ? "Caption Copied" : "Copy Caption") {
                    UIPasteboard.general.string = caption
                    copiedCaption = true
                }
                .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section {
                Button {
                    share = MemoryShare(images: photos.map(\.image), caption: caption.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Label("Share Memory", systemImage: "square.and.arrow.up")
                }
                .disabled(loading || photos.isEmpty)
            } footer: {
                Text("Available apps depend on what's installed and what they support. Some apps don't accept captions—copy yours first and paste it there. This draft isn't saved after you leave this screen.")
            }
        }
        .navigationTitle("Share a Memory")
        .tint(TravelStyle.ink)
        .scrollDismissesKeyboard(.interactively)
        .task(id: selection) { await loadPhotos() }
        .onChange(of: caption) { copiedCaption = false }
        .sheet(item: $share) { item in MemoryShareSheet(share: item) }
        .alert("Couldn't Prepare Photos", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    private func loadPhotos() async {
        photos = []
        guard !selection.isEmpty else { loading = false; return }
        loading = true
        do {
            var loaded: [MemoryPhoto] = []
            for item in selection {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw AuthError.invalidResponse
                }
                try Task.checkCancellation()
                guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 2048
                      ] as CFDictionary) else { throw AuthError.invalidResponse }
                // Re-rendering avoids forwarding the original photo's location metadata.
                loaded.append(MemoryPhoto(image: UIImage(cgImage: thumbnail)))
            }
            try Task.checkCancellation()
            photos = loaded
            loading = false
        } catch is CancellationError {
            // A newer selection owns the loading state.
        } catch {
            guard !Task.isCancelled else { return }
            loading = false
            errorMessage = "Please try choosing your photos again. If they're stored in iCloud, check your connection."
        }
    }
}

private struct MemoryPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct MemoryShare: Identifiable {
    let id = UUID()
    let images: [UIImage]
    let caption: String
}

private struct MemoryShareSheet: UIViewControllerRepresentable {
    let share: MemoryShare

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = share.images
        if !share.caption.isEmpty { items.append(share.caption) }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
