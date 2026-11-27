import SwiftUI

struct PersonDetailView: View {
    @EnvironmentObject var store: FinanceStore
    @AppStorage("appLanguage") private var lang = "ml"
    let personID: UUID
    @State private var showAdd = false
    @State private var selectedTxn: Txn?

    private var person: Person? {
        store.people.first { $0.id == personID }
    }

    var body: some View {
        let _ = lang
        Group {
            if let person = person {
                content(for: person)
            } else {
                Text(tr("Person not found", "ആളെ കണ്ടില്ല"))
            }
        }
    }

    @ViewBuilder
    private func content(for person: Person) -> some View {
        let balances = store.balances(for: person)
        let list = store.transactions(for: person)

        List {
            header(person: person, balances: balances)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            Section {
                if list.isEmpty {
                    Text(tr("No entries yet. Tap + to add one.",
                            "എൻട്രി ഇല്ല. + അമർത്തി ചേർക്കുക."))
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                ForEach(list) { txn in
                    Button {
                        selectedTxn = txn
                    } label: {
                        entryRow(txn)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    store.deleteTxns(at: offsets, from: list)
                }
            } header: {
                Text(tr("Entries", "എൻട്രികൾ"))
                    .font(.headline)
                    .textCase(nil)
                    .foregroundColor(.primary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(personID: person.id)
        }
        .sheet(item: $selectedTxn) { txn in
            TransactionDetailView(txnID: txn.id)
        }
    }

    private func header(person: Person, balances: [CurrencyBalance]) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                AvatarView(name: person.name, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    if !person.phone.isEmpty {
                        Text(person.phone)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                Spacer()
            }

            if balances.isEmpty {
                Label(tr("All settled", "കണക്ക് തീർന്നു"), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(balances) { b in
                let positive = b.amount > 0
                VStack(alignment: .leading, spacing: 2) {
                    Text(positive
                         ? "\(person.name) \(tr("owes you", "നിങ്ങൾക്ക് തരാനുള്ളത്"))"
                         : "\(tr("You owe", "നിങ്ങൾ കൊടുക്കാനുള്ളത്")) \(person.name)")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.75))
                    Text(money(abs(b.amount), b.code))
                        .font(.title.weight(.bold))
                        .foregroundColor(positive ? FinStyle.heroReceive : FinStyle.heroPay)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(FinStyle.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(red: 0.07, green: 0.12, blue: 0.30).opacity(0.35), radius: 14, x: 0, y: 8)
    }

    private func entryRow(_ txn: Txn) -> some View {
        let color = txn.signedAmount > 0 ? FinStyle.receive : FinStyle.pay
        return HStack(spacing: 12) {
            Image(systemName: txn.type.icon)
                .font(.title2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(txn.type.title).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                    if txn.receiptFile != nil {
                        Image(systemName: "paperclip")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if !txn.note.isEmpty {
                    Text(txn.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(money(txn.amount, txn.currency))
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
        }
        .cardStyle()
    }
}