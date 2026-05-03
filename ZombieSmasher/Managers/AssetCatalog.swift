import SpriteKit

enum AssetCatalog {

    // MARK: - Player

    static let playerWeapons       = "MaleCharacterWeaponsSpriteSheetAttacks"
    static let playerJump          = "Player1JumpingAnimationSpriteSheet"
    static let playerIdleDance     = "Player1IdleBachataDance"
    static let playerHurt          = "Player1TakingDamageSpriteSheet"
    static let playerDeath         = "Player1DeathAnimation"
    static let playerWalkHandgun   = "Player1WalkingWithHandGunEquiped"
    static let playerWalkRifle     = "WalkingWithRifleSpriteAnimation"
    static let playerWalkBow       = "Player1WalkingwithBow"
    static let playerWalkUnarmed   = "Player1WalkingAnimationUnequiped"
    static let playerRunning       = "Player1RunningSpriteSheetAnimation"
    static let playerShootHandgun  = "ShootingHandGunSpriteSheet"
    static let playerShootRifle    = "ShootingRifleAnimation"
    static let playerShootBow      = "ShootingBowAnimationSpriteSheet"
    static let playerShootBowFire  = "Player1ShooingBowFireArrowAnimation"
    static let playerSwingBat      = "Player1SwingingBatSpriteSheet"

    // MARK: - Zombie

    static let zombieWalk          = "ZombieWalkingAnimations"
    static let zombieAttackBite    = "ZombieBitingAttackAnimation"
    static let zombieHitBullet     = "ZombieTakingBulletDamageSpriteSheet"
    static let zombieDeathBullet   = "ZombieDyingByBeingShotDeathSpriteSheet"
    static let zombieHitArrow      = "ZombieAnimationGettingHitByArrow"
    static let zombieDeathGrenade  = "ZombieDeathByGrenadeSpriteSheet"
    static let zombieDeathFireArrow = "ZombieDeathByFireArrowAnimation"
    static let zombieDeathArrow     = "ZombieDeathByNormalArrowSpriteSheet"
    static let zombieHitFireArrow   = "ZombieTakingDamageByFireArrow"

    // MARK: - Projectiles + explosion

    static let bulletHandgunAnim   = "HandGunBulletTravelingAnimationSpriteSheet"
    static let bulletRifleAnim     = "TravelingRifleBulletSpriteSheet"
    static let arrowFireAnim       = "FlyingArrowBurningFireSpriteSheet"
    static let arrowNormalAnim     = "RegularArrowProjectileSpriteSheet"
    static let explosionSheet      = "GrenadeExplosionSpriteSheet"
    static let grenadeImage        = "GrenadeImage"

    // MARK: - Pickups

    static let pickupHandgun       = "PickupHandGunSpriteSheet"
    static let pickupRifle         = "RiflePickupItemRotationSpriteSheet"
    static let pickupBow           = "PickupItemBowRotatingSpriteSheet"
    static let pickupBat           = "PickupItemBatRotationSpritesheet"
    static let pickupRifleAmmo     = "PickupRifleAmmoBoxSpriteSheet"
    static let pickupArrowBag      = "PickupArrowBagSpriteSheet"
    static let pickupFireArrowBag  = "PickupFireArrowBagSpriteSheet"

    // MARK: - UI

    static let menuBackground      = "MainMenuBackground"
    static let menuLogoVariants    = ["MainLogoBachataAnimatonSpriteSheet",
                                       "MainLogoBachataAnimatonSpriteSheet1"]
    static let menuLogo            = "MainLogoBachataAnimatonSpriteSheet"
    static let startButton         = "StartButtonAnimationMenuSpriteSheet"
    static let inventoryButton     = "InventoryButton"
    static let inventoryWeapons    = "InventoryWeaponItems"
    static let iconHandgun         = "HandGunIcon"

    // MARK: - Level / ground

    static func levelBackground(_ index: Int) -> String { "Level\(index)" }
    static func levelGround(_ index: Int) -> String? { "road" }

    // MARK: - Player frames

