import Foundation
import SwiftData

/// Espelha `public.profile` — id = auth uid do Supabase, não um UUID gerado localmente.
@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var companyName: String?
    var tradeName: String?
    var cnpj: String?
    var email: String?
    var taxRegime: TaxRegime
    var defaultTaxRate: Decimal
    var dasDueDay: Int
    var meiAnnualCeiling: Decimal?
    var pixKey: String?
    var bankInfo: String?
    var avatarURL: String?
    var onboardingDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        companyName: String? = nil,
        tradeName: String? = nil,
        cnpj: String? = nil,
        email: String? = nil,
        taxRegime: TaxRegime = .mei,
        defaultTaxRate: Decimal = 0,
        dasDueDay: Int = 20,
        meiAnnualCeiling: Decimal? = nil,
        pixKey: String? = nil,
        bankInfo: String? = nil,
        avatarURL: String? = nil,
        onboardingDone: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.companyName = companyName
        self.tradeName = tradeName
        self.cnpj = cnpj
        self.email = email
        self.taxRegime = taxRegime
        self.defaultTaxRate = defaultTaxRate
        self.dasDueDay = dasDueDay
        self.meiAnnualCeiling = meiAnnualCeiling
        self.pixKey = pixKey
        self.bankInfo = bankInfo
        self.avatarURL = avatarURL
        self.onboardingDone = onboardingDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
