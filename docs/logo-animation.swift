import SwiftUI
 
/// Splash/hero animado do wordmark "miomei.": uma caneta só desenhando a palavra
/// inteira da esquerda pra direita ("mio" em branco, seguido de "mei." em laranja,
/// sem pausa entre as duas), e um único preenchimento que aparece pras duas cores
/// ao mesmo tempo perto do fim do traço — como o `LogoDraw` faz pra um `Shape` só,
/// só que dividido em duas cores.
///
/// `LogoDraw` (o componente genérico de `Sources/LogoDraw`) não dá pra reusar direto
/// aqui: ele anima um `Shape`/preenchimento por vez, e duas instâncias em paralelo
/// desenhariam "mio" e "mei." ao mesmo tempo, ou uma só depois da outra terminar de
/// preencher — nos dois casos parece dois logos, não uma palavra. Este componente
/// reimplementa a mesma coreografia (traço via `.trim`, depois fade do preenchimento,
/// `freezeAt`, Reduce Motion) reservando o `drawDuration` pra palavra inteira.
///
/// As duas metades NÃO têm cada uma sua própria animação encadeada (isso criaria uma
/// costura perceptível: a curva de easing desacelera no fim de "mio" e reacelera no
/// início de "mei", como se a caneta parasse no meio da palavra). Em vez disso existe
/// um único `wordProgress` (0...1) animado com uma curva só, e `mioTrim`/`meiTrim` são
/// só fatias lineares desse valor a cada quadro — proporcionais ao comprimento de
/// traço real de cada metade (medido em `logo/tools/vectorize.py`: "mio" 47%, "mei."
/// 53%). Como há uma velocidade contínua do início ao fim, a troca de cor no meio
/// acontece sem qualquer variação de ritmo.
///
/// Ao contrário do `LogoDraw` (que sempre desenha num quadrado `size x size`), aqui
/// `width`/`height` já saem na proporção real do wordmark — `path(in:)` das duas
/// `Shape` recebe esse retângulo e preenche ele por inteiro, sem letterboxing.
public struct MiomeiLogo: View {
    public enum DrawEasing: String, CaseIterable, Sendable {
        case snappy, smooth, easeInOut, linear
    }
 
    /// Fração do comprimento de traço total que pertence à metade "mio" (o resto é
    /// "mei."); medida a partir dos pontos vetorizados, não do número de letras ou
    /// da largura. Usada por `MiomeiWordStrokes` pra fatiar `wordProgress`.
    private static let mioFraction: CGFloat = 0.4723
 
    private static let aspectRatio = MiomeiWordmarkMetrics.designSize.height
        / MiomeiWordmarkMetrics.designSize.width
 
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wordProgress: CGFloat = 0
    @State private var fillOpacity: Double = 0
 
    private let width: CGFloat
    private let drawDuration: TimeInterval
    private let drawEasing: DrawEasing
    private let fillStartPercent: Double
    private let fillDuration: TimeInterval
    private let strokeWidth: CGFloat
    private let replayTrigger: Int
    private let freezeAt: CGFloat?
    private let onComplete: (() -> Void)?
 
    /// - Parameters:
    ///   - width: largura final do wordmark (a altura é derivada da proporção do logo).
    ///   - drawDuration: duração do traço da palavra inteira, "mio" + "mei." (0.3...4 s).
    ///   - drawEasing: curva do traço.
    ///   - fillStartPercent: em que ponto do traço da palavra inteira o preenchimento
    ///     das duas cores começa a aparecer, em % (0...100).
    ///   - fillDuration: duração do fade do preenchimento (0.1...1 s).
    ///   - strokeWidth: espessura do contorno.
    ///   - replayTrigger: mude o valor pra tocar de novo.
    ///   - freezeAt: progresso fixo (0...1) do traço da palavra inteira, em vez de animar.
    ///   - onComplete: chamado quando o preenchimento termina.
    public init(
        width: CGFloat = 240,
        drawDuration: TimeInterval = 1.8,
        drawEasing: DrawEasing = .smooth,
        fillStartPercent: Double = 70,
        fillDuration: TimeInterval = 0.35,
        strokeWidth: CGFloat = 1.5,
        replayTrigger: Int = 0,
        freezeAt: CGFloat? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.width = max(width, 1)
        self.drawDuration = min(max(drawDuration, 0.3), 4)
        self.drawEasing = drawEasing
        self.fillStartPercent = min(max(fillStartPercent, 0), 100)
        self.fillDuration = min(max(fillDuration, 0.1), 1)
        self.strokeWidth = min(max(strokeWidth, 0.5), 12)
        self.replayTrigger = replayTrigger
        self.freezeAt = freezeAt.map { min(max($0, 0), 1) }
        self.onComplete = onComplete
    }
 
