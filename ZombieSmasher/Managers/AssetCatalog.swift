import SpriteKit

enum AssetCatalog {

    static let playerRun           = "MaleCharacterMovementSpriteSheet"
    static let playerWeapons       = "MaleCharacterWeaponsSpriteSheetAttacks"
    static let playerGrenadeDeath  = "GrenadeExplosionAndDeathAnimationSpriteSheet"
    static let playerIdleDance     = "IdleBachataDance"
    static let playerWalkHandgun   = "WalkingWithHandGunEquiped"
    static let playerWalkRifle     = "WalkingWithRifleSpriteAnimation"
    static let playerWalkBow       = "WalkingwithBow"

    static let zombieWalk          = "ZombieWalkingAttackingAnimations"
    static let zombieHitBullet     = "ZombieAnimationGettingShotByHandgunBullets"
    static let zombieHitArrow      = "ZombieAnimationGettingHitByArrow"
    static let zombieDeathGrenade  = "ZombieDeathByGrenadeSpriteSheet"

    static let pickupHandgun = "HandgunrotatingAnimationPickupitemspritesheet"
    static let pickupRifle   = "RiflePickupItemRotationSpriteSheet"
    static let pickupBow     = "PickupItemBowRotatingSpriteSheet"
    static let pickupBat     = "PickupItemBatRotationSpritesheet"

    static let menuBackground = "MainMenuBackground"
    static let menuLogo       = "MainLogoBachataAnimatonSpriteSheet"
    static let startButton    = "StartButtonAnimationMenuSpriteSheet"

    static func levelBackground(_ index: Int) -> String { "Level\(index)" }
    static func levelGround(_ index: Int) -> String? {
        index == 1 ? "GroundLevel1" : nil
    }

    // MARK: - Frame extraction

    static func playerRunFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerRun, cols: 4, rows: 3, range: 0..<4)
    }

    static func playerJumpFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerRun, cols: 4, rows: 3, range: 4..<12)
    }

    static func playerIdleDanceFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerIdleDance, cols: 4, rows: 3)
    }

    static func playerWalkFrames(weapon: WeaponKind) -> [SKTexture] {
        let sheet: String
        switch weapon {
        case .handgun: sheet = playerWalkHandgun
        case .rifle:   sheet = playerWalkRifle
        case .bow:     sheet = playerWalkBow
        default:       return SpriteSheetSlicer.slice(image: playerRun, cols: 4, rows: 3, range: 0..<4)
        }
        return SpriteSheetSlicer.slice(image: sheet, cols: 4, rows: 3, range: 0..<4)
    }

    static func playerAttackFrames(weapon: WeaponKind) -> [SKTexture] {
        let all = SpriteSheetSlicer.slice(image: playerWeapons, cols: 4, rows: 5)
        let row = weapon.attackRow
        return Array(all[(row * 4)..<((row + 1) * 4)])
    }

    static func explosionFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerGrenadeDeath, cols: 4, rows: 2, range: 0..<4)
    }

    static func playerDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerGrenadeDeath, cols: 4, rows: 2, range: 4..<8)
    }

    static func zombieWalkFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieWalk, cols: 4, rows: 3)
    }

    static func zombieHitBulletFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieHitBullet, cols: 4, rows: 1)
    }

    static func zombieHitArrowFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieHitArrow, cols: 4, rows: 1)
    }

    static func zombieGrenadeDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieDeathGrenade, cols: 4, rows: 1)
    }

    static func pickupFrames(_ weapon: WeaponKind) -> [SKTexture] {
        SpriteSheetSlicer.slice(image: weapon.pickupSheet, cols: 4, rows: 2)
    }

    static func startButtonFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: startButton, cols: 4, rows: 2)
    }

    static func menuLogoFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: menuLogo, cols: 4, rows: 3)
    }

    // MARK: - Preload

    static func preloadAll() {
        let names = [
            playerRun, playerWeapons, playerGrenadeDeath, playerIdleDance,
            playerWalkHandgun, playerWalkRifle, playerWalkBow,
            zombieWalk, zombieHitBullet, zombieHitArrow, zombieDeathGrenade,
            pickupHandgun, pickupRifle, pickupBow, pickupBat,
            menuBackground, menuLogo, startButton,
            "Level1", "Level2", "Level3", "Level4", "Level5"
        ]
        DispatchQueue.global(qos: .userInitiated).async {
            for n in names {
                _ = UIImage(named: n)
            }
        }
    }
}
