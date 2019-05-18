//
//  ViewController.swift
//  MidiMetronome
//
//  Created by Sam Parsons on 12/12/18.
//  Copyright © 2018 Sam Parsons. All rights reserved.
//
//
//
// OPEN TICKETS
// 1. clear up handleSlider() logic
// 2. add constraints to storyboard to make responsive


import UIKit
import AudioKit
import JOCircularSlider

class ViewController: UIViewController, passDataBack {

    // visualization image
    @IBOutlet weak var imageView: UIImageView!
    
    // UI instantiation
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var tempoIndicator: UILabel!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var tap: UIButton!
    @IBOutlet weak var staticBpmLabel: UILabel!
    
    // AudioKit objects and data
    var sequencer = AKSequencer()
    var bpmValue: Int = 120
    var beepFreq: Double = 880.0
    var arrIndex: Int?
    var arrIndexSent: Int?
    var beep: AKOscillatorBank?
    
    // tap tempo data
    let interval: TimeInterval = 0.5
    let minTaps: Int = 3
    var taps: [Double] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        arrIndex = 12
        
        // slider format
        slider.minimumValue = 30
        slider.maximumValue = 260
        slider.value = 120
        slider.isContinuous = true
        
        // label format
        label.text = "120"
        
        // button format
        start.applyDesign()
        
        // visualization format
        self.imageView.isHidden = true
        
        // instrument set up - sound and callback
        beep = AKOscillatorBank.init(waveform: AKTable(.sine), attackDuration: 0.01, decayDuration: 0.05, sustainLevel: 0.1, releaseDuration:  0.05, pitchBend: 0, vibratoDepth: 0, vibratoRate: 0)
        let beepNode = AKMIDINode(node: beep!)
        let callbackInst = AKMIDICallbackInstrument()
        
        // AudioKit final set up phase
        AudioKit.output = beepNode
        try! AudioKit.start()
    
        // instantiating metronome and callback tracks and assigning their respective i/o
        _ = sequencer.newTrack()
        sequencer.tracks[0].setMIDIOutput(beepNode.midiIn)
        _ = sequencer.newTrack()
        sequencer.tracks[1].setMIDIOutput(callbackInst.midiIn)
        
        // sequencer settings initiation
        sequencer.setLength(AKDuration(beats: 4))
        sequencer.setTempo(120)
        sequencer.enableLooping()
    
        // add audio tracks to sequencer
        let noteNum = UInt8(beepFreq.frequencyToMIDINote())
        for i in 0..<4 {
            sequencer.tracks[0].add(noteNumber: noteNum, velocity: 100, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.05))
        }
        
        // add callback tracks to sequencer
        for i in 0..<4 {
            sequencer.tracks[1].add(noteNumber: MIDINoteNumber(i), velocity: 100, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.05))
        }

        // sequencer callback method
        callbackInst.callback = { status, noteNumber, velocity in
            if status == 144 {
                DispatchQueue.main.sync {
                    self.circularSlider.color1 = UIColor.white
                }
            } else if status == 128 {
                DispatchQueue.main.sync {
                    self.circularSlider.color1 = UIColor.lightGray
                }
            }
        }
        
        // set initial values for sliders and label
        updateTempoLabel(bpm: 120)
    }

    // play/stop button method
    @IBAction func handleToggle(_ sender: UIButton) {
        if sequencer.isPlaying {
            start.setTitle("Start", for: .normal) // What does for: .normal mean
            sequencer.stop()
        } else {
            sequencer.rewind()
            start.setTitle("Stop", for: .normal)
            sequencer.play()
        }
    }
    
    // handles both horizontal slider and circular knob
    @IBAction func handleSlider(_ sender: Any) {
        let tempTempo: Int = Int(slider.value)
        if sender is UISlider {
            circularSlider.value = CGFloat(slider.value)
            sequencer.setTempo(Double(tempTempo))
            label.text = "\(tempTempo)"
        } else if sender is JOCircularSlider.CircularSlider {
            slider.value = Float(circularSlider.value)
            sequencer.setTempo(Double(tempTempo))
            label.text = "\(tempTempo)"
        }
        updateTempoLabel(bpm: tempTempo)
    }
    
    @IBAction func handleTap(_ sender: Any) {
        let thisTap = NSDate()
        // checks if distance from last tap to current tap crosses threshold, if so, taps array wiped clean
        if taps.count > 0 && thisTap.timeIntervalSince1970 - taps[taps.count-1] > 2.0 {
            taps.removeAll()
        }
        var avg: Double
        if taps.count < 3 {
            taps.append(thisTap.timeIntervalSince1970)
            tap.setTitle("Keep Tapping", for: .normal) // this is useless with a button that uses an image
            // label on view controller says "keep tapping" until minTaps is met
        } else {
            taps.append(thisTap.timeIntervalSince1970)
            if taps.count == 3 {
                let first = taps[taps.count-1]
                let second = taps[taps.count-2]
                let third = taps[taps.count-3]
                avg = ((first-second)+(second-third)) / 2
            } else {
                let first = taps[taps.count-1]
                let second = taps[taps.count-2]
                let third = taps[taps.count-3]
                let fourth = taps[taps.count-4]
                avg = ((first-second)+(second-third)+(third-fourth)) / 3
            }
            print("bpm: ", Double(60/avg))
            bpmValue = Int(60/avg)
            let tempVal = Float(60/avg)
            label.text = "\(bpmValue)"
            slider.setValue(tempVal, animated: false)
            sequencer.setTempo(Double(bpmValue))
            circularSlider.value = CGFloat(tempVal)
            updateTempoLabel(bpm: bpmValue)
        }
        print("tap button pressed")
    }

    @IBAction func showSettings(_ sender: Any) {
        let settingsViewController = storyboard?.instantiateViewController(withIdentifier: "sbSettingsID") as! SettingsViewController
        // passing sequencer and arrIndex to instantiated settingsVC
        settingsViewController.sequencer = sequencer
        settingsViewController.arrIndex = arrIndex!
        settingsViewController.arrIndexProtocol = self
        present(settingsViewController, animated: true, completion: nil)
    }

    private func updateTempoLabel(bpm: Int) {
        if bpm < 45 {
            tempoIndicator.text = "Grave"
        } else if bpm < 60 {
            tempoIndicator.text = "Largo"
        } else if bpm < 66 {
            tempoIndicator.text = "Larghetto"
        } else if bpm < 76 {
            tempoIndicator.text = "Adagio"
        } else if bpm < 108 {
            tempoIndicator.text = "Andante"
        } else if bpm < 120 {
            tempoIndicator.text = "Moderato"
        } else if bpm < 156 {
            tempoIndicator.text = "Allegro"
        } else if bpm < 176 {
            tempoIndicator.text = "Vivace"
        } else if bpm < 200 {
            tempoIndicator.text = "Presto"
        } else if bpm >= 200 {
            tempoIndicator.text = "Prestissimo"
        }
    }
    
    func setArrIndex(index: Int) {
        arrIndex = index
    }
}

extension UIButton {
    func applyDesign() {
        self.layer.cornerRadius = 8
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}

extension CircularSlider {
    func applyDesign() {
        self.maximumValue = 260
        self.minimumValue = 30
    }
}

