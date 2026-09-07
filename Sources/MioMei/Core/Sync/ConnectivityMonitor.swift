import Foundation
import Network
import Observation

/// Observa conectividade de rede para acionar sync oportunista ao reconectar
/// e para o indicador "Offline" das Configurações (mio-escopo.md §12, §10.1).
@Observable
final class ConnectivityMonitor {
    private(set) var isConnected: Bool = true
    private(set) var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.projexsystem.miomei.connectivity")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
