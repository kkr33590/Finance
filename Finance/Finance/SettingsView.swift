import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "ml"
    @AppStorage("defaultCurrency") private var defaultCurrency = "INR"

    var body: some View {
        let _ = lang
        NavigationStack {
            Form {
                Section(tr("Language", "ഭാഷ")) {
                    Picker(tr("Language", "ഭാഷ"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { l in
                            Text(l.label).tag(l.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section(tr("Default currency", "സ്ഥിര കറൻസി")) {
                    NavigationLink {
                        CurrencyPickerView(selection: $defaultCurrency)
                    } label: {
                        HStack {
                            Text(currencyName(defaultCurrency))
                            Spacer()
                            Text(defaultCurrency).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(tr("Settings", "സെറ്റിങ്സ്"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Done", "ശരി")) { dismiss() }
                }
            }
        }
    }
}