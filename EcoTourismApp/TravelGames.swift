import SwiftUI
import PhotosUI
import ImageIO

struct TravelGames: View {
    var body: some View {
        List {
            Section {
                Text("A little play between adventures. All three games work offline; your photos stay on this device.")
                    .foregroundStyle(.secondary)
            }
            NavigationLink { PhotoPuzzle() } label: {
                Label("Photo Puzzle", systemImage: "puzzlepiece").padding(.vertical, 12)
            }
            NavigationLink { WildlifePairs() } label: {
                Label("Wildlife Memory Pairs", systemImage: "square.grid.3x2").padding(.vertical, 12)
            }
            NavigationLink { PlaceScramble() } label: {
                Label("Zimbabwe Word Scramble", systemImage: "textformat.abc").padding(.vertical, 12)
            }
        }
        .navigationTitle("Travel Games")
        .tint(TravelStyle.ink)
    }
}

enum TravelGameRules {
    static func shuffledTiles(count: Int) -> [Int] {
        guard count > 1 else { return Array(0..<max(0, count)) }
        var tiles = Array(0..<count).shuffled()
        if tiles == Array(0..<count) { tiles.swapAt(0, 1) }
        return tiles
    }

    static func isSolved(_ tiles: [Int]) -> Bool {
        !tiles.isEmpty && tiles == Array(0..<tiles.count)
    }

    static func normalisedAnswer(_ answer: String) -> String {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct PhotoPuzzle: View {
    @State private var selection: PhotosPickerItem?
    @State private var tiles: [UIImage] = []
    @State private var order: [Int] = []
    @State private var selected: Int?
    @State private var reference: UIImage?
    @State private var showingReference = false
    @State private var moves = 0
    @State private var loading = false
    @State private var errorMessage: String?
    private var solved: Bool { TravelGameRules.isSolved(order) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Turn a memory into a puzzle. Tap two tiles to swap them and rebuild your photo.")
                    .foregroundStyle(.secondary)
                PhotosPicker(selection: $selection, matching: .images) {
                    Label(reference == nil ? "Choose a Photo" : "Choose Another Photo", systemImage: "photo")
                }
                .buttonStyle(.borderedProminent)
                if loading { ProgressView("Preparing your puzzle…") }
                if !tiles.isEmpty {
                    Text(solved ? "You solved it in \(moves) moves!" : "\(moves) moves")
                        .font(.headline)
                        .accessibilityAddTraits(.updatesFrequently)
                    GeometryReader { geometry in
                        let side = (geometry.size.width - 8) / 3
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                            ForEach(order, id: \.self) { tile in
                                Button { swap(tile) } label: {
                                    Image(uiImage: tiles[tile])
                                        .resizable().scaledToFill()
                                        .frame(width: side, height: side).clipped()
                                        .overlay {
                                            Rectangle().stroke(selected == tile ? Color.orange : .clear, lineWidth: 4)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Photo piece \(tile + 1), position \((order.firstIndex(of: tile) ?? 0) + 1)")
                                .accessibilityAddTraits(selected == tile ? .isSelected : [])
                                .disabled(solved || loading)
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    Toggle("Show Original Photo", isOn: $showingReference)
                    if showingReference, let reference {
                        Image(uiImage: reference).resizable().scaledToFit()
                            .frame(maxHeight: 240)
                            .accessibilityLabel("Original puzzle photo")
                    }
                    Button("Shuffle Again") { reset() }.buttonStyle(.bordered)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                Text("Photos are not uploaded. Your puzzle resets when you leave this screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Photo Puzzle")
        .task(id: selection) { await preparePhoto() }
    }

    private func swap(_ tile: Int) {
        if selected == tile { selected = nil; return }
        if let first = selected, let a = order.firstIndex(of: first), let b = order.firstIndex(of: tile) {
            order.swapAt(a, b); selected = nil; moves += 1
        } else { selected = tile }
    }

    private func reset() {
        order = TravelGameRules.shuffledTiles(count: tiles.count)
        moves = 0; selected = nil
    }

    private func preparePhoto() async {
        guard let selection else { return }
        loading = true; errorMessage = nil
        do {
            guard let data = try await selection.loadTransferable(type: Data.self),
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 900
                  ] as CFDictionary) else { throw AuthError.invalidResponse }
            try Task.checkCancellation()
            let side = min(thumbnail.width, thumbnail.height)
            let crop = CGRect(x: (thumbnail.width - side) / 2, y: (thumbnail.height - side) / 2, width: side, height: side)
            guard let square = thumbnail.cropping(to: crop) else { throw AuthError.invalidResponse }
            var pieces: [UIImage] = []
            let tileSize = side / 3
            for row in 0..<3 {
                for column in 0..<3 {
                    guard let piece = square.cropping(to: CGRect(x: column * tileSize, y: row * tileSize, width: tileSize, height: tileSize)) else {
                        throw AuthError.invalidResponse
                    }
                    pieces.append(UIImage(cgImage: piece))
                }
            }
            tiles = pieces; reference = UIImage(cgImage: square); reset(); loading = false
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            loading = false
            errorMessage = "Couldn't open that photo. Try another image, or check your connection if it's in iCloud."
        }
    }
}

private struct WildlifeCard: Identifiable {
    let id: Int
    let animal: String
}

private struct WildlifePairs: View {
    @State private var cards: [WildlifeCard] = []
    @State private var open: [Int] = []
    @State private var matched: Set<Int> = []
    @State private var attempts = 0
    @State private var round = UUID()
    private let animals = ["🐘", "🦁", "🦒", "🦓", "🦏", "🐆"]
    private let names = ["🐘": "Elephant", "🦁": "Lion", "🦒": "Giraffe", "🦓": "Zebra", "🦏": "Rhino", "🐆": "Leopard"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Find the six matching animal pairs.").foregroundStyle(.secondary)
                Text(matched.count == 12 ? "All pairs found in \(attempts) turns!" : "\(matched.count / 2) of 6 pairs · \(attempts) turns")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(cards) { card in
                        let visible = open.contains(card.id) || matched.contains(card.id)
                        Button { flip(card) } label: {
                            Text(visible ? card.animal : "?")
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity, minHeight: 86)
                                .background(visible ? TravelStyle.card : TravelStyle.forest, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(.white)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16).stroke(TravelStyle.ink.opacity(0.2))
                                }
                        }
                        .accessibilityLabel(visible ? (names[card.animal] ?? "Animal") : "Hidden card \(card.id + 1)")
                        .disabled(visible || open.count == 2)
                    }
                }
                Button("New Game") { reset() }.buttonStyle(.bordered)
            }
            .padding(20)
            .frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .navigationTitle("Wildlife Pairs")
        .onAppear { if cards.isEmpty { reset() } }
        .onDisappear { round = UUID() }
    }

    private func reset() {
        round = UUID()
        cards = (0..<12).map { WildlifeCard(id: $0, animal: animals[$0 / 2]) }.shuffled()
        open = []; matched = []; attempts = 0
    }

    private func flip(_ card: WildlifeCard) {
        guard open.count < 2, !open.contains(card.id), !matched.contains(card.id) else { return }
        open.append(card.id)
        guard open.count == 2 else { return }
        attempts += 1
        if let first = cards.first(where: { $0.id == open[0] }), first.animal == card.animal {
            matched.formUnion(open); open = []
        } else {
            let current = round
            Task {
                try? await Task.sleep(for: .seconds(1))
                guard current == round else { return }
                open = []
            }
        }
    }
}

private struct PlaceScramble: View {
    private let places = ["HARARE", "BULAWAYO", "HWANGE", "NYANGA", "KARIBA", "CHINHOYI"]
    @State private var index = 0
    @State private var letters = ""
    @State private var answer = ""
    @State private var message = ""
    @State private var correct = false

