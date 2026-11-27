import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: FinanceStore
    @AppStorage("appLanguage") private var lang = "ml"
    @State private var showAddPerson = false
    @State private var showSettings = false

    private var sortedPeople: [Person] {
        store.people.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        let _ = lang
        NavigationStack {
            List {
                Section(tr("Summary", "ആകെ കണക്ക്")) {
                    if store.totals.isEmpty {
                        Text(tr("No balances yet", "ബാക്കി തുക ഒന്നുമില്ല"))
                            .foregroundColor(.secondary)
                    }
                    ForEach(store.totals) { t in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(t.code) – \(currencyName(t.code))")
                                .font(.caption).foregroundColor(.secondary)
                            HStack {
                                summaryBox(title: tr("To receive", "എനിക്ക് കിട്ടാനുള്ളത്"),
                                           value: t.toReceive, code: t.code, color: .green)
                                Divider()
                                summaryBox(title: tr("To pay", "ഞാൻ കൊടുക്കാനുള്ളത്"),
                                           value: t.toPay, code: t.code, color: .red)
                            }
                        }
                    }
                }

                Section(tr("People", "ആളുകൾ")) {
                    if store.people.isEmpty {
                        Text(tr("No people yet. Tap + to add one.",
                                "ആരും ഇല്ല. മുകളിലെ + അമർത്തി ഒരാളെ ചേർക്കുക."))
                            .foregroundColor(.secondary)
                    }
                    ForEach(sortedPeople) { person in
                        NavigationLink(value: person) {
                            HStack(alignment: .top) {
                                Text(person.name)
                                Spacer()
                                balanceLines(for: person)
                            }
                        }
                    }
                    .onDelete { offsets in
                        store.deletePeople(at: offsets, from: sortedPeople)
                    }
                }
            }
            .navigationTitle("Finance")
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(personID: person.id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPerson = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPerson) {
                AddPersonView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private func summaryBox(title: String, value: Double, code: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(money(value, code)).font(.headline).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func balanceLines(for person: Person) -> some View {
        let balances = store.balances(for: person)
        if balances.isEmpty {
            Text(tr("Settled", "കണക്ക് തീർന്നു"))
                .foregroundColor(.secondary).font(.subheadline)
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(balances) { b in
                    if b.amount > 0 {
                        Text("\(tr("To receive", "കിട്ടാനുള്ളത്")) \(money(b.amount, b.code))")
                            .foregroundColor(.green).font(.subheadline)
                    } else {
                        Text("\(tr("To pay", "കൊടുക്കാനുള്ളത്")) \(money(-b.amount, b.code))")
                            .foregroundColor(.red).font(.subheadline)
                    }
                }
            }
        }
    }
}