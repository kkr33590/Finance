import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "ml"

    let personID: UUID
    @State private var type: TxType = .lent
    @State private var amountText = ""
    @State private var currency: String
    @State private var date = Date()
    @State private var note = ""

    init(personID: UUID) {
        self.personID = personID
        let saved = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "INR"
        _currency = State(initialValue: saved)
    }

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        let _ = lang
        NavigationStack {
            Form {
                Section(tr("Type", "തരം")) {
                    Picker(tr("Type", "തരം"), selection: $type) {
                        ForEach(TxType.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section(tr("Amount", "തുക")) {
                    TextField(tr("Amount", "തുക"), text: $amountText)
                        .keyboardType(.decimalPad)
                    NavigationLink {
                        CurrencyPickerView(selection: $currency)
                    } label: {
                        HStack {
                            Text(tr("Currency", "കറൻസി"))
                            Spacer()
                            Text(currency).foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    DatePicker(tr("Date", "തീയതി"), selection: $date, displayedComponents: .date)
                    TextField(tr("Note (optional)", "കുറിപ്പ് (optional)"), text: $note)
                }
            }
            .navigationTitle(tr("New entry", "പുതിയ എൻട്രി"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel", "റദ്ദാക്കുക")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save", "സേവ്")) {
                        if let amount = amount, amount > 0 {
                            store.addTxn(Txn(personID: personID, type: type,
                                             amount: amount, currency: currency,
                                             date: date, note: note))
                            dismiss()
                        }
                    }
                    .disabled((amount ?? 0) <= 0)
                }
            }
        }
    }
}