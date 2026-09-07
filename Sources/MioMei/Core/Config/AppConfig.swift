import Foundation

/// Lê as chaves do Supabase injetadas no Info.plist via `Config/Secrets.xcconfig`
/// (nunca versionado — ver README).
enum AppConfig {
    static var supabaseURL: URL {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "MioMeiSupabaseHost") as? String,
              !host.isEmpty,
              let url = URL(string: "https://\(host)")
        else {
            fatalError("MioMeiSupabaseHost ausente — preencha Config/Secrets.xcconfig")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "MioMeiSupabaseAnonKey") as? String,
              !key.isEmpty
        else {
            fatalError("MioMeiSupabaseAnonKey ausente — preencha Config/Secrets.xcconfig")
        }
        return key
    }

    static let oauthRedirectURL = URL(string: "miomei://login-callback")!
}
