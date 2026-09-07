import Foundation
import SwiftData

@Model
final class TimeEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var demandId: UUID
    /// Âncora de tempo real (não um contador em memória) — Guia de Estilo §7 "Cronômetro".
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?
    var isManual: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        demandId: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        isManual: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.demandId = demandId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.isManual = isManual
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
