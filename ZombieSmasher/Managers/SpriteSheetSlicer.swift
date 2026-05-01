import SpriteKit

enum SpriteSheetSlicer {

    static func slice(image name: String, cols: Int, rows: Int) -> [SKTexture] {
        guard let img = UIImage(named: name) else {
            assertionFailure("Missing sheet: \(name)")
            return []
        }
        let base = SKTexture(image: img)
        base.filteringMode = .nearest
        let cellW = 1.0 / CGFloat(cols)
        let cellH = 1.0 / CGFloat(rows)
        var out: [SKTexture] = []
        out.reserveCapacity(cols * rows)
        for r in 0..<rows {
            for c in 0..<cols {
                let rect = CGRect(
                    x: CGFloat(c) * cellW,
                    y: 1.0 - CGFloat(r + 1) * cellH,
                    width: cellW,
                    height: cellH
                )
                let tex = SKTexture(rect: rect, in: base)
                tex.filteringMode = .nearest
                out.append(tex)
            }
        }
        return out
    }

    static func slice(image name: String, cols: Int, rows: Int, range: Range<Int>) -> [SKTexture] {
        let all = slice(image: name, cols: cols, rows: rows)
        guard range.upperBound <= all.count else { return all }
        return Array(all[range])
    }
}
