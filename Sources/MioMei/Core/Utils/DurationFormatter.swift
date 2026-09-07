import Foundation

extension Int {
    /// Segundos → "01:24:36" (Guia de Estilo §5 "Cronômetro em curso").
    var hoursMinutesSeconds: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Segundos → "2h 15m" para totais de horas.
    var hoursAndMinutes: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
