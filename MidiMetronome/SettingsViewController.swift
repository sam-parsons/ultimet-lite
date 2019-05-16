//
//  SettingsViewController.swift
//  
//
//  Created by Sam Parsons.
//
// 

import UIKit
import AudioKit

protocol passDataBack {
    func setArrIndex(index: Int)
}

class SettingsViewController: UIViewController, UIWebViewDelegate, UINavigationControllerDelegate {

    var sequencer: AKSequencer?
    var arrIndexProtocol: passDataBack?
    
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var decFreqBtn: UIButton!
    @IBOutlet weak var incFreqBtn: UIButton!

    var beepNumberArr: [MIDINoteNumber] = []
    var beepNoteArr: [String] = [
        "A4", "Bb4", "B4", "C5", "Db5", "D5", "Eb5", "E5", "F5", "Gb5", "G5", "Ab5", "A5", "Bb5", "B5", "C6", "Db6", "D6", "Eb6", "E6", "F6", "Gb6", "G6", "Ab6", "A6"
    ]
    var arrIndex: Int = 12 // how to read this variable from segue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        
        for i in 0...25 { // should I just do this literally like beepNoteArr?
            var tempVar = i + 69
            beepNumberArr.append(MIDINoteNumber(tempVar))
        }

        freqLabel.text = beepNoteArr[arrIndex]
    }
    
    @IBAction func closeSettings(_ sender: Any)  {
        arrIndexProtocol?.setArrIndex(index: arrIndex)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func increaseFreq(_ sender: Any) {
        print("increasing frequency")
        var tempLabel = freqLabel.text
        generateMIDIOutput(note: tempLabel ?? "C5", incDec: true)
    }
    
    @IBAction func decreaseFreq(_ sender: Any) {
        print("decreasing frequency")
        var tempLabel = freqLabel.text
        generateMIDIOutput(note: tempLabel ?? "C5", incDec: false)
    }
    
    func generateMIDIOutput(note: String, incDec: Bool) {
        if (incDec) { // incDec is a bool to keep track which button pressed
            if arrIndex == 24 {
                print("max index")
            } else {
                print("increase button pressed")
                arrIndex = arrIndex + 1
                freqLabel.text = beepNoteArr[arrIndex]
                sequencer!.tracks[0].replaceMIDINoteData(with: [])
                var noteNum: MIDINoteNumber = MIDINoteNumber(beepNumberArr[arrIndex])
                for i in 0..<4 {
                    sequencer!.tracks[0].add(noteNumber: noteNum, velocity: 100, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.05))
                }
            }
        } else {
            if arrIndex == 0 {
                print("min index")
            } else {
                print("decrease button pressed")
                arrIndex = arrIndex - 1
                freqLabel.text = beepNoteArr[arrIndex]
                sequencer!.tracks[0].replaceMIDINoteData(with: [])
                var noteNum: MIDINoteNumber = MIDINoteNumber(beepNumberArr[arrIndex])
                for i in 0..<4 {
                    sequencer!.tracks[0].add(noteNumber: noteNum, velocity: 100, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.05))
                }
            }
        }
    }
    
    private func webViewDidFinishLoad(webView: UIWebView) {
        arrIndexProtocol?.setArrIndex(index: arrIndex)
    }
}
