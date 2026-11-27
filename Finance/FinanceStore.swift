import Foundation

struct CurrencyBalance: Identifiable {
    let code: String
    let amount: Double
    var id: String { code }
}

struct CurrencyTotal: Identifiable {
    let code: String
    var toReceive: Double
    var toPay: Double
    var id: String { code }
}

final class FinanceStore: ObservableObject {
    @Published var people: [Person] = [] { didSet { save() } }
    @Published var txns: [Txn] = [] { didSet { save() } }

    private struct Saved: Codable {
        var people: [Person]
        var txns: [Txn]
    }

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("finance.json")
    }

    init() { load() }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(Saved.self, from: data)
        else { return }
        people = saved.people
        txns = saved.txns
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(Saved(people: people, txns: txns))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    // MARK: - കണക്കുകൾ

    func balances(for person: Person) -> [CurrencyBalance] {
        var dict: [String: Double] = [:]
        for t in txns where t.personID == person.id {
            dict[t.currency, default: 0] += t.signedAmount
        }
        return dict
            .filter { abs($0.value) > 0.005 }
            .map { CurrencyBalance(code: $0.key, amount: $0.value) }
            .sorted { $0.code < $1.code }
    }

    func transactions(for person: Person) -> [Txn] {
        txns.filter { $0.personID == person.id }
            .sorted { $0.date > $1.date }
    }

    var totals: [CurrencyTotal] {
        var dict: [String: CurrencyTotal] = [:]
        for person in people {
            for b in balances(for: person) {
                var t = dict[b.code] ?? CurrencyTotal(code: b.code, toReceive: 0, toPay: 0)
                if b.amount > 0 {
                    t.toReceive += b.amount
                } else {
                    t.toPay += -b.amount
                }
                dict[b.code] = t
            }
        }
        return dict.values.sorted { $0.code < $1.code }
    }

    // MARK: - മാറ്റങ്ങൾ

    func addPerson(name: String, phone: String) {
        people.append(Person(name: name, phone: phone))
    }

    func deletePeople(at offsets: IndexSet, from list: [Person]) {
        let ids = offsets.map { list[$0].id }
        for t in txns where ids.contains(t.personID) {
            ReceiptStorage.delete(t.receiptFile)
        }
        txns.removeAll { ids.contains($0.personID) }
        people.removeAll { ids.contains($0.id) }
    }

    func addTxn(_ txn: Txn) {
        txns.append(txn)
    }

    func deleteTxns(at offsets: IndexSet, from list: [Txn]) {
        let ids = offsets.map { list[$0].id }
        for t in txns where ids.contains(t.id) {
            ReceiptStorage.delete(t.receiptFile)
        }
        txns.removeAll { ids.contains($0.id) }
    }

    /// ഒരു എൻട്രിയുടെ റെസിപ്റ്റ് മാറ്റുന്നു (nil = റെസിപ്റ്റ് നീക്കം ചെയ്യുക)
    func setReceipt(_ txnID: UUID, _ fileName: String?) {
        guard let i = txns.firstIndex(where: { $0.id == txnID }) else { return }
        ReceiptStorage.delete(txns[i].receiptFile)
        txns[i].receiptFile = fileName
    }
}