    public var body: some View {
        let height = width * Self.aspectRatio
 
        ZStack {
            MiomeiWordStrokes(progress: wordProgress, mioFraction: Self.mioFraction, strokeWidth: strokeWidth)
 
            MiomeiMioShape()
                .fill(.white)
                .opacity(fillOpacity)
            MiomeiMeiShape()
                .fill(.miomeiOrange)
                .opacity(fillOpacity)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("miomei.")
        .accessibilityValue(isComplete ? "Completo" : "Desenhando")
        .task(id: PlaybackKey(
            replayTrigger: replayTrigger,
            reduceMotion: reduceMotion,
            freezeAt: freezeAt,
            drawDuration: drawDuration,
            drawEasing: drawEasing,
            fillStartPercent: fillStartPercent,
            fillDuration: fillDuration
        )) {
            await restartAnimation()
        }
    }
 
    private var isComplete: Bool {
        wordProgress == 1 && fillOpacity == 1
    }
 
    private func drawAnimation(duration: TimeInterval) -> Animation {
        switch drawEasing {
        case .snappy: .snappy(duration: duration)
        case .smooth: .smooth(duration: duration)
        case .easeInOut: .easeInOut(duration: duration)
        case .linear: .linear(duration: duration)
        }
    }
 
    @MainActor
    private func restartAnimation() async {
        var reset = Transaction()
        reset.disablesAnimations = true
 
        if let freezeAt {
            withTransaction(reset) {
                wordProgress = freezeAt
                fillOpacity = freezeAt * 100 >= fillStartPercent ? 1 : 0
            }
            return
        }
 
        withTransaction(reset) {
            wordProgress = reduceMotion ? 1 : 0
            fillOpacity = reduceMotion ? 1 : 0
        }
 
        if reduceMotion {
            onComplete?()
            return
        }
        await Task.yield()
        guard !Task.isCancelled else { return }
 
        let fillDelay = drawDuration * fillStartPercent / 100
 
        // Traço da palavra inteira numa única animação/curva de easing -- "mio" e
        // "mei." são só fatias lineares de `wordProgress` (ver `MiomeiWordStrokes`),
        // então não há descontinuidade de velocidade na troca de cor. O preenchimento
        // é um evento único pras duas cores, disparado a `fillStartPercent` da palavra
        // inteira, concorrente com o que estiver acontecendo no traço nesse instante.
        withAnimation(drawAnimation(duration: drawDuration)) {
            wordProgress = 1
        }
 
        await sleepThen(fillDelay) {
            withAnimation(.smooth(duration: fillDuration)) {
                fillOpacity = 1
            }
        }
        guard !Task.isCancelled else { return }
 
        let remaining = max(drawDuration, fillDelay + fillDuration) - fillDelay
        if remaining > 0 {
            guard (try? await Task.sleep(for: .seconds(remaining))) != nil, !Task.isCancelled else { return }
        }
        onComplete?()
    }
 
    @MainActor
    private func sleepThen(_ delay: TimeInterval, _ action: () -> Void) async {
        if delay > 0 {
            guard (try? await Task.sleep(for: .seconds(delay))) != nil else { return }
        }
        guard !Task.isCancelled else { return }
        action()
    }
 
    private struct PlaybackKey: Equatable {
        let replayTrigger: Int
        let reduceMotion: Bool
        let freezeAt: CGFloat?
        let drawDuration: TimeInterval
        let drawEasing: DrawEasing
        let fillStartPercent: Double
        let fillDuration: TimeInterval
    }
}
 
private extension Color {
    /// RGB(242, 150, 46) — a cor exata do laranja em `logo/miomei-logo.png`.
    static let miomeiOrange = Color(red: 242.0 / 255, green: 150.0 / 255, blue: 46.0 / 255)
}
 
/// Os dois traços ("mio" branco + "mei." laranja) desenhados a partir de um único
/// `progress` (0...1) da palavra inteira. Conformar a `Animatable` aqui (em vez de
/// deixar cada `Shape` animar seu próprio `trim` via `@State` separado) é o que
/// garante uma curva de velocidade só: o SwiftUI interpola `progress` sozinho e
/// chama `body` a cada quadro, e `mioTrim`/`meiTrim` são só fatias lineares desse
/// valor — sem isso, "mio" desaceleraria no fim e "mei" reaceleraria do zero, dando
/// a impressão de uma pausa entre as duas metades.
private struct MiomeiWordStrokes: View, Animatable {
    var progress: CGFloat
    let mioFraction: CGFloat
    let strokeWidth: CGFloat
 
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
 
    private var mioTrim: CGFloat {
        min(progress / mioFraction, 1)
    }
 
    private var meiTrim: CGFloat {
        min(max((progress - mioFraction) / (1 - mioFraction), 0), 1)
    }
 
    var body: some View {
        ZStack {
            MiomeiMioShape()
                .trim(from: 0, to: mioTrim)
                .stroke(.white, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            MiomeiMeiShape()
                .trim(from: 0, to: meiTrim)
                .stroke(.miomeiOrange, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }
}
 
#if DEBUG
// A metade "mio" do logo é branca (fica invisível em fundo claro por design —
// veja `logo/miomei-logo.png`); os previews usam fundo escuro pra mostrar as
// duas metades, mas o componente em si não impõe nenhum fundo.
private struct MiomeiLogoDemo: View {
    @State private var replay = 0
    var body: some View {
        VStack(spacing: 32) {
            MiomeiLogo(width: 280, replayTrigger: replay)
            Button("Replay") { replay += 1 }
        }
        .padding(40)
        .background(.black)
    }
}
 
#Preview("MiomeiLogo") {
    MiomeiLogoDemo()
}
 
#Preview("MiomeiLogo (freeze 60%)") {
    MiomeiLogo(width: 280, freezeAt: 0.6)
        .padding(40)
        .background(.black)
}
#endif
 