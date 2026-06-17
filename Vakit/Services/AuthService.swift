import AuthenticationServices
import Foundation
import Observation

enum SessionState: Equatable {
    case guest
    case apple(userID: String)
}

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private enum Key {
        static let appleUserID = "auth.appleUserID"
    }

    private(set) var session: SessionState
    private(set) var isSigningIn = false
    var errorMessage: String?

    private init(defaults: UserDefaults = AppGroup.userDefaults) {
        self.defaults = defaults
        if let userID = defaults.string(forKey: Key.appleUserID), !userID.isEmpty {
            session = .apple(userID: userID)
        } else {
            session = .guest
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isGuest: Bool {
        if case .guest = session { return true }
        return false
    }

    var appleUserID: String? {
        if case .apple(let userID) = session { return userID }
        return nil
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple ile giriş tamamlanamadı."
                return
            }

            let userID = credential.user
            defaults.set(userID, forKey: Key.appleUserID)
            session = .apple(userID: userID)
            try? await PurchaseService.shared.logIn(appUserID: userID)
        } catch {
            errorMessage = "Apple ile giriş tamamlanamadı."
        }
    }

    func refreshCredentialState() async {
        guard let userID = appleUserID else { return }

        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: userID)
            if state == .revoked || state == .notFound {
                signOut()
            }
        } catch {
            // Keep the local session if Apple credential state cannot be checked.
        }
    }

    func signOut() {
        defaults.removeObject(forKey: Key.appleUserID)
        session = .guest
        Task { try? await PurchaseService.shared.logOut() }
    }

    /// Hesabı siler: yerel Apple kimliğini ve RevenueCat bağlantısını kaldırır.
    ///
    /// Not: Bu uygulamanın arka uç sunucusu yoktur; Apple kullanıcı kimliği yalnızca
    /// cihazda saklanır. Sunucu tarafı bir Sign in with Apple token'ı üretilmediği için
    /// REST "revoke" çağrısı gerekmez/uygulanamaz — hesabın tüm izleri (yerel kimlik +
    /// RevenueCat kullanıcı bağlantısı + tüm kullanıcı verisi) cihazdan kaldırılır.
    /// Kullanıcı verisi temizliği çağıran tarafça (SettingsViewModel.deleteAccount) yapılır.
    func deleteAccount() async {
        try? await PurchaseService.shared.logOut()
        defaults.removeObject(forKey: Key.appleUserID)
        session = .guest
        errorMessage = nil
    }
}
