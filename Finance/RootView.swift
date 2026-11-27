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
                VStack(spacing: 0) {
                    header

                    List {
                        heroCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        searchField
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 10, trailing: 16))
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
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { offsets in
                                store.deletePeople(at: offsets, from: filteredPeople)
                            }
                        } header: {
                            HStack {
                                Text(tr("PEOPLE", "ആളുകൾ"))
                                    .font(FinFont.caption)
                                    .tracking(1.2)
                                    .foregroundColor(FinStyle.cyan)
                                Spacer()
                                Text("\(store.people.count)")
                                    .font(FinFont.caption)
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            .textCase(nil)
                            .padding(.horizontal, 4)
                        }

                        Color.clear
                            .frame(height: 80)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }

                addButton
            }
            .background(GlowBackground())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(personID: person.id)
            }
            .sheet(isPresented: $showAddPerson) {
                AddPersonView()
                    .font(FinFont.body)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .font(FinFont.body)
            }
        }
    }

    // MARK: - ഹെഡർ

    private var header: some View {
        HStack {
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(FinStyle.neon)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    // MARK: - ബാലൻസ് card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(tr("TOTAL BALANCE", "ആകെ ബാക്കി"))
                    .font(FinFont.caption)
                    .tracking(1.2)
                    .foregroundColor(FinStyle.cyan)
                Spacer()
                Label("\(store.people.count)", systemImage: "person.2.fill")
                    .font(FinFont.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }

            if store.totals.isEmpty {
                Text(tr("No balances yet", "ബാക്കി തുക ഒന്നുമില്ല"))
                    .font(FinFont.title3)
                    .foregroundColor(.white)
            }

            ForEach(store.totals) { t in
                currencyBlock(t)
                if t.id != store.totals.last?.id {
                    Divider().overlay(Color.white.opacity(0.10))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowCardBackground())
        .shadow(color: FinStyle.neon.opacity(0.18), radius: 22, x: 0, y: 6)
    }

    private func currencyBlock(_ t: CurrencyTotal) -> some View {
        let net = t.toReceive - t.toPay
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(t.code)
                    .font(FinFont.caption)
                    .foregroundColor(FinStyle.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FinStyle.cyan.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(FinStyle.cyan.opacity(0.5), lineWidth: 1))
                Text(currencyName(t.code))
                    .font(FinFont.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineLimit(1)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tr("Net balance", "നെറ്റ് ബാക്കി"))
                    .font(FinFont.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                Text(money(net, t.code))
                    .font(FinFont.font(32))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            HStack(spacing: 10) {
                statTile(icon: "arrow.down.left",
                         title: tr("To receive", "കിട്ടാനുള്ളത്"),
                         value: t.toReceive, code: t.code, color: FinStyle.receive)
                statTile(icon: "arrow.up.right",
                         title: tr("To pay", "കൊടുക്കാനുള്ളത്"),
                         value: t.toPay, code: t.code, color: FinStyle.pay)
            }
        }
    }

    private func statTile(icon: String, title: String, value: Double,
                          code: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(FinFont.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            Text(money(value, code))
                .font(FinFont.font(18))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(FinStyle.neon)
            TextField(tr("Search people", "ആളുകളെ തിരയുക"), text: $query)
                .font(FinFont.body)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - ആളുടെ card

    private func personRow(_ person: Person) -> some View {
        let list = store.transactions(for: person)
        return HStack(spacing: 12) {
            AvatarView(name: person.name)
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(FinFont.headline)
                    .foregroundColor(.white)
                Text(subtitle(count: list.count, last: list.first?.date))
                    .font(FinFont.caption)
                    .foregroundColor(Color.white.opacity(0.55))
            }
            Spacer()
            balanceColumn(for: person)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.3))
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
                .font(FinFont.caption)
                .foregroundColor(Color.white.opacity(0.5))
        } else {
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(balances) { b in
                    let positive = b.amount > 0
                    let color = positive ? FinStyle.receive : FinStyle.pay
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(money(abs(b.amount), b.code))
                            .font(FinFont.subheadline)
                            .foregroundColor(color)
                        Text(positive ? tr("to receive", "കിട്ടാനുള്ളത്") : tr("to pay", "കൊടുക്കാനുള്ളത്"))
                            .font(FinFont.caption2)
                            .foregroundColor(color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.largeTitle)
                .foregroundColor(FinStyle.neon)
            Text(tr("No people yet. Tap the button below to add one.",
                    "ആരും ഇല്ല. താഴെയുള്ള ബട്ടൺ അമർത്തി ഒരാളെ ചേർക്കുക."))
                .font(FinFont.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: - Add ബട്ടൺ (shadow ഇല്ല)

    private var addButton: some View {
        Button {
            showAddPerson = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                Text(tr("Add person", "ആളെ ചേർക്കുക"))
            }
            .font(FinFont.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(FinStyle.accent)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }
}