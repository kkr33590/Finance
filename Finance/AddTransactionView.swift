import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let personID: UUID
    @State private var type: TxType = .lent
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("തരം") {
                    Picker("തരം", selection: $type) {
                        ForEach(TxType.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("തുക") {
                    TextField("തുക", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    DatePicker("തീയതി", selection: $date, displayedComponents: .date)
                    TextField("കുറിപ്പ് (optional)", text: $note)
                }
            }
            .navigationTitle("പുതിയ എൻട്രി")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("റദ്ദാക്കുക") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("സേവ്") {
                        if let amount = amount, amount > 0 {
                            store.addTxn(Txn(personID: personID, type: type,
                                             amount: amount, date: date, note: note))
                            dismiss()
                        }
                    }
                    .disabled((amount ?? 0) <= 0)
                }
            }
        }
    }
}