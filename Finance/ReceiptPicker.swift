import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

/// റെസിപ്റ്റ് ചേർക്കാനുള്ള 3 വഴികൾ: Photos, Files, Paste
struct ReceiptPicker: View {
    @Binding var image: UIImage?
    @AppStorage("appLanguage") private var lang = "ml"
    @State private var photoItem: PhotosPickerItem?
    @State private var showFiles = false
    @State private var message: String?

    var body: some View {
        let _ = lang
        VStack(spacing: 12) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button(role: .destructive) {
                    self.image = nil
                } label: {
                    Label(tr("Remove receipt", "റെസിപ്റ്റ് മാറ്റുക"), systemImage: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            } else {
                HStack(spacing: 10) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        tile(tr("Photos", "ഫോട്ടോസ്"), "photo.on.rectangle")
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFiles = true
                    } label: {
                        tile(tr("Files", "ഫയലുകൾ"), "folder")
                    }
                    .buttonStyle(.plain)

                    Button {
                        pasteFromClipboard()
                    } label: {
                        tile(tr("Paste", "പേസ്റ്റ്"), "doc.on.clipboard")
                    }
                    .buttonStyle(.plain)
                }
            }

            if let message = message {
                Text(message).font(FinFont.caption).foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: photoItem) { item in
            loadPhoto(item)
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image, .pdf]) { result in
            switch result {
            case .success(let url):
                if let ui = ReceiptStorage.image(fromFile: url) {
                    image = ui
                    message = nil
                } else {
                    message = tr("Could not read this file", "ഈ ഫയൽ വായിക്കാൻ പറ്റിയില്ല")
                }
            case .failure:
                message = tr("Could not open the file", "ഫയൽ തുറക്കാൻ പറ്റിയില്ല")
            }
        }
    }

    private func tile(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3)
            Text(title).font(FinFont.caption).multilineTextAlignment(.center)
        }
        .foregroundColor(.accentColor)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(Color.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pasteFromClipboard() {
        if let ui = UIPasteboard.general.image {
            image = ui
            message = nil
        } else {
            message = tr("No image copied. Copy a screenshot or photo first.",
                         "ഇമേജ് കോപ്പി ചെയ്തിട്ടില്ല. ആദ്യം സ്ക്രീൻഷോട്ടോ ഫോട്ടോയോ കോപ്പി ചെയ്യുക.")
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run {
                if let data = data, let ui = UIImage(data: data) {
                    image = ui
                    message = nil
                } else {
                    message = tr("Could not load the photo", "ഫോട്ടോ ലോഡ് ചെയ്യാൻ പറ്റിയില്ല")
                }
                photoItem = nil
            }
        }
    }
}