    var body: some View {
        Form {
            Section {
                Text("Unscramble a Zimbabwe place name.").font(.headline)
                Text("Place \(index + 1) of \(places.count)").foregroundStyle(.secondary)
                Text(letters.map(String.init).joined(separator: " "))
                    .font(.title2.monospaced().bold())
                    .accessibilityLabel("Letters: " + letters.map(String.init).joined(separator: ", "))
            }
            Section {
                TextField("Place name", text: $answer)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit { check() }
                Button("Check Answer") { check() }
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || correct)
                if !message.isEmpty { Text(message) }
                if correct {
                    Button(index == places.count - 1 ? "Play Again" : "Next Place") {
                        index = (index + 1) % places.count; prepare()
                    }
                } else {
                    Button("Give Me a Hint") { message = "Starts with \(places[index].prefix(1)) and has \(places[index].count) letters." }
                }
            }
        }
        .navigationTitle("Word Scramble")
        .onAppear { if letters.isEmpty { prepare() } }
    }

    private func prepare() {
        letters = String(places[index].shuffled())
        if letters == places[index] { letters = String(places[index].reversed()) }
        answer = ""; message = ""; correct = false
    }

    private func check() {
        guard !correct else { return }
        correct = TravelGameRules.normalisedAnswer(answer) == places[index]
        message = correct ? "That's right! \(places[index].capitalized)." : "Not quite—try another arrangement."
    }
}
