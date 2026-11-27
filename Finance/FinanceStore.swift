import Foundation

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

    func balance(for person: Person) -> Double {
        txns.filter { $0.personID == person.id }
            .reduce(0) { $0 + $1.signedAmount }
    }

    func transactions(for person: Person) -> [Txn] {
        txns.filter { $0.personID == person.id }
            .sorted { $0.date > $1.date }
    }

    var totalToReceive: Double {
        people.map { balance(for: $0) }.filter { $0 > 0 }.reduce(0, +)
    }

    var totalToPay: Double {
        -people.map { balance(for: $0) }.filter { $0 < 0 }.reduce(0, +)
    }

    // MARK: - മാറ്റങ്ങൾ

    func addPerson(name: String, phone: String) {
        people.append(Person(name: name, phone: phone))
    }

    func deletePeople(at offsets: IndexSet, from list: [Person]) {
        let ids = offsets.map { list[$0].id }
        txns.removeAll { ids.contains($0.personID) }
        people.removeAll { ids.contains($0.id) }
    }

    func addTxn(_ txn: Txn) {
        txns.append(txn)
    }

    func deleteTxns(at offsets: IndexSet, from list: [Txn]) {
        let ids = offsets.map { list[$0].id }
        txns.removeAll { ids.contains($0.id) }
    }
}