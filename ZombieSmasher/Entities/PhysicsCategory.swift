import Foundation

enum PhysicsCategory {
    static let none:      UInt32 = 0
    static let player:    UInt32 = 1 << 0
    static let zombie:    UInt32 = 1 << 1
    static let bullet:    UInt32 = 1 << 2
    static let arrow:     UInt32 = 1 << 3
    static let grenade:   UInt32 = 1 << 4
    static let explosion: UInt32 = 1 << 5
    static let pickup:    UInt32 = 1 << 6
    static let ground:    UInt32 = 1 << 7
}
