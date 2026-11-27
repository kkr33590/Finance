import SwiftUI
import Combine

enum SyncError: LocalizedError {
    case encode
    case noBackup
    case badBackup

    var errorDescription: String? {
        switch self {
        case .encode:
            return tr("Could not prepare data", "ഡാറ്റ തയ്യാറാക്കാൻ പറ്റിയില്ല")
        case .noBackup:
            return tr("No backup found in Google Drive", "Google Drive-ൽ ബാക്കപ്പ് കണ്ടില്ല")
        case .badBackup:
            return tr("The backup file is damaged", "ബാക്കപ്പ് ഫയൽ കേടായിരിക്കുന്നു")
        }
    }
}

@MainActor
final class CloudSync: ObservableObject {
    @Published var isSignedIn = false
    @Published var email = ""
    @Published var isBusy = false
    @Published var errorText: String?
    @Published var lastBackup: Date?
    /// ഫോണിലും ക്ലൗഡിലും ഡാറ്റ ഉണ്ടെങ്കിൽ ഏത് ഉപയോഗിക്കണമെന്ന് ചോദിക്കാൻ
    @Published var conflict = false
    @Published var autoBackup: Bool {
        didSet { UserDefaults.standard.set(autoBackup, forKey: "autoBackup") }
    }

    private let auth = GoogleAuth()
    private weak var store: FinanceStore?
    private var cancellable: AnyCancellable?
    private let backupName = "finance.json"

    init() {
        autoBackup = UserDefaults.standard.object(forKey: "autoBackup") as? Bool ?? true
        lastBackup = UserDefaults.standard.object(forKey: "lastBackup") as? Date
        isSignedIn = auth.hasRefreshToken
        email = auth.email ?? ""
    }

    /// ഡാറ്റ മാറിയാൽ 4 സെക്കൻഡ് കഴിഞ്ഞ് ഓട്ടോ ബാക്കപ്പ്
    func attach(_ store: FinanceStore) {
        guard self.store == nil else { return }
        self.store = store
        cancellable = NotificationCenter.default
            .publisher(for: .financeDidChange)
            .debounce(for: .seconds(4), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { await self.autoBackupIfNeeded() }
            }
    }

    private func autoBackupIfNeeded() async {
        guard autoBackup, isSignedIn, !conflict else { return }
        await backup()
    }

    // MARK: - സൈൻ-ഇൻ / ഔട്ട്

    func signIn() async {
        errorText = nil
        do {
            try await auth.signIn()
            isSignedIn = true
            email = auth.email ?? ""
            await resolveAfterSignIn()
        } catch AuthError.cancelled {
            // ഉപയോക്താവ് റദ്ദാക്കി, ഒന്നും ചെയ്യേണ്ട
        } catch {
            handle(error)
        }
    }

    func signOut() {
        auth.signOut()
        isSignedIn = false
        email = ""
        conflict = false
        errorText = nil
    }

    /// ലോഗിൻ കഴിഞ്ഞ ഉടൻ: ക്ലൗഡിൽ ബാക്കപ്പ് ഉണ്ടോ എന്ന് നോക്കി ശരിയായ കാര്യം ചെയ്യുന്നു
    private func resolveAfterSignIn() async {
        guard let store = store else { return }
        do {
            let token = try await auth.validAccessToken()
            let files = try await DriveAPI.list(token: token)
            let hasRemote = files.contains { $0.name == backupName }
            let localEmpty = store.people.isEmpty && store.txns.isEmpty
            if hasRemote && localEmpty {
                await restore()
            } else if hasRemote {
                conflict = true
            } else {
                await backup()
            }
        } catch {
            handle(error)
        }
    }

    func useCloudData() async {
        conflict = false
        await restore()
    }

    func useThisPhone() async {
        conflict = false
        await backup(force: true)
    }

    // MARK: - ബാക്കപ്പ്

    func backup(force: Bool = false) async {
        guard let store = store, isSignedIn, !isBusy else { return }
        isBusy = true
        errorText = nil
        defer { isBusy = false }
        do {
            let token = try await auth.validAccessToken()
            let files = try await DriveAPI.list(token: token)
            let existing = files.first { $0.name == backupName }
            let localEmpty = store.people.isEmpty && store.txns.isEmpty

            if existing != nil && localEmpty && !force {
                errorText = tr("This phone has no data. Use Restore instead.",
                               "ഈ ഫോണിൽ ഡാറ്റ ഇല്ല. പകരം Restore ഉപയോഗിക്കുക.")
                return
            }

            guard let json = store.exportJSON() else { throw SyncError.encode }
            try await DriveAPI.upload(token: token, name: backupName, data: json,
                                      mime: "application/json", existingID: existing?.id)

            let remoteNames = Set(files.map { $0.name })
            for name in store.receiptFileNames() where !remoteNames.contains(name) {
                if let data = ReceiptStorage.data(for: name) {
                    try await DriveAPI.upload(token: token, name: name, data: data,
                                              mime: "image/jpeg", existingID: nil)
                }
            }

            let now = Date()
            lastBackup = now
            UserDefaults.standard.set(now, forKey: "lastBackup")
        } catch {
            handle(error)
        }
    }

    // MARK: - Restore

    func restore() async {
        guard let store = store, isSignedIn, !isBusy else { return }
        isBusy = true
        errorText = nil
        defer { isBusy = false }
        do {
            let token = try await auth.validAccessToken()
            let files = try await DriveAPI.list(token: token)
            guard let file = files.first(where: { $0.name == backupName }) else {
                throw SyncError.noBackup
            }
            let data = try await DriveAPI.download(token: token, id: file.id)
            guard store.replaceAll(from: data) else { throw SyncError.badBackup }

            for name in store.receiptFileNames() where !ReceiptStorage.exists(name) {
                if let remote = files.first(where: { $0.name == name }) {
                    let image = try await DriveAPI.download(token: token, id: remote.id)
                    ReceiptStorage.write(image, name: name)
                }
            }
        } catch {
            handle(error)
        }
    }

    private func handle(_ error: Error) {
        if case AuthError.notSignedIn = error {
            isSignedIn = false
        }
        errorText = error.localizedDescription
    }
}