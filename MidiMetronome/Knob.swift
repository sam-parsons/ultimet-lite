//
//  Knob.swift
//  MidiMetronome
//
//  Created by Lorenzo Boaro.
//  Modified for MidiMetronome by Sam Parsons.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class Knob: UIControl {

    var minimumValue: Float = 30
    var maximumValue: Float = 260
    private (set) var value: Float = 0
    var isContinuous = true
    
    private let renderer = KnobRenderer()
    
    var lineWidth: CGFloat {
        get { return renderer.lineWidth }
        set { renderer.lineWidth = newValue }
    }
    
    var startAngle: CGFloat {
        get { return renderer.startAngle }
        set { renderer.startAngle = newValue }
    }
    
    var endAngle: CGFloat {
        get { return renderer.endAngle }
        set { renderer.endAngle = newValue}
    }
    
    var pointerLength: CGFloat {
        get { return renderer.pointerLength }
        set { renderer.pointerLength = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        renderer.updateBounds(bounds)
        renderer.color = tintColor
        renderer.setPointerAngle(renderer.startAngle, animated: false)
        
        layer.addSublayer(renderer.trackLayer)
        layer.addSublayer(renderer.pointerLayer)
        
        let gestureRecognizer = RotationGestureRecognizer(target:self, action: #selector(Knob.handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)
    }

    func setValue(_ newValue: Float, animated: Bool = false) {
        value = min(maximumValue, max(minimumValue, newValue))
        
        let angleRange = endAngle - startAngle
        let valueRange = maximumValue - minimumValue
        let angleValue = CGFloat(value - minimumValue) / CGFloat(valueRange) * angleRange + startAngle
        renderer.setPointerAngle(angleValue, animated: animated)
    }
    
    @objc private func handleGesture(_ gesture: RotationGestureRecognizer) {
        // 1
        let midPointAngle = (2 * CGFloat(Double.pi) + startAngle - endAngle) / 2 + endAngle
        // 2
        var boundedAngle = gesture.touchAngle
        if boundedAngle > midPointAngle {
            boundedAngle -= 2 * CGFloat(Double.pi)
        } else if boundedAngle < (midPointAngle - 2 * CGFloat(Double.pi)) {
            boundedAngle -= 2 * CGFloat(Double.pi)
        }
        
        // 3
        boundedAngle = min(endAngle, max(startAngle, boundedAngle))
        
        // 4
        let angleRange = endAngle - startAngle
        let valueRange = maximumValue - minimumValue
        let angleValue = Float(boundedAngle - startAngle) / Float(angleRange) * valueRange + minimumValue
        
        // 5
        setValue(angleValue)
        
        if isContinuous {
            sendActions(for: .valueChanged)
        } else {
            if gesture.state == .ended || gesture.state == .cancelled {
                sendActions(for: .valueChanged)
            }
        }
    }
}

private class KnobRenderer {
    var color: UIColor = .blue {
        didSet {
            trackLayer.strokeColor = color.cgColor
            pointerLayer.strokeColor = color.cgColor
        }
    }
    
    var lineWidth: CGFloat = 2 {
        didSet {
            trackLayer.lineWidth = lineWidth
            pointerLayer.lineWidth = lineWidth
            updateTrackLayerPath()
            updatePointerLayerPath()
        }
    }
    
    var startAngle: CGFloat = CGFloat(-Double.pi) * 11 / 8 {
        didSet {
            updateTrackLayerPath()
        }
    }
    
    var endAngle: CGFloat = CGFloat(Double.pi) * 3 / 8 {
        didSet {
            updateTrackLayerPath()
        }
    }
    
    var pointerLength: CGFloat = 6 {
        didSet {
            updateTrackLayerPath()
            updatePointerLayerPath()
        }
    }
    
    private (set) var pointerAngle: CGFloat = CGFloat(-Double.pi) * 11 / 8
    
    func setPointerAngle(_ newPointerAngle: CGFloat, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        pointerLayer.transform = CATransform3DMakeRotation(newPointerAngle, 0, 0, 1)
        
        if animated {
            let midAngleValue = (max(newPointerAngle, pointerAngle) - min(newPointerAngle, pointerAngle)) / 2 + min(newPointerAngle, pointerAngle)
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.values = [pointerAngle, midAngleValue, newPointerAngle]
            animation.keyTimes = [0.0, 0.5, 1.0]
            animation.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)]
            pointerLayer.add(animation, forKey: nil)
        }
        
        CATransaction.commit()
        
        pointerAngle = newPointerAngle
    }
    
    let trackLayer = CAShapeLayer()
    let pointerLayer = CAShapeLayer()
    
    init() {
        trackLayer.fillColor = UIColor.clear.cgColor
        pointerLayer.fillColor = UIColor.clear.cgColor
    }
    
    private func updateTrackLayerPath() {
        let bounds = trackLayer.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let offset = max(pointerLength, lineWidth / 2)
        let radius = min(bounds.width, bounds.height) / 2 - offset
        
        let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = ring.cgPath
    }
    
    private func updatePointerLayerPath() {
        let bounds = trackLayer.bounds
        
        let pointer = UIBezierPath()
        pointer.move(to: CGPoint(x: bounds.width - CGFloat(pointerLength) - CGFloat(lineWidth) / 2, y: bounds.midY))
        pointer.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        pointerLayer.path = pointer.cgPath
    }
    
    func updateBounds(_ bounds: CGRect) {
        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        updateTrackLayerPath()
        
        pointerLayer.bounds = trackLayer.bounds
        pointerLayer.position = trackLayer.position
        updatePointerLayerPath()
    }
}

private class RotationGestureRecognizer: UIPanGestureRecognizer {
    private(set) var touchAngle: CGFloat = 0
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        updateAngle(with: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        updateAngle(with: touches)
    }
    
    private func updateAngle(with touches: Set<UITouch>) {
        guard
            let touch = touches.first,
            let view = view
        else {
            return
        }
        let touchPoint = touch.location(in: view)
        touchAngle = angle(for: touchPoint, in: view)
    }
    
    private func angle(for point: CGPoint, in view: UIView) -> CGFloat {
        let centerOffset = CGPoint(x: point.x - view.bounds.midX, y: point.y - view.bounds.midY)
        return atan2(centerOffset.y, centerOffset.x)
    }
}
