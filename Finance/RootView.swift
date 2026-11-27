import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: FinanceStore
    @AppStorage("appLanguage") private var lang = "ml"
    @State private var showAddPerson = false
    @State private var showSettings = false
    @State private var query = ""

    private var filteredPeople: [Person] {
        let sorted = store.people.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        if query.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        let _ = lang
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    heroCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    Section {
                        if store.people.isEmpty {
                            emptyState
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(filteredPeople) { person in
                            ZStack {
                                NavigationLink(value: person) { EmptyView() }
                                    .opacity(0)
                                personRow(person)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            store.deletePeople(at: offsets, from: filteredPeople)
                        }
                    } header: {
                        Text(tr("People", "ആളുകൾ"))
                            .font(.headline)
                            .textCase(nil)
                            .foregroundColor(.primary)
                    }

                    Color.clear
                        .frame(height: 70)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .searchable(text: $query, prompt: tr("Search people", "ആളുകളെ തിരയുക"))

                addButton
            }
            .navigationTitle("Finance")
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(personID: person.id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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

    // MARK: - മുകളിലെ balance card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("Total balance", "ആകെ ബാക്കി"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.8))
                    Text("\(store.people.count) \(tr("people", "ആളുകൾ"))")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .font(.title2)
                    .foregroundColor(Color.white.opacity(0.85))
            }

            if store.totals.isEmpty {
                Text(tr("No balances yet", "ബാക്കി തുക ഒന്നുമില്ല"))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
            }

            ForEach(store.totals) { t in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(t.code)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                        Text(currencyName(t.code))
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(1)
                        Spacer()
                        Text("\(tr("Net", "നെറ്റ്")) \(money(t.toReceive - t.toPay, t.code))")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        heroColumn(icon: "arrow.down.left.circle.fill",
                                   title: tr("To receive", "കിട്ടാനുള്ളത്"),
                                   value: t.toReceive, code: t.code, color: FinStyle.heroReceive)
                        heroColumn(icon: "arrow.up.right.circle.fill",
                                   title: tr("To pay", "കൊടുക്കാനുള്ളത്"),
                                   value: t.toPay, code: t.code, color: FinStyle.heroPay)
                    }
                }
                if t.id != store.totals.last?.id {
                    Divider().overlay(Color.white.opacity(0.2))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FinStyle.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(red: 0.07, green: 0.12, blue: 0.30).opacity(0.35), radius: 14, x: 0, y: 8)
    }

    private func heroColumn(icon: String, title: String, value: Double,
                            code: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            Text(money(value, code))
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ആളുടെ card

    private func personRow(_ person: Person) -> some View {
        let list = store.transactions(for: person)
        let count = list.count
        return HStack(spacing: 12) {
            AvatarView(name: person.name)
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name).font(.headline)
                Text(subtitle(count: count, last: list.first?.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            balanceColumn(for: person)
        }
        .cardStyle()
    }

    private func subtitle(count: Int, last: Date?) -> String {
        if count == 0 { return tr("No entries", "എൻട്രി ഇല്ല") }
        let entries = "\(count) \(tr("entries", "എൻട്രികൾ"))"
        if let last = last {
            return "\(entries) • \(last.formatted(date: .abbreviated, time: .omitted))"
        }
        return entries
    }

    @ViewBuilder
    private func balanceColumn(for person: Person) -> some View {
        let balances = store.balances(for: person)
        if balances.isEmpty {
            Label(tr("Settled", "തീർന്നു"), systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(balances) { b in
                    let positive = b.amount > 0
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(money(abs(b.amount), b.code))
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(positive ? FinStyle.receive : FinStyle.pay)
                        Text(positive ? tr("to receive", "കിട്ടാനുള്ളത്") : tr("to pay", "കൊടുക്കാനുള്ളത്"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(tr("No people yet. Tap the + button to add one.",
                    "ആരും ഇല്ല. താഴെയുള്ള + അമർത്തി ഒരാളെ ചേർക്കുക."))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var addButton: some View {
        Button {
            showAddPerson = true
        } label: {
            Image(systemName: "person.badge.plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(FinStyle.accent)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
        .padding(20)
    }
}