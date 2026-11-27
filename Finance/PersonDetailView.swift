import SwiftUI

struct PersonDetailView: View {
    @EnvironmentObject var store: FinanceStore
    @AppStorage("appLanguage") private var lang = "ml"
    let personID: UUID
    @State private var showAdd = false

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
            Section {
                if balances.isEmpty {
                    Text(tr("Settled", "കണക്ക് തീർന്നു"))
                        .font(.headline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                ForEach(balances) { b in
                    VStack(spacing: 6) {
                        if b.amount > 0 {
                            Text("\(person.name) \(tr("owes you", "നിങ്ങൾക്ക് തരാനുള്ളത്"))")
                                .font(.caption).foregroundColor(.secondary)
                            Text(money(b.amount, b.code))
                                .font(.title).bold().foregroundColor(.green)
                        } else {
                            Text("\(tr("You owe", "നിങ്ങൾ കൊടുക്കാനുള്ളത്")) \(person.name)")
                                .font(.caption).foregroundColor(.secondary)
                            Text(money(-b.amount, b.code))
                                .font(.title).bold().foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            Section(tr("Entries", "എൻട്രികൾ")) {
                if list.isEmpty {
                    Text(tr("No entries", "എൻട്രി ഇല്ല")).foregroundColor(.secondary)
                }
                ForEach(list) { txn in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(txn.type.title)
                            Spacer()
                            Text(money(txn.amount, txn.currency))
                                .foregroundColor(txn.signedAmount > 0 ? .green : .red)
                        }
                        Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundColor(.secondary)
                        if !txn.note.isEmpty {
                            Text(txn.note).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    store.deleteTxns(at: offsets, from: list)
                }
            }
        }
        .navigationTitle(person.name)
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(personID: person.id)
        }
    }
}