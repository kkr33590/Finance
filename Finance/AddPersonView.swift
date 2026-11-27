import SwiftUI

struct AddPersonView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "ml"

    @State private var name = ""
    @State private var phone = ""

    var body: some View {
        let _ = lang
        NavigationStack {
            Form {
                TextField(tr("Name", "പേര്"), text: $name)
                TextField(tr("Phone (optional)", "ഫോൺ (optional)"), text: $phone)
                    .keyboardType(.phonePad)
            }
            .navigationTitle(tr("New person", "പുതിയ ആൾ"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel", "റദ്ദാക്കുക")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save", "സേവ്")) {
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