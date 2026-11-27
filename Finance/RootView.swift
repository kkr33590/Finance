import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: FinanceStore
    @State private var showAddPerson = false

    private var sortedPeople: [Person] {
        store.people.sorted {
            abs(store.balance(for: $0)) > abs(store.balance(for: $1))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        summaryBox(title: "എനിക്ക് കിട്ടാനുള്ളത്",
                                   value: store.totalToReceive, color: .green)
                        Divider()
                        summaryBox(title: "ഞാൻ കൊടുക്കാനുള്ളത്",
                                   value: store.totalToPay, color: .red)
                    }
                }

                Section("ആളുകൾ") {
                    if store.people.isEmpty {
                        Text("ആരും ഇല്ല. മുകളിലെ + അമർത്തി ഒരാളെ ചേർക്കുക.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(sortedPeople) { person in
                        NavigationLink(value: person) {
                            HStack {
                                Text(person.name)
                                Spacer()
                                balanceLabel(store.balance(for: person))
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
                Button {
                    showAddPerson = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddPerson) {
                AddPersonView()
            }
        }
    }

    private func summaryBox(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(money(value)).font(.headline).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func balanceLabel(_ value: Double) -> some View {
        if value > 0 {
            Text("കിട്ടാനുള്ളത് \(money(value))").foregroundColor(.green).font(.subheadline)
        } else if value < 0 {
            Text("കൊടുക്കാനുള്ളത് \(money(-value))").foregroundColor(.red).font(.subheadline)
        } else {
            Text("കണക്ക് തീർന്നു").foregroundColor(.secondary).font(.subheadline)
        }
    }
}