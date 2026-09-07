import Foundation
import SwiftUI

/// Espelha a view `calendar_event` do Supabase, mas montada localmente a
/// partir dos repositórios já carregados (mio-escopo.md §8.1).
enum CalendarEventSource: String, CaseIterable {
    case receivable, payable, invoice, demand, contract, reminder

    var label: String {
        switch self {
        case .receivable: return "Recebimento"
        case .payable: return "Pagamento"
        case .invoice: return "Nota fiscal"
        case .demand: return "Demanda"
        case .contract: return "Contrato"
        case .reminder: return "Lembrete"
        }
    }

    var systemImage: String {
        switch self {
        case .receivable: return "arrow.down.circle"
        case .payable: return "arrow.up.circle"
        case .invoice: return "doc.text"
        case .demand: return "checklist"
        case .contract: return "briefcase"
        case .reminder: return "bell"
        }
    }

    var color: Color {
        switch self {
        case .receivable: return Semantic.received
        case .payable: return Semantic.attention
        case .invoice: return Semantic.info
        case .demand: return Semantic.overdue
        case .contract: return Color(hex: 0xC96A49)
        case .reminder: return .white
        }
    }
}

struct CalendarEvent: Identifiable {
    let id: String
    let source: CalendarEventSource
    let title: String
    let date: Date
    let amount: Decimal?
}
