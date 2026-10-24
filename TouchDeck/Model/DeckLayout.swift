import CoreGraphics

enum SliderID: String, CaseIterable, Hashable {
    case brightness, volume, custom

    var symbol: String {
        switch self {
        case .brightness: return "sun.max.fill"
        case .volume: return "speaker.wave.2.fill"
        case .custom: return "slider.vertical.3"
        }
    }
}

enum DeckKey: Hashable {
    case digit(Int)
    case decimal, plus, minus, multiply, divide, backspace, enter

    var id: String {
        switch self {
        case .digit(let d): return "digit\(d)"
        case .decimal: return "decimal"
        case .plus: return "plus"
        case .minus: return "minus"
        case .multiply: return "multiply"
        case .divide: return "divide"
        case .backspace: return "backspace"
        case .enter: return "enter"
        }
    }

    /// Text label, or nil when an SF Symbol is used instead.
    var label: String? {
        switch self {
        case .digit(let d): return "\(d)"
        case .decimal: return "."
        default: return nil
        }
    }

    var symbol: String? {
        switch self {
        case .plus: return "plus"
        case .minus: return "minus"
        case .multiply: return "multiply"
        case .divide: return "divide"
        case .backspace: return "delete.left.fill"
        case .enter: return "return"
        default: return nil
        }
    }
}

enum DeckControlKind: Equatable {
    case slider(SliderID)
    case key(DeckKey)
}

struct DeckControl: Identifiable {
    let id: String
    let kind: DeckControlKind
    /// Normalized rect (0...1), origin top-left. Same space as `TouchPoint`.
    let rect: CGRect
}

/// Single source of truth for geometry: the view draws from it and the
/// touch router hit-tests against it, so what you see is what you touch.
/// The trackpad maps 1:1 onto the whole panel.
enum DeckLayout {
    /// Built-in MacBook trackpads are roughly 1.6:1.
    static let panelSize = CGSize(width: 720, height: 450)

    static let controls: [DeckControl] = makeControls()

    static func control(at point: CGPoint) -> DeckControl? {
        controls.first { $0.rect.contains(point) }
    }

    private static func makeControls() -> [DeckControl] {
        var result: [DeckControl] = []

        // Left: three vertical sliders. Hit area = full column, so you don't need to aim.
        let sliderX = 0.04, sliderWidth = 0.38, sliderY = 0.12, sliderHeight = 0.72
        let column = sliderWidth / Double(SliderID.allCases.count)
        for (i, slider) in SliderID.allCases.enumerated() {
            result.append(DeckControl(
                id: "slider.\(slider.rawValue)",
                kind: .slider(slider),
                rect: CGRect(x: sliderX + Double(i) * column, y: sliderY, width: column, height: sliderHeight)
            ))
        }

        // Right: 4×5 numpad.
        let padX = 0.48, padY = 0.06, padWidth = 0.48, padHeight = 0.88
        let gapX = 0.015, gapY = 0.024
        let cellW = (padWidth - 3 * gapX) / 4
        let cellH = (padHeight - 4 * gapY) / 5

        func cell(_ col: Int, _ row: Int, colSpan: Int = 1, rowSpan: Int = 1) -> CGRect {
            CGRect(
                x: padX + Double(col) * (cellW + gapX),
                y: padY + Double(row) * (cellH + gapY),
                width: Double(colSpan) * cellW + Double(colSpan - 1) * gapX,
                height: Double(rowSpan) * cellH + Double(rowSpan - 1) * gapY
            )
        }

        let keys: [(DeckKey, CGRect)] = [
            (.divide, cell(0, 0)), (.multiply, cell(1, 0)), (.minus, cell(2, 0)), (.backspace, cell(3, 0)),
            (.digit(7), cell(0, 1)), (.digit(8), cell(1, 1)), (.digit(9), cell(2, 1)), (.plus, cell(3, 1, rowSpan: 2)),
            (.digit(4), cell(0, 2)), (.digit(5), cell(1, 2)), (.digit(6), cell(2, 2)),
            (.digit(1), cell(0, 3)), (.digit(2), cell(1, 3)), (.digit(3), cell(2, 3)), (.enter, cell(3, 3, rowSpan: 2)),
            (.digit(0), cell(0, 4, colSpan: 2)), (.decimal, cell(2, 4)),
        ]
        for (key, rect) in keys {
            result.append(DeckControl(id: "key.\(key.id)", kind: .key(key), rect: rect))
        }

        return result
    }
}
