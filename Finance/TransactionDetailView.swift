import SwiftUI
import UIKit

struct FullScreenItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct TransactionDetailView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "ml"

    let txnID: UUID
    @State private var newImage: UIImage?
    @State private var fullItem: FullScreenItem?

    private var txn: Txn? {
        store.txns.first { $0.id == txnID }
    }

    var body: some View {
        let _ = lang
        NavigationStack {
            Group {
                if let txn = txn {
                    content(txn)
                } else {
                    Text(tr("Entry not found", "എൻട്രി കണ്ടില്ല"))
                }
            }
            .navigationTitle(tr("Entry", "എൻട്രി"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Done", "ശരി")) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ txn: Txn) -> some View {
        Form {
            Section {
                HStack {
                    Text(tr("Type", "തരം"))
                    Spacer()
                    Text(txn.type.title).foregroundColor(.secondary)
                }
                HStack {
                    Text(tr("Amount", "തുക"))
                    Spacer()
                    Text(money(txn.amount, txn.currency))
                        .bold()
                        .foregroundColor(txn.signedAmount > 0 ? FinStyle.receive : FinStyle.pay)
                }
                HStack {
                    Text(tr("Date", "തീയതി"))
                    Spacer()
                    Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
                if !txn.note.isEmpty {
                    HStack(alignment: .top) {
                        Text(tr("Note", "കുറിപ്പ്"))
                        Spacer()
                        Text(txn.note).foregroundColor(.secondary).multilineTextAlignment(.trailing)
                    }
                }
            }

            Section(tr("Receipt", "റെസിപ്റ്റ്")) {
                if let name = txn.receiptFile, let img = ReceiptStorage.load(name) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .frame(maxWidth: .infinity)
                        .onTapGesture { fullItem = FullScreenItem(image: img) }

                    ShareLink(item: Image(uiImage: img),
                              preview: SharePreview(tr("Receipt", "റെസിപ്റ്റ്"),
                                                    image: Image(uiImage: img))) {
                        Label(tr("Share", "ഷെയർ"), systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        store.setReceipt(txn.id, nil)
                    } label: {
                        Label(tr("Remove receipt", "റെസിപ്റ്റ് മാറ്റുക"), systemImage: "trash")
                    }
                } else {
                    ReceiptPicker(image: $newImage)
                }
            }
        }
        .onChange(of: newImage) { img in
            if let img = img, let file = ReceiptStorage.save(img) {
                store.setReceipt(txn.id, file)
                newImage = nil
            }
        }
        .fullScreenCover(item: $fullItem) { item in
            ReceiptFullView(image: item.image)
        }
    }
}

struct ReceiptFullView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1, lastScale * value)
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale == 1 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 {
                                offset = CGSize(width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height)
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(Color.white.opacity(0.9))
                    .padding()
            }
        }
    }
}