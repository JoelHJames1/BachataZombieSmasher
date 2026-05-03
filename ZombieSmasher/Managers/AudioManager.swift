import Foundation
import AVFoundation
import SpriteKit

/// Centralized audio for music + sound effects.
/// Honors `SaveManager.isMuted`. Background music loops on a single AVAudioPlayer.
enum AudioManager {

    private static var bgmPlayer: AVAudioPlayer?
    private static var currentTrack: String?

    // MARK: - Music

    static func playMusic(named filename: String, fileExt: String = "mp3", loop: Bool = true) {
        guard !SaveManager.isMuted else { return }
        if currentTrack == filename, bgmPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExt) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loop ? -1 : 0
            player.volume = 0.65
            player.prepareToPlay()
            player.play()
            bgmPlayer = player
            currentTrack = filename
        } catch {
            // Silent fail — audio is non-critical.
        }
    }

    static func stopMusic() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        currentTrack = nil
    }

    // MARK: - SFX

    /// Returns an SKAction that plays the named sound effect. Honors mute state.
    static func sfx(_ filename: String, ext: String = "mp3") -> SKAction {
        if SaveManager.isMuted { return SKAction.run {} }
        return SKAction.playSoundFileNamed("\(filename).\(ext)", waitForCompletion: false)
    }

    static func play(_ filename: String, ext: String = "mp3", on node: SKNode) {
        node.run(sfx(filename, ext: ext))
    }
}
