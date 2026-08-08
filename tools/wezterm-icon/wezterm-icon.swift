import SwiftUI
import AppKit
import Foundation

let CANVAS: CGFloat = 1024
let BODY: CGFloat = 824
let RADIUS: CGFloat = 214.5
let PHI: CGFloat = 1.618033988749895

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 6 { s += "FF" }
        let v = UInt32(s, radix: 16) ?? 0xFFFFFFFF
        self.init(.sRGB,
                  red: Double((v >> 24) & 0xFF) / 255,
                  green: Double((v >> 16) & 0xFF) / 255,
                  blue: Double((v >> 8) & 0xFF) / 255,
                  opacity: Double(v & 0xFF) / 255)
    }
}

// WezTerm's own palette, sampled from the shipped icon.
let LEVELS: [(String, String, String, String, Double, Double)] = [
  ("#2B383E", "#141B20", "#5F5BFA", "#4340D8", 0.62, 0.38),   // 0: current
  ("#232E34", "#0F161A", "#7B78FF", "#5A56EE", 0.68, 0.44),   // 1: subtle
  ("#1E272C", "#0C1215", "#8C89FF", "#6A66F5", 0.74, 0.50),   // 2: medium
  ("#1A2227", "#090E11", "#9F9CFF", "#7C79FF", 0.80, 0.56),   // 3: strong
]
var LV = 0
var PLATE_TOP: String { LEVELS[LV].0 }
var PLATE_BOT: String { LEVELS[LV].1 }
var INK_TOP: String { LEVELS[LV].2 }
var INK_BOT: String { LEVELS[LV].3 }
var ROW1_OP: Double { LEVELS[LV].4 }
var ROW2_OP: Double { LEVELS[LV].5 }
var GLOW: String { LEVELS[LV].2 }

struct Chevron: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        return p
    }
}

struct Geom {
    let markW, markH, barW, chevW, gap, stroke, barH, chevPathW, chevPathH: CGFloat
    init(scale: CGFloat) {
        markW = BODY / PHI * scale
        markH = markW / PHI
        barW = markW / (PHI + 1 / PHI + 1)
        chevW = barW * PHI
        gap = barW / PHI
        stroke = chevW / (PHI * PHI * PHI)
        barH = stroke
        chevPathW = chevW - stroke
        chevPathH = markH - stroke
    }
}

struct PromptMark: View {
    let g: Geom
    var body: some View {
        ZStack {
            Chevron()
                .stroke(style: StrokeStyle(lineWidth: g.stroke, lineCap: .round, lineJoin: .round))
                .frame(width: g.chevPathW, height: g.chevPathH)
                .position(x: g.chevW / 2, y: g.markH / 2)
            RoundedRectangle(cornerRadius: g.barH / 2, style: .continuous)
                .frame(width: g.barW, height: g.barH)
                .position(x: g.chevW + g.gap + g.barW / 2, y: g.markH - g.barH / 2)
        }
        .frame(width: g.markW, height: g.markH)
    }
}

/// Prompt anchored at the start position with two lines of output beneath it —
/// the layout that gives an up-left placement a reason to exist. Widths and the
/// vertical rhythm are all φ-derived.
struct SessionMark: View {
    let g: Geom
    let blockW: CGFloat

    var lead: CGFloat { g.barH * PHI }
    var row1W: CGFloat { blockW }
    var row2W: CGFloat { blockW / PHI }
    var blockH: CGFloat { g.markH + lead + g.barH + lead + g.barH }

    var body: some View {
        VStack(alignment: .leading, spacing: lead) {
            PromptMark(g: g)
            RoundedRectangle(cornerRadius: g.barH / 2, style: .continuous)
                .frame(width: row1W, height: g.barH).opacity(ROW1_OP)
            RoundedRectangle(cornerRadius: g.barH / 2, style: .continuous)
                .frame(width: row2W, height: g.barH).opacity(ROW2_OP)
        }
        .frame(width: max(blockW, g.markW), height: blockH, alignment: .leading)
    }
}

struct Icon<M: View>: View {
    let mark: M
    let blur: CGFloat
    let dx: CGFloat   // + right
    let dy: CGFloat   // + up

    var body: some View {
        ZStack {
            Color.clear
            ZStack {
                LinearGradient(colors: [Color(hex: INK_TOP), Color(hex: INK_BOT)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                ZStack {
                    Rectangle().fill(
                        LinearGradient(colors: [Color(hex: PLATE_TOP), Color(hex: PLATE_BOT)],
                                       startPoint: .top, endPoint: .bottom))
                    mark.offset(x: dx, y: -dy).blendMode(.destinationOut)
                }
                .compositingGroup()
                // The glow must carry the identical offset or it separates from the cut.
                mark.offset(x: dx, y: -dy)
                    .foregroundStyle(Color(hex: GLOW))
                    .blur(radius: blur)
                    .opacity(0.60)
                    .blendMode(.plusLighter)
                RoundedRectangle(cornerRadius: RADIUS, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.34), .white.opacity(0)],
                                       startPoint: .top, endPoint: .center),
                        lineWidth: 4)
            }
            .frame(width: BODY, height: BODY)
            .clipShape(RoundedRectangle(cornerRadius: RADIUS, style: .continuous))
        }
        .frame(width: CANVAS, height: CANVAS)
    }
}

func render<M: View>(_ v: Icon<M>, _ path: String) throws {
    try MainActor.assumeIsolated {
        let r = ImageRenderer(content: v)
        r.scale = 1.0
        r.isOpaque = false
        guard let cg = r.cgImage else { exit(2) }
        guard let d = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { exit(3) }
        try d.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

let args = CommandLine.arguments
guard args.count >= 4, let lv = Int(args[3]), lv >= 0, lv < LEVELS.count else {
    FileHandle.standardError.write("usage: monophi4 <B|D> <out.png> <level 0-3>\n".data(using: .utf8)!)
    exit(64)
}
LV = lv

let g79 = Geom(scale: 0.79)
switch args[1] {
case "A":  // box-centred, optical rise only — the version currently installed
    try render(Icon(mark: PromptMark(g: g79), blur: 30, dx: 0, dy: 25), args[2])
case "B":  // true optical centre: ink centroid measured at (-52.9, +23.8)
    try render(Icon(mark: PromptMark(g: g79), blur: 30, dx: 53, dy: 24), args[2])
case "C":  // deliberate up-left bias
    try render(Icon(mark: PromptMark(g: g79), blur: 30, dx: -45, dy: 55), args[2])
case "D":  // prompt at the start position, output filling the space below
    let gs = Geom(scale: 0.62)
    let s = SessionMark(g: gs, blockW: 470)
    // Anchor up-left: margins split so top:bottom and left:right are 1:φ.
    let freeX = BODY - max(470, gs.markW), freeY = BODY - s.blockH
    let mx = freeX / (1 + PHI), my = freeY / (1 + PHI)
    try render(Icon(mark: s, blur: 24,
                    dx: -(freeX / 2 - mx), dy: (freeY / 2 - my)), args[2])
default:
    FileHandle.standardError.write("unknown variant\n".data(using: .utf8)!)
    exit(65)
}
