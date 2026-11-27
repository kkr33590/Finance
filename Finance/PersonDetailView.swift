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
                    .foregroundColor(.white)
            }
        }
        .background(GlowBackground())
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
                        .foregroundColor(Color.white.opacity(0.6))
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
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    store.deleteTxns(at: offsets, from: list)
                }
            } header: {
                HStack {
                    Text(tr("ENTRIES", "എൻട്രികൾ"))
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundColor(FinStyle.cyan)
                    Spacer()
                    Text("\(list.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .textCase(nil)
                .padding(.horizontal, 4)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(FinStyle.neon)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(personID: person.id)
        }
        .sheet(item: $selectedTxn) { txn in
            TransactionDetailView(txnID: txn.id)
        }
    }

    // MARK: - ഹെഡർ card

    private func header(person: Person, balances: [CurrencyBalance]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                AvatarView(name: person.name, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(FinFont.font(22))
                        .foregroundColor(.white)
                    if !person.phone.isEmpty {
                        Text(person.phone)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                Spacer()
            }

            if balances.isEmpty {
                Label(tr("All settled", "കണക്ക് തീർന്നു"), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(FinStyle.receive)
            }

            ForEach(balances) { b in
                let positive = b.amount > 0
                let color = positive ? FinStyle.receive : FinStyle.pay
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(b.code)
                            .font(.caption.weight(.bold))
                            .foregroundColor(FinStyle.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(FinStyle.cyan.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(FinStyle.cyan.opacity(0.5), lineWidth: 1))
                        Text(positive
                             ? "\(person.name) \(tr("owes you", "നിങ്ങൾക്ക് തരാനുള്ളത്"))"
                             : "\(tr("You owe", "നിങ്ങൾ കൊടുക്കാനുള്ളത്")) \(person.name)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    Text(money(abs(b.amount), b.code))
                        .font(FinFont.font(32))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowCardBackground())
        .shadow(color: FinStyle.neon.opacity(0.18), radius: 22, x: 0, y: 6)
    }

    // MARK: - എൻട്രി card

    private func entryRow(_ txn: Txn) -> some View {
        let color = txn.signedAmount > 0 ? FinStyle.receive : FinStyle.pay
        return HStack(spacing: 12) {
            Image(systemName: txn.type.icon)
                .font(.title2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(txn.type.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                    if txn.receiptFile != nil {
                        Image(systemName: "paperclip")
                            .foregroundColor(FinStyle.cyan)
                    }
                }
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.55))
                if !txn.note.isEmpty {
                    Text(txn.note)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(money(txn.amount, txn.currency))
                .font(FinFont.font(15))
                .foregroundColor(color)
        }
        .cardStyle()
    }
}