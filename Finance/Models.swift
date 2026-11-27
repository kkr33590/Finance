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
        case .lent: return "ഞാൻ കടം കൊടുത്തു"
        case .repaidToMe: return "അവർ തിരിച്ചു തന്നു"
        case .borrowed: return "ഞാൻ കടം വാങ്ങി"
        case .repaidByMe: return "ഞാൻ തിരിച്ചു കൊടുത്തു"
        }
    }

    // + = അവർ എനിക്ക് തരാനുണ്ട്, − = ഞാൻ അവർക്ക് കൊടുക്കാനുണ്ട്
    var sign: Double {
        switch self {
        case .lent, .repaidByMe: return 1
        case .repaidToMe, .borrowed: return -1
        }
    }
}

struct Txn: Identifiable, Codable, Hashable {
    var id = UUID()
    var personID: UUID
    var type: TxType
    var amount: Double
    var date: Date = Date()
    var note: String = ""

    var signedAmount: Double { amount * type.sign }
}

func money(_ value: Double) -> String {
    value.formatted(.currency(code: "INR"))
}