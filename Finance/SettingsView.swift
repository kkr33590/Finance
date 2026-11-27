import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cloud: CloudSync
    @AppStorage("appLanguage") private var lang = "ml"
    @AppStorage("defaultCurrency") private var defaultCurrency = "INR"
    @State private var showRestoreConfirm = false

    var body: some View {
        let _ = lang
        NavigationStack {
            Form {
                Section(tr("Language", "ഭാഷ")) {
                    Picker(tr("Language", "ഭാഷ"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { l in
                            Text(l.label).tag(l.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section(tr("Default currency", "സ്ഥിര കറൻസി")) {
                    NavigationLink {
                        CurrencyPickerView(selection: $defaultCurrency)
                    } label: {
                        HStack {
                            Text(currencyName(defaultCurrency))
                            Spacer()
                            Text(defaultCurrency).foregroundColor(.secondary)
                        }
                    }
                }

                googleSection
            }
            .navigationTitle(tr("Settings", "സെറ്റിങ്സ്"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Done", "ശരി")) { dismiss() }
                }
            }
            .alert(tr("Restore from Google?", "Google-ൽ നിന്ന് Restore ചെയ്യണോ?"),
                   isPresented: $showRestoreConfirm) {
                Button(tr("Restore", "Restore"), role: .destructive) {
                    Task { await cloud.restore() }
                }
                Button(tr("Cancel", "റദ്ദാക്കുക"), role: .cancel) {}
            } message: {
                Text(tr("This replaces the data on this phone with your last backup.",
                        "ഈ ഫോണിലെ ഡാറ്റ അവസാന ബാക്കപ്പ് കൊണ്ട് മാറ്റും."))
            }
        }
        .alert(tr("Backup found", "ബാക്കപ്പ് കണ്ടെത്തി"), isPresented: $cloud.conflict) {
            Button(tr("Use cloud data", "ക്ലൗഡ് ഡാറ്റ ഉപയോഗിക്കുക")) {
                Task { await cloud.useCloudData() }
            }
            Button(tr("Use this phone's data", "ഈ ഫോണിലെ ഡാറ്റ ഉപയോഗിക്കുക"), role: .destructive) {
                Task { await cloud.useThisPhone() }
            }
        } message: {
            Text(tr("Your Google Drive already has a backup, and this phone also has data. Which one do you want to keep? The other one will be replaced.",
                    "Google Drive-ൽ ബാക്കപ്പ് ഉണ്ട്, ഈ ഫോണിലും ഡാറ്റ ഉണ്ട്. ഏതാണ് നിലനിർത്തേണ്ടത്? മറ്റേത് മാറ്റപ്പെടും."))
        }
    }

    private var googleSection: some View {
        Section {
            if !GoogleConfig.isConfigured {
                Text(tr("Set your Google Client ID in GoogleConfig.swift first.",
                        "ആദ്യം GoogleConfig.swift-ൽ Client ID ചേർക്കുക."))
                    .font(FinFont.caption)
                    .foregroundColor(.orange)
            }

            if cloud.isSignedIn {
                Label(cloud.email.isEmpty ? "Google" : cloud.email,
                      systemImage: "person.crop.circle.fill")

                Toggle(tr("Auto backup", "ഓട്ടോ ബാക്കപ്പ്"), isOn: $cloud.autoBackup)

                Button {
                    Task { await cloud.backup() }
                } label: {
                    Label(tr("Back up now", "ഇപ്പോൾ ബാക്കപ്പ് ചെയ്യുക"),
                          systemImage: "icloud.and.arrow.up")
                }
                .disabled(cloud.isBusy)

                Button {
                    showRestoreConfirm = true
                } label: {
                    Label(tr("Restore from Google Drive", "Google Drive-ൽ നിന്ന് Restore"),
                          systemImage: "icloud.and.arrow.down")
                }
                .disabled(cloud.isBusy)

                if let last = cloud.lastBackup {
                    Text("\(tr("Last backup", "അവസാന ബാക്കപ്പ്")): \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(FinFont.caption)
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    cloud.signOut()
                } label: {
                    Label(tr("Sign out", "സൈൻ ഔട്ട്"),
                          systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                Button {
                    Task { await cloud.signIn() }
                } label: {
                    Label(tr("Sign in with Google", "Google ഉപയോഗിച്ച് സൈൻ-ഇൻ"),
                          systemImage: "person.crop.circle.badge.checkmark")
                }
            }

            if cloud.isBusy {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(tr("Working…", "പ്രവർത്തിക്കുന്നു…"))
                        .foregroundColor(.secondary)
                }
            }

            if let error = cloud.errorText {
                Text(error)
                    .font(FinFont.caption)
                    .foregroundColor(.red)
            }
        } header: {
            Text(tr("Google backup", "Google ബാക്കപ്പ്"))
        } footer: {
            Text(tr("Your data is saved in a private, hidden app folder in your own Google Drive. Only this app can open it.",
                    "ഡാറ്റ നിങ്ങളുടെ സ്വന്തം Google Drive-ലെ രഹസ്യ ആപ്പ് ഫോൾഡറിൽ സൂക്ഷിക്കുന്നു. ഈ ആപ്പിന് മാത്രമേ ഇത് തുറക്കാൻ പറ്റൂ."))
        }
    }
}