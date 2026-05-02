import SpriteKit

enum WeaponKind: Int, CaseIterable {
    case handgun = 0
    case rifle   = 1
    case bow     = 2
    case punch   = 3
    case bat     = 4

    var attackRow: Int { rawValue }

    var pickupSheet: String {
        switch self {
        case .handgun: return AssetCatalog.pickupHandgun
        case .rifle:   return AssetCatalog.pickupRifle
        case .bow:     return AssetCatalog.pickupBow
        case .bat:     return AssetCatalog.pickupBat
        case .punch:   return AssetCatalog.pickupHandgun
        }
    }

    var damage: Int {
        switch self {
        case .handgun: return 10
        case .rifle:   return 20
        case .bow:     return 30
        case .punch:   return 5
        case .bat:     return 15
        }
    }

    var fireInterval: TimeInterval {
        switch self {
        case .handgun: return 0.35
        case .rifle:   return 0.18
        case .bow:     return 0.7
        case .punch:   return 0.4
        case .bat:     return 0.45
        }
    }

    var isRanged: Bool {
        switch self {
        case .handgun, .rifle, .bow: return true
        case .punch, .bat:           return false
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .handgun: return 900
        case .rifle:   return 1300
        case .bow:     return 700
        default:       return 0
        }
    }

    var label: String {
        switch self {
        case .handgun: return "Handgun"
        case .rifle:   return "Rifle"
        case .bow:     return "Bow"
        case .punch:   return "Fists"
        case .bat:     return "Bat"
        }
    }

    var hasInfiniteAmmo: Bool {
        self == .punch
    }
}