    static func playerJumpFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerJump, cols: 4, rows: 2, range: 0..<8)
    }

    static func playerIdleDanceFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerIdleDance, cols: 4, rows: 3, range: 0..<8)
    }

    static func playerHurtFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerHurt, cols: 4, rows: 2, range: 0..<8)
    }

    static func playerDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: playerDeath, cols: 4, rows: 4, range: 0..<16)
    }

    static func playerWalkFrames(weapon: WeaponKind) -> [SKTexture] {
        switch weapon {
        case .handgun:
            return SpriteSheetSlicer.slice(image: playerWalkHandgun, cols: 4, rows: 3, range: 0..<12)
        case .rifle:
            return SpriteSheetSlicer.slice(image: playerWalkRifle, cols: 4, rows: 2, range: 0..<4)
        case .bow:
            return SpriteSheetSlicer.slice(image: playerWalkBow, cols: 4, rows: 2, range: 0..<8)
        case .bat, .punch:
            return SpriteSheetSlicer.slice(image: playerRunning, cols: 4, rows: 2, range: 0..<8)
        }
    }

    static func playerAttackFrames(weapon: WeaponKind, useFireArrow: Bool = false) -> [SKTexture] {
        let sheet: String
        switch weapon {
        case .handgun: sheet = playerShootHandgun
        case .rifle:   sheet = playerShootRifle
        case .bow:     sheet = useFireArrow ? playerShootBowFire : playerShootBow
        case .bat:     sheet = playerSwingBat
        case .punch:   sheet = playerSwingBat
        }
        return SpriteSheetSlicer.slice(image: sheet, cols: 4, rows: 2, range: 0..<8)
    }

    // MARK: - Zombie frames

    static func zombieWalkFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieWalk, cols: 4, rows: 3, range: 0..<8)
    }

    static func zombieAttackBiteFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieAttackBite, cols: 4, rows: 3, range: 0..<8)
    }

    static func zombieHitBulletFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieHitBullet, cols: 4, rows: 3, range: 0..<8)
    }

    static func zombieBulletDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieDeathBullet, cols: 4, rows: 3, range: 0..<12)
    }

    static func zombieHitArrowFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieHitArrow, cols: 4, rows: 1)
    }

    static func zombieGrenadeDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieDeathGrenade, cols: 4, rows: 3, range: 0..<12)
    }

    static func zombieFireArrowDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieDeathFireArrow, cols: 4, rows: 4, range: 0..<16)
    }

    static func zombieFireArrowHitFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieHitFireArrow, cols: 4, rows: 3, range: 0..<8)
    }

    static func zombieArrowDeathFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: zombieDeathArrow, cols: 4, rows: 3, range: 0..<12)
    }

    // MARK: - Projectile + explosion frames

    static func bulletHandgunFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: bulletHandgunAnim, cols: 4, rows: 1, range: 0..<4)
    }

    static func bulletRifleFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: bulletRifleAnim, cols: 4, rows: 1, range: 0..<4)
    }

    static func arrowFireFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: arrowFireAnim, cols: 4, rows: 1, range: 0..<4)
    }

    static func arrowNormalFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: arrowNormalAnim, cols: 4, rows: 1, range: 0..<4)
    }

    static func explosionFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: explosionSheet, cols: 4, rows: 3, range: 0..<12)
    }

    // MARK: - Pickup frames

    static func pickupFrames(_ weapon: WeaponKind) -> [SKTexture] {
        let sheet = weapon.pickupSheet
        let isNewSquare = sheet == pickupHandgun
        let rows = isNewSquare ? 4 : 2
        return SpriteSheetSlicer.slice(image: sheet, cols: 4, rows: rows, range: 0..<8)
    }

    static func ammoPickupFrames(_ kind: AmmoKind) -> [SKTexture] {
        let sheet: String
        switch kind {
        case .rifle:     sheet = pickupRifleAmmo
        case .arrow:     sheet = pickupArrowBag
        case .fireArrow: sheet = pickupFireArrowBag
        }
        return SpriteSheetSlicer.slice(image: sheet, cols: 4, rows: 4, range: 0..<8)
    }

    // MARK: - Menu frames

    static func startButtonFrames() -> [SKTexture] {
        SpriteSheetSlicer.slice(image: startButton, cols: 4, rows: 2)
    }

    static func menuLogoFrames() -> [SKTexture] {
        let sheet = menuLogoVariants.randomElement() ?? menuLogo
        return SpriteSheetSlicer.slice(image: sheet, cols: 4, rows: 3)
    }

    // MARK: - Preload

    static func preloadAll() {
        let names = [
            playerWeapons, playerJump, playerIdleDance, playerHurt, playerDeath,
            playerWalkHandgun, playerWalkRifle, playerWalkBow, playerWalkUnarmed, playerRunning,
            playerShootHandgun, playerShootRifle, playerShootBow, playerShootBowFire, playerSwingBat,
            zombieWalk, zombieAttackBite, zombieHitBullet, zombieHitArrow,
            zombieDeathGrenade, zombieDeathFireArrow, zombieDeathArrow, zombieDeathBullet,
            zombieHitFireArrow,
            bulletHandgunAnim, bulletRifleAnim, arrowFireAnim, arrowNormalAnim, explosionSheet, grenadeImage,
            pickupHandgun, pickupRifle, pickupBow, pickupBat,
            pickupRifleAmmo, pickupArrowBag, pickupFireArrowBag,
            menuBackground, menuLogo, "MainLogoBachataAnimatonSpriteSheet1", startButton,
            inventoryButton, inventoryWeapons, iconHandgun,
            "road",
            "Level1", "Level2", "Level3", "Level4", "Level5"
        ]
        DispatchQueue.global(qos: .userInitiated).async {
            for n in names {
                _ = UIImage(named: n)
            }
        }
    }
}
