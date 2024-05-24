//
//  SoundEffectModel.swift
//  gARffiti
//
//  Created by Paulus Michael on 24/05/24.
//

import AVFoundation

struct SoundEffectModel {
    var audioPlayer: AVAudioPlayer?
    
    mutating func audioAssign(_ url: URL) -> AVAudioPlayer? {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            return audioPlayer
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func audioStop(){
        guard let player = audioPlayer else { return }
        player.stop()
    }
}
