import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "ml"
    @State private var search = ""

    private let common = ["INR", "SAR", "AED", "USD", "EUR", "GBP", "QAR", "KWD", "OMR", "BHD"]
    private let all: [String] = Locale.commonISOCurrencyCodes.sorted()

    private func matches(_ code: String) -> Bool {
        search.isEmpty
            || code.localizedCaseInsensitiveContains(search)
            || currencyName(code).localizedCaseInsensitiveContains(search)
    }

    var body: some View {
        let _ = lang
        List {
            if search.isEmpty {
                Section(tr("Common", "സാധാരണ ഉപയോഗിക്കുന്നവ")) {
                    ForEach(common, id: \.self) { row($0) }
                }
            }
            Section(tr("All currencies", "എല്ലാ കറൻസികളും")) {
                ForEach(all.filter(matches), id: \.self) { row($0) }
            }
        }
        .navigationTitle(tr("Currency", "കറൻസി"))
        .searchable(text: $search)
    }

    private func row(_ code: String) -> some View {
        Button {
            selection = code
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(code).bold()
                    Text(currencyName(code)).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if selection == code {
                    Image(systemName: "checkmark")
                }
            }
        }
        .foregroundColor(.primary)
    }
}