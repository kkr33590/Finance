import SwiftUI

struct AddPersonView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("പേര്", text: $name)
                TextField("ഫോൺ (optional)", text: $phone)
                    .keyboardType(.phonePad)
            }
            .navigationTitle("പുതിയ ആൾ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("റദ്ദാക്കുക") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("സേവ്") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            store.addPerson(name: trimmed, phone: phone)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}