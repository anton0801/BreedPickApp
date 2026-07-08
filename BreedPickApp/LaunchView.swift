import SwiftUI
import Combine
import Network

struct LaunchView: View {

    // Animation flags
    @State private var isVisible = true
    @State private var networkMonitor = NWPathMonitor()
    @State private var glow = false        // layer 1: background glow pulse
    @State private var spin = false        // layer 2: rotating dial
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showChicken = false // layer 3a
    @State private var showTitle = false   // layer 3b
    @StateObject private var slate = Slate()
    @State private var exiting = false

    @State private var timer: Timer?
    @State private var tick = 0

    private let midDots = 12
    private let outerDots = 18

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    Image("load_image_app")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .opacity(0.4)
                        .blur(radius: 5.5)

                    // Layer 1 — radial glow that breathes
                    Circle()
                        .fill(RadialGradient(colors: [BPColor.primaryGlow.opacity(0.45), .clear],
                                             center: .center, startRadius: 6, endRadius: 230))
                        .scaleEffect(glow ? 1.15 : 0.8)
                        .opacity(glow ? 0.9 : 0.5)
                        .frame(width: 420, height: 420)
                    
                    NavigationLink(
                        destination: CourseView().navigationBarHidden(true),
                        isActive: $slate.navigateToWeb
                    ) { EmptyView() }

                    // Layer 2 — concentric priority dials
                    ZStack {
                        dialRing(count: outerDots, radius: 150, dotSize: 9, rotate: false)
                            .opacity(showChicken ? 1 : 0)
                        dialRing(count: midDots, radius: 110, dotSize: 12, rotate: true)
                            .rotationEffect(.degrees(spin ? 360 : 0))
                    }
                    .scaleEffect(exiting ? 1.6 : (showChicken ? 1 : 0.6))
                    .opacity(exiting ? 0 : 1)
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $slate.navigateToMain
                    ) { EmptyView() }

                    // Layer 3 — mascot + title
                    VStack(spacing: 18) {
                        ChickenView(size: 132, bodyColor: BPColor.primary)
                            .scaleEffect(exiting ? 1.5 : (showChicken ? 1 : 0.3))
                            .opacity(exiting ? 0 : (showChicken ? 1 : 0))
                            .rotationEffect(.degrees(showChicken ? 0 : -18))

                        VStack(spacing: 6) {
                            Text("Breed Pick")
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("Loading application content.")
                                .font(.bpBody(15))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .opacity(showTitle ? (exiting ? 0 : 1) : 0)
                        .offset(y: showTitle ? 0 : 16)
                    }
                    
                    VStack {
                        Spacer()
                        InfiniteLoaderView(size: 52)
                        Spacer()
                            .frame(height: 42)
                    }
                }
                .onAppear(perform: start)
                .fullScreenCover(isPresented: $slate.showOfflineView) {
                    OfflineCard()
                }
                .onDisappear(perform: cleanup)
                .fullScreenCover(isPresented: $slate.showPermissionPrompt) {
                    ConsentCard(slate: slate)
                }
            }
            .ignoresSafeArea()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func wireStreams() {
        NotificationCenter.default.publisher(for: .cuesIn)
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                slate.ingestCues(data)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .marksIn)
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                slate.ingestMarks(data)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Dial ring

    private func dialRing(count: Int, radius: CGFloat, dotSize: CGFloat, rotate: Bool) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let isMatch = i % 3 == 0
                Circle()
                    .fill(isMatch ? BPColor.match : BPColor.primary.opacity(0.55))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(isMatch && glow ? 1.5 : 1)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(count) * 360))
            }
        }
    }

    // MARK: - Coordinator

    private func start() {
        isVisible = true
        wireStreams()
        slate.ignite()
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { spin = true }

        timer?.invalidate()
        tick = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { t in
            tick += 1
            switch tick {
            case 3:  withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { showChicken = true }
            case 7:  withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showTitle = true }
            default: break
            }
        }
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                slate.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        isVisible = false
        glow = false; spin = false
        showChicken = false; showTitle = false
    }
    
}

struct ConsentCard: View {
    let slate: Slate

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                Image("breed_pick_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.95)

                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }

    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                slate.acceptConsent()
            } label: {
                Image("want")
                    .resizable()
                    .frame(width: 300, height: 55)
            }

            Button {
                slate.skipConsent()
            } label: {
                Image("sk")
                    .resizable()
                    .frame(width: 278, height: 38)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct OfflineCard: View {
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("error_image_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .blur(radius: 2.5)
                
                if geometry.size.width > geometry.size.height {
                    Image("app_some_error")
                        .resizable()
                        .frame(width: 240, height: 230)
                        .offset(x: 100)
                } else {
                    Image("app_some_error")
                        .resizable()
                        .frame(width: 240, height: 230)
                        .offset(y: 100)
                }
            }
        }
        .ignoresSafeArea()
    }
    
}

struct InfiniteLoaderView: View {
    var size: CGFloat = 64
    var lineWidth: CGFloat = 6

    @State private var isSpinning = false
    @State private var isPulsing = false

    private var arcGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.0),
                Color(red: 1.0, green: 0.80, blue: 0.20),
                Color(red: 1.0, green: 0.45, blue: 0.10)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(300)
        )
    }

    var body: some View {
        ZStack {
            // Подложка кольца
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            
            // Бегущая градиентная дуга
            Circle()
                .trim(from: 0.02, to: 0.80)
                .stroke(arcGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(
                    isSpinning
                    ? .linear(duration: 1.1).repeatForever(autoreverses: false)
                    : nil, // при сбросе анимация не применяется
                    value: isSpinning
                )
                .shadow(color: Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.35), radius: 8)
            
            // Пульсирующее ядро
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.30),
                            Color(red: 1.0, green: 0.45, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.28, height: size * 0.28)
                .scaleEffect(isPulsing ? 1.15 : 0.75)
                .opacity(isPulsing ? 1.0 : 0.45)
                .animation(
                    isPulsing
                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : nil,
                    value: isPulsing
                )
        }
        .frame(width: size, height: size)
        .onAppear(perform: start)
        .onDisappear(perform: reset)
    }

    // MARK: - Lifecycle

    private func start() {
        isSpinning = true
        isPulsing = true
    }

    private func reset() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isSpinning = false
            isPulsing = false
        }
    }
}
