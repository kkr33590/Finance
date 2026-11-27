import SwiftUI

struct PersonDetailView: View {
    @EnvironmentObject var store: FinanceStore
    let personID: UUID
    @State private var showAdd = false

    private var person: Person? {
        store.people.first { $0.id == personID }
    }

    var body: some View {
        Group {
            if let person = person {
                content(for: person)
            } else {
                Text("ആളെ കണ്ടില്ല")
            }
        }
    }

    @ViewBuilder
    private func content(for person: Person) -> some View {
        let balance = store.balance(for: person)
        let list = store.transactions(for: person)

        List {
            Section {
                VStack(spacing: 6) {
                    if balance > 0 {
                        Text("\(person.name) നിങ്ങൾക്ക് തരാനുള്ളത്")
                            .font(.caption).foregroundColor(.secondary)
                        Text(money(balance)).font(.title).bold().foregroundColor(.green)
                    } else if balance < 0 {
                        Text("നിങ്ങൾ \(person.name)-ന് കൊടുക്കാനുള്ളത്")
                            .font(.caption).foregroundColor(.secondary)
                        Text(money(-balance)).font(.title).bold().foregroundColor(.red)
                    } else {
                        Text("കണക്ക് തീർന്നു").font(.headline).foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("എൻട്രികൾ") {
                if list.isEmpty {
                    Text("എൻട്രി ഇല്ല").foregroundColor(.secondary)
                }
                ForEach(list) { txn in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(txn.type.title)
                            Spacer()
                            Text(money(txn.amount))
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