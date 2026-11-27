import Foundation

struct Person: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var phone: String = ""
}

enum TxType: String, Codable, CaseIterable, Identifiable {
    case lent, repaidToMe, borrowed, repaidByMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lent: return tr("I lent", "ഞാൻ കടം കൊടുത്തു")
        case .repaidToMe: return tr("They paid me back", "അവർ തിരിച്ചു തന്നു")
        case .borrowed: return tr("I borrowed", "ഞാൻ കടം വാങ്ങി")
        case .repaidByMe: return tr("I paid back", "ഞാൻ തിരിച്ചു കൊടുത്തു")
        }
    }

    // + = അവർ എനിക്ക് തരാനുണ്ട്, − = ഞാൻ അവർക്ക് കൊടുക്കാനുണ്ട്
    var sign: Double {
        switch self {
        case .lent, .repaidByMe: return 1
        case .repaidToMe, .borrowed: return -1
        }
    }

    /// എൻ്റെ കയ്യിൽ നിന്ന് പണം പുറത്തേക്ക് പോകുന്നവ
    var isMoneyOut: Bool {
        self == .lent || self == .repaidByMe
    }

    var icon: String {
        isMoneyOut ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill"
    }
}

struct Txn: Identifiable, Codable, Hashable {
    var id = UUID()
    var personID: UUID
    var type: TxType
    var amount: Double
    var currency: String = "INR"
    var date: Date = Date()
    var note: String = ""
    var receiptFile: String? = nil

    var signedAmount: Double { amount * type.sign }

    enum CodingKeys: String, CodingKey {
        case id, personID, type, amount, currency, date, note, receiptFile
    }
}

// പഴയ ഡാറ്റയിൽ currency, receiptFile എന്നിവ ഇല്ല. അവയ്ക്ക് default നൽകുന്ന decoder.
extension Txn {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        personID = try c.decode(UUID.self, forKey: .personID)
        type = try c.decode(TxType.self, forKey: .type)
        amount = try c.decode(Double.self, forKey: .amount)
        currency = try c.decodeIfPresent(String.self, forKey: .currency) ?? "INR"
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        receiptFile = try c.decodeIfPresent(String.self, forKey: .receiptFile)
    }
}

func money(_ value: Double, _ code: String) -> String {
    value.formatted(.currency(code: code))
}

func currencyName(_ code: String) -> String {
    Locale.current.localizedString(forCurrencyCode: code) ?? code
}