import ScreenSaver
import Cocoa
import QuartzCore

/// A macOS screen saver that slowly pans and crossfades through
/// classic painterly space art (John Berkey, Chris Foss).
///
/// Each image is shown for ~24 seconds while it slowly drifts and
/// zooms — a Ken Burns pan, so the ships and stations seem to glide
/// across the screen — then crossfades into the next. Runs full-screen
/// and in the System Settings preview pane.
final class SpaceArtView: ScreenSaverView {

    /// How long each image stays on screen.
    private static let slideDuration: TimeInterval = 24
    /// Length of the crossfade between images.
    private static let fadeDuration: TimeInterval = 2.5

    /// Image files in Resources/ (without extension), in show order.
    /// To add your own art, drop a .jpg into Resources/ and add its
    /// name here, then rebuild.
    private static let imageNames = [
        "berkey-116-22-white-oval-ship-red-dot",
        "berkey-120-14-underwater-ships-on-blue",
        "berkey-128-20-oval-ship-with-red",
        "berkey-129-20-exchange-to-left",
        "berkey-13-17-instant-survey",
        "berkey-27-19-space-sphere",
        "berkey-8-19-fire-charge",
        "berkey-96-9-single-ship",
        "berkey-97-9-white-ship",
        "berkey-alien-landscape",
        "berkey-battle-1920",
        "berkey-boiling-globe-114-221052",
        "berkey-brians-crash",
        "berkey-burning-city-121061",
        "berkey-canyon-scan-5-1031",
        "berkey-cathedral",
        "berkey-defending-rose",
        "berkey-desert",
        "berkey-fire-escape-5-1029",
        "berkey-fly-over",
        "berkey-fools-quarry-121064",
        "berkey-garbage-chronicles-refrain",
        "berkey-guarded-space",
        "berkey-how-many-aretheir-121066",
        "berkey-inside-the-sphere",
        "berkey-pre-flight-5-1030",
        "berkey-saucer",
        "berkey-skull-ship-5-1033",
        "berkey-space-study",
        "berkey-space-study-115-221058",
        "berkey-space-study-664-25-1034",
        "berkey-space-study-665-25-1035",
        "berkey-space-study-666-25-1036",
        "berkey-space-study-667-25-1048",
        "berkey-space-study-668-25-1037",
        "berkey-space-study-671-25-1038",
        "berkey-space-study-672-25-1039",
        "berkey-space-study-673-25-1040",
        "berkey-space-study-675-25-1043",
        "berkey-space-study-676-25-1050",
        "berkey-space-study-677-25-1046",
        "berkey-space-study-679-25-1045",
        "berkey-space-study-695-221057",
        "berkey-space-study-696-221053",
        "berkey-space-study-697-221056",
        "berkey-space-study-699-221054",
        "berkey-stacked-energy",
        "berkey-starwars-poster",
        "berkey-station-light-19-1025",
        "berkey-the-fire-this-time-marked",
        "berkey-the-golden-ship",
        "berkey-the-long-red-line-121060",
        "berkey-three-are-one",
        "berkey-three-ships",
        "burns-conquering-sword",
        "elson-ringed-planet",
        "foss-orig-greylensman-foss",
        "foss-tethered",
        "white-a-habitat",
    ]

    private var images: [CGImage] = []
    private var layers: [CALayer] = []
    /// Index into `layers` of the currently visible layer.
    private var visibleLayer = 0
    /// Index into `images` of the currently shown image.
    private var currentImage = 0
    private var timer: Timer?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        loadImages()
        buildLayers()
        if let first = images.first, !layers.isEmpty {
            layers[0].contents = first
            layers[0].opacity = 1
            startMotion(on: layers[0], seed: 0)
        }
    }

    private func loadImages() {
        let bundle = Bundle(for: SpaceArtView.self)
        for name in Self.imageNames {
            guard let url = bundle.url(forResource: name, withExtension: "jpg"),
                  let image = NSImage(contentsOf: url),
                  let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else { continue }
            images.append(cg)
        }
    }

    private func buildLayers() {
        guard let root = layer else { return }
        for _ in 0..<2 {
            let sublayer = CALayer()
            sublayer.frame = bounds
            // Fill the screen, cropping edges rather than letterboxing.
            sublayer.contentsGravity = .resizeAspectFill
            sublayer.opacity = 0
            sublayer.masksToBounds = true
            root.addSublayer(sublayer)
            layers.append(sublayer)
        }
    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        for sublayer in layers {
            sublayer.frame = bounds
        }
    }

    override func startAnimation() {
        super.startAnimation()
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: Self.slideDuration, repeats: true
        ) { [weak self] _ in
            self?.advance()
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        timer?.invalidate()
        timer = nil
    }

    private func advance() {
        guard images.count > 1, layers.count == 2 else { return }
        currentImage = (currentImage + 1) % images.count
        let incoming = layers[1 - visibleLayer]
        let outgoing = layers[visibleLayer]
        incoming.contents = images[currentImage]
        incoming.opacity = 0
        startMotion(on: incoming, seed: currentImage)
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.fadeDuration)
        incoming.opacity = 1
        outgoing.opacity = 0
        CATransaction.commit()
        visibleLayer = 1 - visibleLayer
    }

    /// Slow Ken Burns drift: a gentle zoom combined with a slow pan,
    /// so the scene feels like it is gliding. The direction varies
    /// from slide to slide. The zoom leaves enough margin that the
    /// pan never exposes the edge of the image.
    private func startMotion(on sublayer: CALayer, seed: Int) {
        sublayer.removeAnimation(forKey: "motion")
        let duration = Self.slideDuration + Self.fadeDuration

        // Zoom: alternate in / out so consecutive slides feel different.
        let zoomIn = seed % 2 == 0
        let zoom = CABasicAnimation(keyPath: "transform.scale")
        zoom.fromValue = zoomIn ? 1.02 : 1.16
        zoom.toValue = zoomIn ? 1.16 : 1.02
        zoom.duration = duration

        // Pan: up to ~3% of the smaller screen dimension, in one of
        // four diagonal directions, cycling with the slide index.
        let span = min(bounds.width, bounds.height)
        let dx = 0.03 * span
        let dy = 0.015 * span
        let directions: [(CGFloat, CGFloat)] = [
            (dx, dy), (-dx, -dy), (dx, -dy), (-dx, dy),
        ]
        let (tx, ty) = directions[seed % directions.count]
        let panX = CABasicAnimation(keyPath: "transform.translation.x")
        panX.fromValue = zoomIn ? -tx : tx
        panX.toValue = zoomIn ? tx : -tx
        panX.duration = duration
        let panY = CABasicAnimation(keyPath: "transform.translation.y")
        panY.fromValue = zoomIn ? -ty : ty
        panY.toValue = zoomIn ? ty : -ty
        panY.duration = duration

        let group = CAAnimationGroup()
        group.animations = [zoom, panX, panY]
        group.duration = duration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        sublayer.add(group, forKey: "motion")
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
