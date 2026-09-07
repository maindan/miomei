import Observation

/// Estado global mínimo para a navbar destacar o ícone de cronômetro quando
/// há sessão em curso (Guia de Estilo §7 "Navbar flutuante").
@Observable
final class TimerStatusStore {
    var isRunning = false
}
