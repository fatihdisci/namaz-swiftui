import AppKit

struct Shot {
    let input: String
    let output: String
    let title: String
    let subtitle: String
    let accent: NSColor
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appendingPathComponent("AppStore/Screenshots-tr")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let canvas = NSSize(width: 1290, height: 2796)
let shots: [Shot] = [
    Shot(
        input: "/Users/fatihdisci/Downloads/IMG_9351.PNG",
        output: "01-ana-sayfa-vakitler.png",
        title: "Vakitler her an yanında",
        subtitle: "Şehrine göre güncel namaz vakitleri ve kalan süre.",
        accent: NSColor(calibratedRed: 0.20, green: 0.82, blue: 0.62, alpha: 1)
    ),
    Shot(
        input: "/Users/fatihdisci/Downloads/IMG_9352.PNG",
        output: "02-kesfet-gunluk-icerik.png",
        title: "Günlük manevi içerik",
        subtitle: "Ayet, hadis, dua ve Esmaül Hüsna tek ekranda.",
        accent: NSColor(calibratedRed: 0.22, green: 0.76, blue: 0.58, alpha: 1)
    ),
    Shot(
        input: "/Users/fatihdisci/Downloads/IMG_9355.PNG",
        output: "03-kible-pusulasi.png",
        title: "Kıbleyi kolayca bul",
        subtitle: "Konumunu kaydetmeden pusula ile yönünü gör.",
        accent: NSColor(calibratedRed: 0.22, green: 0.80, blue: 0.68, alpha: 1)
    ),
    Shot(
        input: "/Users/fatihdisci/Downloads/IMG_9353.PNG",
        output: "04-kaza-namazlari.png",
        title: "Kaza takibini düzenli tut",
        subtitle: "Namaz borcunu sade sayaçlarla takip et.",
        accent: NSColor(calibratedRed: 0.24, green: 0.78, blue: 0.55, alpha: 1)
    ),
    Shot(
        input: "/Users/fatihdisci/Downloads/IMG_9354.PNG",
        output: "05-seferi-hesabi.png",
        title: "Seferi durumunu hesapla",
        subtitle: "Ev şehrine göre mesafeyi ve sonucu gör.",
        accent: NSColor(calibratedRed: 0.23, green: 0.81, blue: 0.60, alpha: 1)
    )
]

func rectTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attrs).draw(in: rect)
}

func drawPill(text: String, rect: NSRect, accent: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
    NSColor(calibratedRed: 0.05, green: 0.15, blue: 0.12, alpha: 0.82).setFill()
    path.fill()
    accent.withAlphaComponent(0.22).setStroke()
    path.lineWidth = 2
    path.stroke()
    drawText(
        text,
        in: rect.insetBy(dx: 32, dy: 17),
        font: NSFont.systemFont(ofSize: 34, weight: .semibold),
        color: accent,
        alignment: .center
    )
}

func drawMarketImage(_ shot: Shot) throws {
    guard let source = NSImage(contentsOfFile: shot.input) else {
        throw NSError(domain: "make_appstore_screenshots", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot open \(shot.input)"])
    }

    let image = NSImage(size: canvas)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let backgroundRect = NSRect(origin: .zero, size: canvas)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.03, green: 0.11, blue: 0.09, alpha: 1),
        NSColor(calibratedRed: 0.02, green: 0.18, blue: 0.14, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.03, alpha: 1)
    ])!
    gradient.draw(in: backgroundRect, angle: 260)

    let topBand = NSBezierPath()
    topBand.move(to: NSPoint(x: 0, y: canvas.height))
    topBand.line(to: NSPoint(x: canvas.width, y: canvas.height))
    topBand.line(to: NSPoint(x: canvas.width, y: canvas.height - 760))
    topBand.curve(
        to: NSPoint(x: 0, y: canvas.height - 610),
        controlPoint1: NSPoint(x: 920, y: canvas.height - 590),
        controlPoint2: NSPoint(x: 410, y: canvas.height - 840)
    )
    topBand.close()
    NSColor(calibratedRed: 0.07, green: 0.25, blue: 0.19, alpha: 0.54).setFill()
    topBand.fill()

    let warmBand = NSBezierPath()
    warmBand.move(to: NSPoint(x: 0, y: 0))
    warmBand.line(to: NSPoint(x: canvas.width, y: 0))
    warmBand.line(to: NSPoint(x: canvas.width, y: 420))
    warmBand.curve(
        to: NSPoint(x: 0, y: 270),
        controlPoint1: NSPoint(x: 850, y: 530),
        controlPoint2: NSPoint(x: 420, y: 160)
    )
    warmBand.close()
    NSColor(calibratedRed: 0.30, green: 0.19, blue: 0.06, alpha: 0.25).setFill()
    warmBand.fill()

    drawPill(text: "Ufuk", rect: rectTop(x: 900, y: 88, width: 250, height: 84), accent: shot.accent)

    drawText(
        shot.title,
        in: rectTop(x: 96, y: 112, width: 900, height: 170),
        font: NSFont.systemFont(ofSize: 68, weight: .bold),
        color: .white,
        lineHeight: 78
    )
    drawText(
        shot.subtitle,
        in: rectTop(x: 98, y: 282, width: 950, height: 112),
        font: NSFont.systemFont(ofSize: 33, weight: .medium),
        color: NSColor.white.withAlphaComponent(0.72),
        lineHeight: 43
    )

    let screenshotWidth: CGFloat = 1018
    let screenshotHeight = screenshotWidth * source.size.height / source.size.width
    let screenshotRect = rectTop(
        x: (canvas.width - screenshotWidth) / 2,
        y: 482,
        width: screenshotWidth,
        height: screenshotHeight
    )

    NSShadow().set()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 48
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.set()
    let shadowPath = NSBezierPath(roundedRect: screenshotRect.insetBy(dx: -5, dy: -5), xRadius: 58, yRadius: 58)
    NSColor.black.withAlphaComponent(0.22).setFill()
    shadowPath.fill()
    NSShadow().set()

    let borderPath = NSBezierPath(roundedRect: screenshotRect.insetBy(dx: -3, dy: -3), xRadius: 56, yRadius: 56)
    NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.08, alpha: 0.94).setFill()
    borderPath.fill()

    source.draw(in: screenshotRect, from: .zero, operation: .sourceOver, fraction: 1)

    let gloss = NSBezierPath(roundedRect: screenshotRect.insetBy(dx: -2, dy: -2), xRadius: 54, yRadius: 54)
    NSColor.white.withAlphaComponent(0.09).setStroke()
    gloss.lineWidth = 2
    gloss.stroke()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "make_appstore_screenshots", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot encode PNG"])
    }
    try png.write(to: outputDir.appendingPathComponent(shot.output))
}

for shot in shots {
    try drawMarketImage(shot)
    print(outputDir.appendingPathComponent(shot.output).path)
}
