import Foundation

/// Relatório de horas exportável por período/contrato (mio-escopo.md §7.3).
/// CSV simples (separador `;`, compatível com Excel/Numbers em pt-BR).
enum HoursReportGenerator {
    static func csv(entries: [TimeEntry], demands: [Demand], contracts: [Contract]) -> Data {
        let demandById = Dictionary(uniqueKeysWithValues: demands.map { ($0.id, $0) })
        var lines = ["Data;Demanda;Contrato;Duração (h);Manual"]

        for entry in entries.sorted(by: { $0.startedAt < $1.startedAt }) {
            let demand = demandById[entry.demandId]
            let contract = contracts.first { $0.id == demand?.contractId }
            let hours = Double(entry.durationSeconds ?? Int(Date.now.timeIntervalSince(entry.startedAt))) / 3600
            let fields = [
                entry.startedAt.mediumBR,
                demand?.title ?? "",
                contract?.title ?? "",
                String(format: "%.2f", hours),
                entry.isManual ? "sim" : "não",
            ]
            lines.append(fields.joined(separator: ";"))
        }

        return Data(lines.joined(separator: "\n").utf8)
    }

    static func writeTemporaryFile(data: Data, suggestedName: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(suggestedName).csv")
        try? data.write(to: url)
        return url
    }
}
