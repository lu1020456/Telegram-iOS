import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import HierarchyTrackingLayer
import ShimmerEffect
import ManagedAnimationNode

private func generateIndefiniteActivityIndicatorImage(color: UIColor, diameter: CGFloat = 22.0, lineWidth: CGFloat = 2.0) -> UIImage? {
    return generateImage(CGSize(width: diameter, height: diameter), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        let cutoutAngle: CGFloat = CGFloat.pi * 60.0 / 180.0
        context.addArc(center: CGPoint(x: size.width / 2.0, y: size.height / 2.0), radius: size.width / 2.0 - lineWidth / 2.0, startAngle: 0.0, endAngle: CGFloat.pi * 2.0 - cutoutAngle, clockwise: false)
        context.strokePath()
    })
}

public final class SolidRoundedButtonTheme: Equatable {
    public let backgroundColor: UIColor
    public let backgroundColors: [UIColor]
    public let foregroundColor: UIColor
    public let disabledBackgroundColor: UIColor?
    public let disabledForegroundColor: UIColor?
    
    public init(backgroundColor: UIColor, backgroundColors: [UIColor] = [], foregroundColor: UIColor, disabledBackgroundColor: UIColor? = nil, disabledForegroundColor: UIColor? = nil) {
        self.backgroundColor = backgroundColor
        self.backgroundColors = backgroundColors
        self.foregroundColor = foregroundColor
        self.disabledBackgroundColor = disabledBackgroundColor
        self.disabledForegroundColor = disabledForegroundColor
    }
    
    public func withUpdated(disabledBackgroundColor: UIColor, disabledForegroundColor: UIColor) -> SolidRoundedButtonTheme {
        return SolidRoundedButtonTheme(backgroundColor: self.backgroundColor, backgroundColors: self.backgroundColors, foregroundColor: self.foregroundColor, disabledBackgroundColor: disabledBackgroundColor, disabledForegroundColor: disabledForegroundColor)
    }
    
    public static func ==(lhs: SolidRoundedButtonTheme, rhs: SolidRoundedButtonTheme) -> Bool {
        if lhs.backgroundColor != rhs.backgroundColor {
            return false
        }
        if lhs.backgroundColors != rhs.backgroundColors {
            return false
        }
        if lhs.foregroundColor != rhs.foregroundColor {
            return false
        }
        if lhs.disabledBackgroundColor != rhs.disabledBackgroundColor {
            return false
        }
        if lhs.disabledForegroundColor != rhs.disabledForegroundColor {
            return false
        }
        return true
    }
}

public enum SolidRoundedButtonFont {
    case bold
    case regular
}

public enum SolidRoundedButtonIconPosition {
    case left
    case right
}

public enum SolidRoundedButtonProgressType {
    case fullSize
    case embedded
}

private final class BadgeNode: ASDisplayNode {
    private var fillColor: UIColor
    private var strokeColor: UIColor
    private var textColor: UIColor
    
    private let textNode: ImmediateTextNode
    private let backgroundNode: ASImageNode
    
    private let font: UIFont = Font.with(size: 15.0, design: .round, weight: .bold)
    
    var text: String = "" {
        didSet {
            self.textNode.attributedText = NSAttributedString(string: self.text, font: self.font, textColor: self.textColor)
            self.invalidateCalculatedLayout()
        }
    }
    
    init(fillColor: UIColor, strokeColor: UIColor, textColor: UIColor) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.textColor = textColor
        
        self.textNode = ImmediateTextNode()
        self.textNode.isUserInteractionEnabled = false
        self.textNode.displaysAsynchronously = false
        
        self.backgroundNode = ASImageNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: fillColor, strokeColor: nil, strokeWidth: 1.0)
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.textNode)
        
        self.isUserInteractionEnabled = false
    }
    
    func updateTheme(fillColor: UIColor, strokeColor: UIColor, textColor: UIColor) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.textColor = textColor
        self.backgroundNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: fillColor, strokeColor: strokeColor, strokeWidth: 1.0)
        self.textNode.attributedText = NSAttributedString(string: self.text, font: self.font, textColor: self.textColor)
    }
    
    func animateBump(incremented: Bool) {
        if incremented {
            let firstTransition = ContainedViewLayoutTransition.animated(duration: 0.1, curve: .easeInOut)
            firstTransition.updateTransformScale(layer: self.backgroundNode.layer, scale: 1.2)
            firstTransition.updateTransformScale(layer: self.textNode.layer, scale: 1.2, completion: { finished in
                if finished {
                    let secondTransition = ContainedViewLayoutTransition.animated(duration: 0.1, curve: .easeInOut)
                    secondTransition.updateTransformScale(layer: self.backgroundNode.layer, scale: 1.0)
                    secondTransition.updateTransformScale(layer: self.textNode.layer, scale: 1.0)
                }
            })
        } else {
            let firstTransition = ContainedViewLayoutTransition.animated(duration: 0.1, curve: .easeInOut)
            firstTransition.updateTransformScale(layer: self.backgroundNode.layer, scale: 0.8)
            firstTransition.updateTransformScale(layer: self.textNode.layer, scale: 0.8, completion: { finished in
                if finished {
                    let secondTransition = ContainedViewLayoutTransition.animated(duration: 0.1, curve: .easeInOut)
                    secondTransition.updateTransformScale(layer: self.backgroundNode.layer, scale: 1.0)
                    secondTransition.updateTransformScale(layer: self.textNode.layer, scale: 1.0)
                }
            })
        }
    }
    
    func animateOut() {
        let timingFunction = CAMediaTimingFunctionName.easeInEaseOut.rawValue
        self.backgroundNode.layer.animateScale(from: 1.0, to: 0.1, duration: 0.3, delay: 0.0, timingFunction: timingFunction, removeOnCompletion: true, completion: nil)
        self.textNode.layer.animateScale(from: 1.0, to: 0.1, duration: 0.3, delay: 0.0, timingFunction: timingFunction, removeOnCompletion: true, completion: nil)
    }
    
    func update(_ constrainedSize: CGSize) -> CGSize {
        let badgeSize = self.textNode.updateLayout(constrainedSize)
        let backgroundSize = CGSize(width: max(18.0, badgeSize.width + 8.0), height: 18.0)
        let backgroundFrame = CGRect(origin: CGPoint(), size: backgroundSize)
        self.backgroundNode.frame = backgroundFrame
        self.textNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels(backgroundFrame.midX - badgeSize.width / 2.0), y: floorToScreenPixels((backgroundFrame.size.height - badgeSize.height) / 2.0) - UIScreenPixel), size: badgeSize)
        
        return backgroundSize
    }
}

public final class SolidRoundedButtonNode: ASDisplayNode {
    private var theme: SolidRoundedButtonTheme
    private var fontSize: CGFloat
    private let gloss: Bool
    
    public let buttonBackgroundNode: ASImageNode
    private var buttonBackgroundAnimationView: UIImageView?
    
    private var shimmerView: ShimmerEffectForegroundView?
    private var borderView: UIView?
    private var borderMaskView: UIView?
    private var borderShimmerView: ShimmerEffectForegroundView?
        
    private let buttonNode: HighlightTrackingButtonNode
    public let titleNode: ImmediateTextNode
    private let subtitleNode: ImmediateTextNode
    private let iconNode: ASImageNode
    private var animationNode: SimpleAnimationNode?
    private var progressNode: ASImageNode?
    private var badgeNode: BadgeNode?
    
    private let buttonHeight: CGFloat
    public let buttonCornerRadius: CGFloat
    
    public var pressed: (() -> Void)?
    public var validLayout: CGFloat?
    
    public var isEnabled: Bool = true {
        didSet {
            if self.isEnabled != oldValue {
                self.updateColors(animated: true)
            }
            self.updateAccessibilityLabels()
        }
    }
    
    public var title: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var font: SolidRoundedButtonFont {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var subtitle: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, previousSubtitle: oldValue, transition: .immediate)
            }
        }
    }
    
    public var badge: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var icon: UIImage? {
        didSet {
            self.iconNode.image = generateTintedImage(image: self.icon, color: self.theme.foregroundColor)
        }
    }
    
    private func updateAccessibilityLabels() {
        self.accessibilityLabel = (self.title ?? "") + " " + (self.subtitle ?? "")
        if !self.isEnabled {
            self.accessibilityTraits = [.button, .notEnabled]
        } else {
            self.accessibilityTraits = [.button]
        }
    }
    
    public var animationLoopTime: Double = 4.0
    private var animationTimer: SwiftSignalKit.Timer?
    public var animation: String? {
        didSet {
            if let animation = self.animation {
                if animation != oldValue {
                    self.animationNode?.removeFromSupernode()
                    self.animationNode = nil
                    
                    let animationNode = SimpleAnimationNode(animationName: animation, size: CGSize(width: 30.0, height: 30.0))
                    animationNode.customColor = self.theme.foregroundColor
                    animationNode.isUserInteractionEnabled = false
                    self.addSubnode(animationNode)
                    self.animationNode = animationNode
                    
                    if let width = self.validLayout {
                        _ = self.updateLayout(width: width, transition: .immediate)
                    }
                    
                    if self.gloss {
                        self.animationTimer?.invalidate()
                        
                        Queue.mainQueue().after(1.25) {
                            self.animationNode?.play()
                            
                            let timer = SwiftSignalKit.Timer(timeout: self.animationLoopTime, repeat: true, completion: { [weak self] in
                                self?.animationNode?.play()
                            }, queue: Queue.mainQueue())
                            self.animationTimer = timer
                            timer.start()
                        }
                    } else {
                        self.animationNode?.play()
                        let timer = SwiftSignalKit.Timer(timeout: self.animationLoopTime, repeat: true, completion: { [weak self] in
                            self?.animationNode?.play()
                        }, queue: Queue.mainQueue())
                        self.animationTimer = timer
                        timer.start()
                    }
                }
            } else if let animationNode = self.animationNode {
                animationNode.removeFromSupernode()
                self.animationNode = nil
            }
        }
    }
    
    public var iconSpacing: CGFloat = 8.0 {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var animationSize: CGSize = CGSize(width: 30.0, height: 30.0) {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var iconPosition: SolidRoundedButtonIconPosition = .left {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var progressType: SolidRoundedButtonProgressType = .fullSize
        
    public var highlightEnabled = true {
        didSet {
            if !self.highlightEnabled {
                self.buttonBackgroundNode.alpha = 1.0
                self.titleNode.alpha = 1.0
                self.subtitleNode.alpha = 1.0
                self.iconNode.alpha = 1.0
                self.animationNode?.alpha = 1.0
                self.buttonBackgroundNode.layer.removeAnimation(forKey: "opacity")
                self.titleNode.layer.removeAnimation(forKey: "opacity")
                self.subtitleNode.layer.removeAnimation(forKey: "opacity")
                self.iconNode.layer.removeAnimation(forKey: "opacity")
                self.animationNode?.layer.removeAnimation(forKey: "opacity")
            }
        }
    }
    
    public init(title: String? = nil, icon: UIImage? = nil, theme: SolidRoundedButtonTheme, font: SolidRoundedButtonFont = .bold, fontSize: CGFloat = 17.0, height: CGFloat = 48.0, cornerRadius: CGFloat = 24.0, gloss: Bool = false) {
        self.theme = theme
        self.font = font
        self.fontSize = fontSize
        self.buttonHeight = height
        self.buttonCornerRadius = cornerRadius
        self.title = title
        self.gloss = gloss
        
        self.buttonBackgroundNode = ASImageNode()
        self.buttonBackgroundNode.displaysAsynchronously = false
        self.buttonBackgroundNode.clipsToBounds = true
        
        self.buttonBackgroundNode.backgroundColor = theme.backgroundColor
        if theme.backgroundColors.count > 1 {
            self.buttonBackgroundNode.backgroundColor = nil
            
            var locations: [CGFloat] = []
            let delta = 1.0 / CGFloat(theme.backgroundColors.count - 1)
            for i in 0 ..< theme.backgroundColors.count {
                locations.append(delta * CGFloat(i))
            }
            self.buttonBackgroundNode.image = generateGradientImage(size: CGSize(width: 200.0, height: height), colors: theme.backgroundColors, locations: locations, direction: .horizontal)
            
            let buttonBackgroundAnimationView = UIImageView()
            buttonBackgroundAnimationView.image = generateGradientImage(size: CGSize(width: 200.0, height: height), colors: theme.backgroundColors, locations: locations, direction: .horizontal)
            self.buttonBackgroundAnimationView = buttonBackgroundAnimationView
        }
        
        self.buttonBackgroundNode.cornerRadius = cornerRadius
                
        self.buttonNode = HighlightTrackingButtonNode()
        
        self.titleNode = ImmediateTextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.displaysAsynchronously = false
        
        self.subtitleNode = ImmediateTextNode()
        self.subtitleNode.isUserInteractionEnabled = false
        self.subtitleNode.displaysAsynchronously = false
        
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.image = generateTintedImage(image: icon, color: self.theme.foregroundColor)
        self.iconNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.isAccessibilityElement = true
        
        self.addSubnode(self.buttonBackgroundNode)
        self.addSubnode(self.buttonNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
        self.addSubnode(self.iconNode)
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
        self.buttonNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self, strongSelf.isEnabled && strongSelf.highlightEnabled {
                if highlighted {
                    strongSelf.buttonBackgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.buttonBackgroundNode.alpha = 0.55
                    strongSelf.titleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.titleNode.alpha = 0.55
                    strongSelf.subtitleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.subtitleNode.alpha = 0.55
                    strongSelf.iconNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.iconNode.alpha = 0.55
                    strongSelf.animationNode?.layer.removeAnimation(forKey: "opacity")
                    strongSelf.animationNode?.alpha = 0.55
                } else {
                    if strongSelf.buttonBackgroundNode.alpha > 0.0 {
                        strongSelf.buttonBackgroundNode.alpha = 1.0
                        strongSelf.buttonBackgroundNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.titleNode.alpha = 1.0
                        strongSelf.titleNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.subtitleNode.alpha = 1.0
                        strongSelf.subtitleNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.iconNode.alpha = 1.0
                        strongSelf.iconNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.animationNode?.alpha = 1.0
                        strongSelf.animationNode?.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                    }
                }
            }
        }
        
        self.updateAccessibilityLabels()
    }
    
    public override func didLoad() {
        super.didLoad()
        
        if #available(iOS 13.0, *) {
            self.buttonBackgroundNode.layer.cornerCurve = .continuous
        }
        
        if let buttonBackgroundAnimationView = self.buttonBackgroundAnimationView {
            self.buttonBackgroundNode.view.addSubview(buttonBackgroundAnimationView)
        }
        
        self.setupGloss()
    }
        
    private func setupGloss() {
        if self.gloss {
            if self.shimmerView == nil {
                let shimmerView = ShimmerEffectForegroundView()
                self.shimmerView = shimmerView
                
                if #available(iOS 13.0, *) {
                    shimmerView.layer.cornerCurve = .continuous
                    shimmerView.layer.cornerRadius = self.buttonCornerRadius
                }
                
                let borderView = UIView()
                borderView.isUserInteractionEnabled = false
                self.borderView = borderView
                
                let borderMaskView = UIView()
                borderMaskView.layer.borderWidth = 1.0 + UIScreenPixel
                borderMaskView.layer.borderColor = UIColor.white.cgColor
                borderMaskView.layer.cornerRadius = self.buttonCornerRadius
                borderView.mask = borderMaskView
                self.borderMaskView = borderMaskView
                
                let borderShimmerView = ShimmerEffectForegroundView()
                self.borderShimmerView = borderShimmerView
                borderView.addSubview(borderShimmerView)
                
                self.view.insertSubview(shimmerView, belowSubview: self.buttonNode.view)
                self.view.insertSubview(borderView, belowSubview: self.buttonNode.view)
                
                self.updateShimmerParameters()
                
                if let width = self.validLayout {
                    _ = self.updateLayout(width: width, transition: .immediate)
                }
            }
        } else if self.shimmerView != nil {
            self.shimmerView?.removeFromSuperview()
            self.borderView?.removeFromSuperview()
            self.borderMaskView?.removeFromSuperview()
            self.borderShimmerView?.removeFromSuperview()
            
            self.shimmerView = nil
            self.borderView = nil
            self.borderMaskView = nil
            self.borderShimmerView = nil
        }
    }
    
    public func animateTitle(to title: String) {        
        Queue.mainQueue().justDispatch {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: false) {
                snapshotView.frame = self.bounds
                
                self.view.addSubview(snapshotView)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
            }
            
            self.title = title
            self.buttonBackgroundNode.backgroundColor = self.theme.disabledBackgroundColor
            self.isEnabled = false
        }
    }
    
    private func setupGradientAnimations() {
        guard let buttonBackgroundAnimationView = self.buttonBackgroundAnimationView else {
            return
        }

        if let _ = buttonBackgroundAnimationView.layer.animation(forKey: "movement") {
        } else {
            let offset = (buttonBackgroundAnimationView.frame.width - self.frame.width) / 2.0
            let previousValue = buttonBackgroundAnimationView.center.x
            var newValue: CGFloat = offset
            if offset - previousValue < buttonBackgroundAnimationView.frame.width * 0.25 {
                newValue -= buttonBackgroundAnimationView.frame.width * 0.35
            }
            buttonBackgroundAnimationView.center = CGPoint(x: newValue, y: buttonBackgroundAnimationView.bounds.size.height / 2.0)
            
            CATransaction.begin()
            
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.duration = 4.5
            animation.fromValue = previousValue
            animation.toValue = newValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            CATransaction.setCompletionBlock { [weak self] in
//                if let isCurrentlyInHierarchy = self?.isCurrentlyInHierarchy, isCurrentlyInHierarchy {
                    self?.setupGradientAnimations()
//                }
            }

            buttonBackgroundAnimationView.layer.add(animation, forKey: "movement")
            CATransaction.commit()
        }
    }
    
    func updateShimmerParameters() {
        guard let shimmerView = self.shimmerView, let borderShimmerView = self.borderShimmerView else {
            return
        }
        
        let color = self.theme.foregroundColor
        let alpha: CGFloat
        let borderAlpha: CGFloat
        let compositingFilter: String?
        if color.lightness > 0.5 {
            alpha = 0.5
            borderAlpha = 0.75
            compositingFilter = "overlayBlendMode"
        } else {
            alpha = 0.2
            borderAlpha = 0.3
            compositingFilter = nil
        }
        
        shimmerView.update(backgroundColor: .clear, foregroundColor: color.withAlphaComponent(alpha), gradientSize: 70.0, globalTimeOffset: false, duration: 4.0, horizontal: true)
        borderShimmerView.update(backgroundColor: .clear, foregroundColor: color.withAlphaComponent(borderAlpha), gradientSize: 70.0, globalTimeOffset: false, duration: 4.0, horizontal: true)
        
        shimmerView.layer.compositingFilter = compositingFilter
        borderShimmerView.layer.compositingFilter = compositingFilter
    }
    
    public func updateTheme(_ theme: SolidRoundedButtonTheme, animated: Bool = false) {
        guard theme !== self.theme else {
            return
        }
        let previousTheme = self.theme
        self.theme = theme
        
        let animateTransition = previousTheme.backgroundColors.count != theme.backgroundColors.count
        
        if animated && animateTransition {
            if let snapshotView = self.buttonBackgroundNode.view.snapshotView(afterScreenUpdates: false) {
                self.view.insertSubview(snapshotView, aboveSubview: self.buttonBackgroundNode.view)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
            }
            
            if let snapshotView = self.titleNode.view.snapshotView(afterScreenUpdates: false) {
                snapshotView.frame = self.titleNode.frame
                
                self.view.insertSubview(snapshotView, aboveSubview: self.titleNode.view)
                snapshotView.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: 15.0), duration: 0.2, removeOnCompletion: false, additive: true)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
                self.titleNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -15.0), to: CGPoint(), duration: 0.2, additive: true)
                self.titleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
            
            if let snapshotView = self.iconNode.view.snapshotView(afterScreenUpdates: false) {
                snapshotView.frame = self.iconNode.frame
                
                self.view.insertSubview(snapshotView, aboveSubview: self.iconNode.view)
                snapshotView.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: 15.0), duration: 0.2, removeOnCompletion: false, additive: true)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
                self.iconNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -15.0), to: CGPoint(), duration: 0.2, additive: true)
                self.iconNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
            
            if let animationNode = self.animationNode, let snapshotView = animationNode.view.snapshotView(afterScreenUpdates: false) {
                snapshotView.frame = animationNode.frame
                
                self.view.insertSubview(snapshotView, aboveSubview: animationNode.view)
                snapshotView.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: 15.0), duration: 0.2, removeOnCompletion: false, additive: true)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
                animationNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -15.0), to: CGPoint(), duration: 0.2, additive: true)
                animationNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
        
        self.iconNode.image = generateTintedImage(image: self.iconNode.image, color: theme.foregroundColor)
        self.animationNode?.customColor = theme.foregroundColor
        
        self.updateColors(animated: false)
                
        self.updateShimmerParameters()
    }
    
    func updateColors(animated: Bool) {
        if animated {
            if let snapshotView = self.view.snapshotView(afterScreenUpdates: false) {
                self.view.addSubview(snapshotView)
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                    snapshotView?.removeFromSuperview()
                })
            }
        }
        
        if !self.isEnabled, let disabledBackgroundColor = self.theme.disabledBackgroundColor, let disabledForegroundColor = self.theme.disabledForegroundColor {
            self.titleNode.attributedText = NSAttributedString(string: self.title ?? "", font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: disabledForegroundColor)
            self.subtitleNode.attributedText = NSAttributedString(string: self.subtitle ?? "", font: Font.regular(14.0), textColor: disabledForegroundColor)
            
            self.buttonBackgroundNode.backgroundColor = disabledBackgroundColor
        } else {
            self.titleNode.attributedText = NSAttributedString(string: self.title ?? "", font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: self.theme.foregroundColor)
            self.subtitleNode.attributedText = NSAttributedString(string: self.subtitle ?? "", font: Font.regular(14.0), textColor: self.theme.foregroundColor)
            
            self.buttonBackgroundNode.backgroundColor = theme.backgroundColor
            if theme.backgroundColors.count > 1 {
                self.buttonBackgroundNode.backgroundColor = nil
                
                var locations: [CGFloat] = []
                let delta = 1.0 / CGFloat(theme.backgroundColors.count - 1)
                for i in 0 ..< theme.backgroundColors.count {
                    locations.append(delta * CGFloat(i))
                }
                self.buttonBackgroundNode.image = generateGradientImage(size: CGSize(width: 200.0, height: self.buttonHeight), colors: theme.backgroundColors, locations: locations, direction: .horizontal)
                
                if self.buttonBackgroundAnimationView == nil {
                    let buttonBackgroundAnimationView = UIImageView()
                    self.buttonBackgroundAnimationView = buttonBackgroundAnimationView
                    self.buttonBackgroundNode.view.addSubview(buttonBackgroundAnimationView)
                }
                
                self.buttonBackgroundAnimationView?.image = self.buttonBackgroundNode.image
            } else {
                self.buttonBackgroundNode.image = nil
                self.buttonBackgroundAnimationView?.image = nil
            }
        }
        
        if let width = self.validLayout {
            _ = self.updateLayout(width: width, transition: .immediate)
        }
    }
    
    public func sizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let titleSize = self.titleNode.updateLayout(constrainedSize)
        return CGSize(width: titleSize.width + 20.0, height: self.buttonHeight)
    }
    
    public func updateLayout(width: CGFloat, transition: ContainedViewLayoutTransition) -> CGFloat {
        return self.updateLayout(width: width, previousSubtitle: self.subtitle, transition: transition)
    }
    
    private func updateLayout(width: CGFloat, previousSubtitle: String?, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayout = width
        
        let buttonSize = CGSize(width: width, height: self.buttonHeight)
        let buttonFrame = CGRect(origin: CGPoint(), size: buttonSize)
        transition.updateFrame(node: self.buttonBackgroundNode, frame: buttonFrame)
        
        if let shimmerView = self.shimmerView, let borderView = self.borderView, let borderMaskView = self.borderMaskView, let borderShimmerView = self.borderShimmerView {
            transition.updateFrame(view: shimmerView, frame: buttonFrame)
            transition.updateFrame(view: borderView, frame: buttonFrame)
            transition.updateFrame(view: borderMaskView, frame: buttonFrame)
            transition.updateFrame(view: borderShimmerView, frame: buttonFrame)
            
            shimmerView.updateAbsoluteRect(CGRect(origin: CGPoint(x: width * 4.0, y: 0.0), size: buttonSize), within: CGSize(width: width * 9.0, height: buttonHeight))
            borderShimmerView.updateAbsoluteRect(CGRect(origin: CGPoint(x: width * 4.0, y: 0.0), size: buttonSize), within: CGSize(width: width * 9.0, height: buttonHeight))
        }
        
        if let buttonBackgroundAnimationView = self.buttonBackgroundAnimationView {
            buttonBackgroundAnimationView.bounds = CGRect(origin: CGPoint(), size: CGSize(width: buttonSize.width * 2.4, height: buttonSize.height))
            if buttonBackgroundAnimationView.layer.animation(forKey: "movement") == nil {
                buttonBackgroundAnimationView.center = CGPoint(x: buttonSize.width * 2.4 / 2.0 - buttonBackgroundAnimationView.frame.width * 0.35, y: buttonSize.height / 2.0)
            }
            self.setupGradientAnimations()
        }
        
        transition.updateFrame(node: self.buttonNode, frame: buttonFrame)
        
        if self.title != self.titleNode.attributedText?.string {
            self.titleNode.attributedText = NSAttributedString(string: self.title ?? "", font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: self.isEnabled ? self.theme.foregroundColor : (self.theme.disabledForegroundColor ?? self.theme.foregroundColor))
        }
        
        let iconSize: CGSize
        if let _ = self.animationNode {
            iconSize = self.animationSize
        } else {
            iconSize = self.iconNode.image?.size ?? CGSize()
        }
        let titleSize = self.titleNode.updateLayout(buttonSize)
        
        let spacingOffset: CGFloat = 9.0
        let verticalInset: CGFloat = self.subtitle == nil ? floor((buttonFrame.height - titleSize.height) / 2.0) : floor((buttonFrame.height - titleSize.height) / 2.0) - spacingOffset

        let iconSpacing: CGFloat = self.iconSpacing
        
        var contentWidth: CGFloat = titleSize.width
        if !iconSize.width.isZero {
            contentWidth += iconSize.width + iconSpacing
        }
        var nextContentOrigin = floor((buttonFrame.width - contentWidth) / 2.0)
        
        let iconFrame: CGRect
        var titleFrame: CGRect
        switch self.iconPosition {
            case .left:
                iconFrame =  CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: floor((buttonFrame.height - iconSize.height) / 2.0)), size: iconSize)
                if !iconSize.width.isZero {
                    nextContentOrigin += iconSize.width + iconSpacing
                }
                titleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: buttonFrame.minY + verticalInset), size: titleSize)
            case .right:
                titleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: buttonFrame.minY + verticalInset), size: titleSize)
                if !iconSize.width.isZero {
                    nextContentOrigin += titleFrame.width + iconSpacing
                }
                iconFrame =  CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: floor((buttonFrame.height - iconSize.height) / 2.0)), size: iconSize)
        }
        
        transition.updateFrame(node: self.iconNode, frame: iconFrame)
        if let animationNode = self.animationNode {
            transition.updateFrame(node: animationNode, frame: iconFrame)
        }
        
        if let badge = self.badge {
            let badgeNode: BadgeNode
            if let current = self.badgeNode {
                badgeNode = current
            } else {
                badgeNode = BadgeNode(fillColor: self.theme.foregroundColor, strokeColor: .clear, textColor: self.theme.backgroundColor)
                self.badgeNode = badgeNode
                self.addSubnode(badgeNode)
            }
            badgeNode.text = badge
            let badgeSize = badgeNode.update(CGSize(width: 100.0, height: 100.0))
            titleFrame.origin.x -= badgeSize.width / 2.0
            transition.updateFrame(node: badgeNode, frame: CGRect(origin: CGPoint(x: titleFrame.maxX + 6.0, y: titleFrame.minY + floorToScreenPixels((titleFrame.height - badgeSize.height) * 0.5)), size: badgeSize))
        } else if let badgeNode = self.badgeNode {
            self.badgeNode = nil
            badgeNode.removeFromSupernode()
        }
        
        transition.updateFrame(node: self.titleNode, frame: titleFrame)
        
        if self.subtitle != self.subtitleNode.attributedText?.string {
            self.subtitleNode.attributedText = NSAttributedString(string: self.subtitle ?? "", font: Font.regular(14.0), textColor: self.theme.foregroundColor)
        }
        
        let subtitleSize = self.subtitleNode.updateLayout(buttonSize)
        let subtitleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + floor((buttonFrame.width - subtitleSize.width) / 2.0), y: buttonFrame.minY + floor((buttonFrame.height - titleSize.height) / 2.0) + spacingOffset + 2.0), size: subtitleSize)
        transition.updateFrame(node: self.subtitleNode, frame: subtitleFrame)
        
        if previousSubtitle == nil && self.subtitle != nil {
            self.titleNode.layer.animatePosition(from: CGPoint(x: 0.0, y: spacingOffset / 2.0), to: CGPoint(), duration: 0.3, additive: true)
            self.subtitleNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -spacingOffset / 2.0), to: CGPoint(), duration: 0.3, additive: true)
            self.subtitleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        }
        
        return buttonSize.height
    }
    
    @objc private func buttonPressed() {
        if self.isEnabled {
            self.pressed?()
        }
    }
    
    public func transitionToProgress() {
        guard self.progressNode == nil else {
            return
        }
        
        self.isUserInteractionEnabled = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        rotationAnimation.duration = 1.0
        rotationAnimation.fromValue = NSNumber(value: Float(0.0))
        rotationAnimation.toValue = NSNumber(value: Float.pi * 2.0)
        rotationAnimation.repeatCount = Float.infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        rotationAnimation.beginTime = 1.0
        
        let buttonOffset = self.buttonBackgroundNode.frame.minX
        let buttonWidth = self.buttonBackgroundNode.frame.width
        
        let progressNode = ASImageNode()
        
        switch self.progressType {
            case .fullSize:
                let progressFrame = CGRect(origin: CGPoint(x: floorToScreenPixels(buttonOffset + (buttonWidth - self.buttonHeight) / 2.0), y: 0.0), size: CGSize(width: self.buttonHeight, height: self.buttonHeight))
                progressNode.frame = progressFrame
                progressNode.image = generateIndefiniteActivityIndicatorImage(color: self.buttonBackgroundNode.backgroundColor ?? .clear, diameter: self.buttonHeight, lineWidth: 2.0 + UIScreenPixel)
                                
                self.buttonBackgroundNode.layer.cornerRadius = self.buttonHeight / 2.0
                self.buttonBackgroundNode.layer.animate(from: self.buttonCornerRadius as NSNumber, to: self.buttonHeight / 2.0 as NSNumber, keyPath: "cornerRadius", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.2)
                self.buttonBackgroundNode.layer.animateFrame(from: self.buttonBackgroundNode.frame, to: progressFrame, duration: 0.2)
                
                self.buttonBackgroundNode.alpha = 0.0
                self.buttonBackgroundNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2, removeOnCompletion: false)
                            
                self.insertSubnode(progressNode, at: 0)
            case .embedded:
                let diameter: CGFloat = self.buttonHeight - 22.0
                let progressFrame = CGRect(origin: CGPoint(x: floorToScreenPixels(buttonOffset + (buttonWidth - diameter) / 2.0), y: floorToScreenPixels((self.buttonHeight - diameter) / 2.0)), size: CGSize(width: diameter, height: diameter))
                progressNode.frame = progressFrame
            
                if !self.isEnabled, let disabledForegroundColor = self.theme.disabledForegroundColor {
                    progressNode.image = generateIndefiniteActivityIndicatorImage(color: disabledForegroundColor, diameter: diameter, lineWidth: 3.0)
                } else {
                    progressNode.image = generateIndefiniteActivityIndicatorImage(color: self.theme.foregroundColor, diameter: diameter, lineWidth: 3.0)
                }
                self.addSubnode(progressNode)
        }
        
        progressNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        progressNode.layer.add(rotationAnimation, forKey: "progressRotation")
        self.progressNode = progressNode
        
        self.titleNode.alpha = 0.0
        self.titleNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.subtitleNode.alpha = 0.0
        self.subtitleNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.badgeNode?.alpha = 0.0
        self.badgeNode?.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.shimmerView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        self.borderShimmerView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    public func transitionFromProgress() {
        guard let progressNode = self.progressNode else {
            return
        }
        self.progressNode = nil
        
        switch self.progressType {
            case .fullSize:
                self.buttonBackgroundNode.layer.cornerRadius = self.buttonCornerRadius
                self.buttonBackgroundNode.layer.animate(from: self.buttonHeight / 2.0 as NSNumber, to: self.buttonCornerRadius as NSNumber, keyPath: "cornerRadius", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.2)
                self.buttonBackgroundNode.layer.animateFrame(from: progressNode.frame, to: self.bounds, duration: 0.2)
                
                self.buttonBackgroundNode.alpha = 1.0
                self.buttonBackgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2, removeOnCompletion: false)
            case .embedded:
                break
        }
        
        progressNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak progressNode, weak self] _ in
            progressNode?.removeFromSupernode()
            self?.isUserInteractionEnabled = true
        })
        
        self.titleNode.alpha = 1.0
        self.titleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.subtitleNode.alpha = 1.0
        self.subtitleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.badgeNode?.alpha = 1.0
        self.badgeNode?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.shimmerView?.layer.removeAllAnimations()
        self.shimmerView?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        self.borderShimmerView?.layer.removeAllAnimations()
        self.borderShimmerView?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
}

public final class SolidRoundedButtonView: UIView {
    private var theme: SolidRoundedButtonTheme
    private var font: SolidRoundedButtonFont
    private var fontSize: CGFloat
    
    private let buttonBackgroundNode: UIImageView
    private var buttonBackgroundAnimationView: UIImageView?
    
    private var shimmerView: ShimmerEffectForegroundView?
    private var borderView: UIView?
    private var borderMaskView: UIView?
    private var borderShimmerView: ShimmerEffectForegroundView?
    
    private let buttonNode: HighlightTrackingButton
    private let titleNode: ImmediateTextView
    private let subtitleNode: ImmediateTextView
    private let iconNode: UIImageView
    private var animationNode: SimpleAnimationNode?
    private var progressNode: UIImageView?
    private var badgeNode: BadgeNode?
    
    private let buttonHeight: CGFloat
    private let buttonCornerRadius: CGFloat
    
    public var pressed: (() -> Void)?
    public var validLayout: CGFloat?
    
    public var title: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var label: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var subtitle: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, previousSubtitle: oldValue, transition: .immediate)
            }
        }
    }
    
    public var badge: String? {
        didSet {
            self.updateAccessibilityLabels()
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    private func updateAccessibilityLabels() {
        self.accessibilityLabel = (self.title ?? "") + " " + (self.subtitle ?? "")
        self.accessibilityValue = self.label
        if !self.isEnabled {
            self.accessibilityTraits = [.button, .notEnabled]
        } else {
            self.accessibilityTraits = [.button]
        }
    }
    
    public var icon: UIImage? {
        didSet {
            self.iconNode.image = generateTintedImage(image: self.icon, color: self.theme.foregroundColor)
        }
    }
    
    public var isEnabled: Bool = true {
        didSet {
            if self.isEnabled != oldValue {
                self.titleNode.alpha = self.isEnabled ? 1.0 : 0.6
            }
            self.updateAccessibilityLabels()
        }
    }
    
    public var animationLoopTime: Double = 4.0
    private var animationTimer: SwiftSignalKit.Timer?
    public var animation: String? {
        didSet {
            if let animation = self.animation {
                if animation != oldValue {
                    self.animationNode?.view.removeFromSuperview()
                    self.animationNode = nil
                    
                    let animationNode = SimpleAnimationNode(animationName: animation, size: CGSize(width: 30.0, height: 30.0))
                    animationNode.customColor = self.theme.foregroundColor
                    animationNode.isUserInteractionEnabled = false
                    self.addSubview(animationNode.view)
                    self.animationNode = animationNode
                    
                    if let width = self.validLayout {
                        _ = self.updateLayout(width: width, transition: .immediate)
                    }
                    
                    if self.gloss {
                        self.animationTimer?.invalidate()
                        
                        Queue.mainQueue().after(1.25) {
                            self.animationNode?.play()
                            
                            let timer = SwiftSignalKit.Timer(timeout: self.animationLoopTime, repeat: true, completion: { [weak self] in
                                self?.animationNode?.play()
                            }, queue: Queue.mainQueue())
                            self.animationTimer = timer
                            timer.start()
                        }
                    } else {
                        self.animationNode?.play()
                        let timer = SwiftSignalKit.Timer(timeout: self.animationLoopTime, repeat: true, completion: { [weak self] in
                            self?.animationNode?.play()
                        }, queue: Queue.mainQueue())
                        self.animationTimer = timer
                        timer.start()
                    }
                }
            } else if let animationNode = self.animationNode {
                animationNode.view.removeFromSuperview()
                self.animationNode = nil
                
                self.animationTimer?.invalidate()
                self.animationTimer = nil
            }
        }
    }
    
    public var iconSpacing: CGFloat = 8.0 {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var iconPosition: SolidRoundedButtonIconPosition = .left {
        didSet {
            if let width = self.validLayout {
                _ = self.updateLayout(width: width, transition: .immediate)
            }
        }
    }
    
    public var gloss: Bool {
        didSet {
            if self.gloss != oldValue {
                self.setupGloss()
            }
        }
    }
    
    public var progressType: SolidRoundedButtonProgressType = .fullSize
    
    public init(title: String? = nil, label: String? = nil, badge: String? = nil, icon: UIImage? = nil, theme: SolidRoundedButtonTheme, font: SolidRoundedButtonFont = .bold, fontSize: CGFloat = 17.0, height: CGFloat = 48.0, cornerRadius: CGFloat = 24.0, gloss: Bool = false) {
        self.theme = theme
        self.font = font
        self.fontSize = fontSize
        self.buttonHeight = height
        self.buttonCornerRadius = cornerRadius
        self.title = title
        self.label = label
        self.badge = badge
        self.gloss = gloss
        
        self.buttonBackgroundNode = UIImageView()
        self.buttonBackgroundNode.clipsToBounds = true
        self.buttonBackgroundNode.layer.cornerRadius = cornerRadius
        if #available(iOS 13.0, *) {
            self.buttonBackgroundNode.layer.cornerCurve = .continuous
        }
        
        self.buttonBackgroundNode.backgroundColor = theme.backgroundColor
        if theme.backgroundColors.count > 1 {
            var locations: [CGFloat] = []
            let delta = 1.0 / CGFloat(theme.backgroundColors.count - 1)
            for i in 0 ..< theme.backgroundColors.count {
                locations.append(delta * CGFloat(i))
            }
            self.buttonBackgroundNode.image = generateGradientImage(size: CGSize(width: 200.0, height: height), colors: theme.backgroundColors, locations: locations, direction: .horizontal)
            
            let buttonBackgroundAnimationView = UIImageView()
            buttonBackgroundAnimationView.image = self.buttonBackgroundNode.image
            self.buttonBackgroundNode.addSubview(buttonBackgroundAnimationView)
            self.buttonBackgroundAnimationView = buttonBackgroundAnimationView
        }
                
        self.buttonNode = HighlightTrackingButton()
        self.buttonNode.isMultipleTouchEnabled = false
        self.buttonNode.isExclusiveTouch = true
        
        self.titleNode = ImmediateTextView()
        self.titleNode.isUserInteractionEnabled = false
        
        self.subtitleNode = ImmediateTextView()
        self.subtitleNode.isUserInteractionEnabled = false
        
        self.iconNode = UIImageView()
        self.iconNode.image = generateTintedImage(image: icon, color: self.theme.foregroundColor)
        
        super.init(frame: CGRect())
        
        self.isAccessibilityElement = true
        
        self.addSubview(self.buttonBackgroundNode)
        self.addSubview(self.buttonNode)
        self.addSubview(self.titleNode)
        self.addSubview(self.subtitleNode)
        self.addSubview(self.iconNode)
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        
        self.buttonNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.buttonBackgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.buttonBackgroundNode.alpha = 0.55
                    strongSelf.titleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.titleNode.alpha = 0.55
                    strongSelf.subtitleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.subtitleNode.alpha = 0.55
                    strongSelf.iconNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.iconNode.alpha = 0.55
                    strongSelf.animationNode?.layer.removeAnimation(forKey: "opacity")
                    strongSelf.animationNode?.alpha = 0.55
                    strongSelf.badgeNode?.layer.removeAnimation(forKey: "opacity")
                    strongSelf.badgeNode?.alpha = 0.55
                } else {
                    if strongSelf.buttonBackgroundNode.alpha > 0.0 {
                        strongSelf.buttonBackgroundNode.alpha = 1.0
                        strongSelf.buttonBackgroundNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.titleNode.alpha = 1.0
                        strongSelf.titleNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.subtitleNode.alpha = 1.0
                        strongSelf.subtitleNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.iconNode.alpha = 1.0
                        strongSelf.iconNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.animationNode?.alpha = 1.0
                        strongSelf.animationNode?.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                        strongSelf.badgeNode?.alpha = 1.0
                        strongSelf.badgeNode?.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                    }
                }
            }
        }
        
        if #available(iOS 13.0, *) {
            self.buttonBackgroundNode.layer.cornerCurve = .continuous
        }
        
        self.updateAccessibilityLabels()
    }
        
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.animationTimer?.invalidate()
    }
    
    private func setupGloss() {
        if self.gloss {
            if self.shimmerView == nil {
                let shimmerView = ShimmerEffectForegroundView()
                self.shimmerView = shimmerView
                
                if #available(iOS 13.0, *) {
                    shimmerView.layer.cornerCurve = .continuous
                    shimmerView.layer.cornerRadius = self.buttonCornerRadius
                }
                
                let borderView = UIView()
                borderView.isUserInteractionEnabled = false
                self.borderView = borderView
                
                let borderMaskView = UIView()
                borderMaskView.layer.borderWidth = 1.0 + UIScreenPixel
                borderMaskView.layer.borderColor = UIColor.white.cgColor
                borderMaskView.layer.cornerRadius = self.buttonCornerRadius
                borderView.mask = borderMaskView
                self.borderMaskView = borderMaskView
                
                let borderShimmerView = ShimmerEffectForegroundView()
                self.borderShimmerView = borderShimmerView
                borderView.addSubview(borderShimmerView)
                
                self.insertSubview(shimmerView, belowSubview: self.buttonNode)
                self.insertSubview(borderView, belowSubview: self.buttonNode)
                
                self.updateShimmerParameters()
                
                if let width = self.validLayout {
                    _ = self.updateLayout(width: width, transition: .immediate)
                }
            }
        } else if self.shimmerView != nil {
            self.shimmerView?.removeFromSuperview()
            self.borderView?.removeFromSuperview()
            self.borderMaskView?.removeFromSuperview()
            self.borderShimmerView?.removeFromSuperview()
            
            self.shimmerView = nil
            self.borderView = nil
            self.borderMaskView = nil
            self.borderShimmerView = nil
        }
    }
    
    private func setupGradientAnimations() {
        guard let buttonBackgroundAnimationView = self.buttonBackgroundAnimationView else {
            return
        }

        if let _ = buttonBackgroundAnimationView.layer.animation(forKey: "movement") {
        } else {
            let offset = (buttonBackgroundAnimationView.frame.width - self.frame.width) / 2.0
            let previousValue = buttonBackgroundAnimationView.center.x
            var newValue: CGFloat = offset
            if offset - previousValue < buttonBackgroundAnimationView.frame.width * 0.25 {
                newValue -= buttonBackgroundAnimationView.frame.width * 0.35
            }
            buttonBackgroundAnimationView.center = CGPoint(x: newValue, y: buttonBackgroundAnimationView.bounds.size.height / 2.0)
            
            CATransaction.begin()
            
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.duration = 4.5
            animation.fromValue = previousValue
            animation.toValue = newValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            CATransaction.setCompletionBlock { [weak self] in
//                if let isCurrentlyInHierarchy = self?.isCurrentlyInHierarchy, isCurrentlyInHierarchy {
                    self?.setupGradientAnimations()
//                }
            }

            buttonBackgroundAnimationView.layer.add(animation, forKey: "movement")
            CATransaction.commit()
        }
    }
    
    public func transitionToProgress() {
        guard self.progressNode == nil else {
            return
        }
        
        self.isUserInteractionEnabled = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        rotationAnimation.duration = 1.0
        rotationAnimation.fromValue = NSNumber(value: Float(0.0))
        rotationAnimation.toValue = NSNumber(value: Float.pi * 2.0)
        rotationAnimation.repeatCount = Float.infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        rotationAnimation.beginTime = 1.0
        
        let buttonOffset = self.buttonBackgroundNode.frame.minX
        let buttonWidth = self.buttonBackgroundNode.frame.width
        
        let progressNode = UIImageView()
        
        switch self.progressType {
            case .fullSize:
                let progressFrame = CGRect(origin: CGPoint(x: floorToScreenPixels(buttonOffset + (buttonWidth - self.buttonHeight) / 2.0), y: 0.0), size: CGSize(width: self.buttonHeight, height: self.buttonHeight))
                progressNode.frame = progressFrame
                progressNode.image = generateIndefiniteActivityIndicatorImage(color: self.buttonBackgroundNode.backgroundColor ?? .clear, diameter: self.buttonHeight, lineWidth: 2.0 + UIScreenPixel)
                                
                self.buttonBackgroundNode.layer.cornerRadius = self.buttonHeight / 2.0
                self.buttonBackgroundNode.layer.animate(from: self.buttonCornerRadius as NSNumber, to: self.buttonHeight / 2.0 as NSNumber, keyPath: "cornerRadius", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.2)
                self.buttonBackgroundNode.layer.animateFrame(from: self.buttonBackgroundNode.frame, to: progressFrame, duration: 0.2)
                
                self.buttonBackgroundNode.alpha = 0.0
                self.buttonBackgroundNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2, removeOnCompletion: false)
                                
                self.insertSubview(progressNode, at: 0)
            case .embedded:
                let diameter: CGFloat = self.buttonHeight - 22.0
                let progressFrame = CGRect(origin: CGPoint(x: floorToScreenPixels(buttonOffset + (buttonWidth - diameter) / 2.0), y: floorToScreenPixels((self.buttonHeight - diameter) / 2.0)), size: CGSize(width: diameter, height: diameter))
                progressNode.frame = progressFrame
                progressNode.image = generateIndefiniteActivityIndicatorImage(color: self.theme.foregroundColor, diameter: diameter, lineWidth: 3.0)
                    
                self.addSubview(progressNode)
        }
        
        progressNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        progressNode.layer.add(rotationAnimation, forKey: "progressRotation")
        self.progressNode = progressNode
        
        self.titleNode.alpha = 0.0
        self.titleNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.subtitleNode.alpha = 0.0
        self.subtitleNode.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.badgeNode?.alpha = 0.0
        self.badgeNode?.layer.animateAlpha(from: 0.55, to: 0.0, duration: 0.2)
        
        self.shimmerView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        self.borderShimmerView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    public func transitionFromProgress() {
        guard let progressNode = self.progressNode else {
            return
        }
        self.progressNode = nil
        
        switch self.progressType {
            case .fullSize:
                self.buttonBackgroundNode.layer.cornerRadius = self.buttonCornerRadius
                self.buttonBackgroundNode.layer.animate(from: self.buttonHeight / 2.0 as NSNumber, to: self.buttonCornerRadius as NSNumber, keyPath: "cornerRadius", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.2)
                self.buttonBackgroundNode.layer.animateFrame(from: progressNode.frame, to: self.bounds, duration: 0.2)
                
                self.buttonBackgroundNode.alpha = 1.0
                self.buttonBackgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2, removeOnCompletion: false)
            case .embedded:
                break
        }
        
        progressNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak progressNode, weak self] _ in
            progressNode?.removeFromSuperview()
            self?.isUserInteractionEnabled = true
        })
        
        self.titleNode.alpha = 1.0
        self.titleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.subtitleNode.alpha = 1.0
        self.subtitleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.badgeNode?.alpha = 1.0
        self.badgeNode?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        
        self.shimmerView?.layer.removeAllAnimations()
        self.shimmerView?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        self.borderShimmerView?.layer.removeAllAnimations()
        self.borderShimmerView?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    func updateShimmerParameters() {
        guard let shimmerView = self.shimmerView, let borderShimmerView = self.borderShimmerView else {
            return
        }
        
        let color = self.theme.foregroundColor
        let alpha: CGFloat
        let borderAlpha: CGFloat
        let compositingFilter: String?
        if color.lightness > 0.5 {
            alpha = 0.5
            borderAlpha = 0.75
            compositingFilter = "overlayBlendMode"
        } else {
            alpha = 0.2
            borderAlpha = 0.3
            compositingFilter = nil
        }
        
        let globalTimeOffset = self.icon == nil && self.animation == nil
        
        shimmerView.update(backgroundColor: .clear, foregroundColor: color.withAlphaComponent(alpha), gradientSize: 70.0, globalTimeOffset: globalTimeOffset, duration: 4.0, horizontal: true)
        borderShimmerView.update(backgroundColor: .clear, foregroundColor: color.withAlphaComponent(borderAlpha), gradientSize: 70.0, globalTimeOffset: globalTimeOffset, duration: 4.0, horizontal: true)
        
        shimmerView.layer.compositingFilter = compositingFilter
        borderShimmerView.layer.compositingFilter = compositingFilter
    }
    
    public func updateTheme(_ theme: SolidRoundedButtonTheme) {
        guard theme !== self.theme else {
            return
        }
        self.theme = theme
        
        self.buttonBackgroundNode.backgroundColor = theme.backgroundColor
        if theme.backgroundColors.count > 1 {
            var locations: [CGFloat] = []
            let delta = 1.0 / CGFloat(theme.backgroundColors.count - 1)
            for i in 0 ..< theme.backgroundColors.count {
                locations.append(delta * CGFloat(i))
            }
            self.buttonBackgroundNode.image = generateGradientImage(size: CGSize(width: 200.0, height: self.buttonHeight), colors: theme.backgroundColors, locations: locations, direction: .horizontal)
            self.buttonBackgroundAnimationView?.image = self.buttonBackgroundNode.image
        } else {
            self.buttonBackgroundNode.image = nil
            self.buttonBackgroundAnimationView?.image = nil
        }
        
        let titleText = NSMutableAttributedString()
        titleText.append(NSAttributedString(string: self.title ?? "", font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: theme.foregroundColor))
        if let label = self.label {
            titleText.append(NSAttributedString(string: " " + label, font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: theme.foregroundColor.withAlphaComponent(0.6)))
        }
        
        self.titleNode.attributedText = titleText
        self.subtitleNode.attributedText = NSAttributedString(string: self.subtitle ?? "", font: Font.medium(11.0), textColor: theme.foregroundColor.withAlphaComponent(0.7))
        
        self.iconNode.image = generateTintedImage(image: self.iconNode.image, color: theme.foregroundColor)
        
        if let width = self.validLayout {
            _ = self.updateLayout(width: width, transition: .immediate)
        }
        
        self.updateShimmerParameters()
    }
    
    public func updateLayout(width: CGFloat, transition: ContainedViewLayoutTransition) -> CGFloat {
        return self.updateLayout(width: width, previousSubtitle: self.subtitle, transition: transition)
    }
    
    private func updateLayout(width: CGFloat, previousSubtitle: String?, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayout = width
        
        self.setupGloss()
        
        let buttonSize = CGSize(width: width, height: self.buttonHeight)
        let buttonFrame = CGRect(origin: CGPoint(), size: buttonSize)
        transition.updateFrame(view: self.buttonBackgroundNode, frame: buttonFrame)
        
        if let shimmerView = self.shimmerView, let borderView = self.borderView, let borderMaskView = self.borderMaskView, let borderShimmerView = self.borderShimmerView {
            transition.updateFrame(view: shimmerView, frame: buttonFrame)
            transition.updateFrame(view: borderView, frame: buttonFrame)
            transition.updateFrame(view: borderMaskView, frame: buttonFrame)
            transition.updateFrame(view: borderShimmerView, frame: buttonFrame)
            
            shimmerView.updateAbsoluteRect(CGRect(origin: CGPoint(x: width * 4.0, y: 0.0), size: buttonSize), within: CGSize(width: width * 9.0, height: buttonHeight))
            borderShimmerView.updateAbsoluteRect(CGRect(origin: CGPoint(x: width * 4.0, y: 0.0), size: buttonSize), within: CGSize(width: width * 9.0, height: buttonHeight))
        }
        
        if let buttonBackgroundAnimationView = self.buttonBackgroundAnimationView {
            buttonBackgroundAnimationView.bounds = CGRect(origin: CGPoint(), size: CGSize(width: buttonSize.width * 2.4, height: buttonSize.height))
            if buttonBackgroundAnimationView.layer.animation(forKey: "movement") == nil {
                buttonBackgroundAnimationView.center = CGPoint(x: buttonSize.width * 2.4 / 2.0 - buttonBackgroundAnimationView.frame.width * 0.35, y: buttonSize.height / 2.0)
            }
            self.setupGradientAnimations()
        }

        transition.updateFrame(view: self.buttonNode, frame: buttonFrame)
        
        let titleText = NSMutableAttributedString()
        titleText.append(NSAttributedString(string: self.title ?? "", font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: theme.foregroundColor))
        if let label = self.label {
            titleText.append(NSAttributedString(string: " " + label, font: self.font == .bold ? Font.semibold(self.fontSize) : Font.regular(self.fontSize), textColor: theme.foregroundColor.withAlphaComponent(0.6)))
        }
        
        self.titleNode.attributedText = titleText
        
        let iconSize: CGSize
        if let _ = self.animationNode {
            iconSize = CGSize(width: 30.0, height: 30.0)
        } else {
            iconSize = self.iconNode.image?.size ?? CGSize()
        }
        let titleSize = self.titleNode.updateLayout(buttonSize)
        
        let spacingOffset: CGFloat = 7.0
        let verticalInset: CGFloat = self.subtitle == nil ? floor((buttonFrame.height - titleSize.height) / 2.0) : floor((buttonFrame.height - titleSize.height) / 2.0) - spacingOffset
        let iconSpacing: CGFloat = self.iconSpacing
        let badgeSpacing: CGFloat = 6.0
        
        var contentWidth: CGFloat = titleSize.width
        if !iconSize.width.isZero {
            contentWidth += iconSize.width + iconSpacing
        }
        
        var badgeSize: CGSize = .zero
        if let badge = self.badge {
            let badgeNode: BadgeNode
            if let current = self.badgeNode {
                badgeNode = current
            } else {
                badgeNode = BadgeNode(fillColor: self.theme.foregroundColor, strokeColor: .clear, textColor: self.theme.backgroundColor)
                badgeNode.alpha = self.titleNode.alpha == 0.0 ? 0.0 : 1.0
                self.badgeNode = badgeNode
                self.addSubnode(badgeNode)
            }
            badgeNode.text = badge
            badgeSize = badgeNode.update(CGSize(width: 100.0, height: 100.0))
            
            contentWidth += badgeSize.width + badgeSpacing
        } else if let badgeNode = self.badgeNode {
            self.badgeNode = nil
            badgeNode.removeFromSupernode()
        }
        
        var nextContentOrigin = floor((buttonFrame.width - contentWidth) / 2.0)
      
        let iconFrame: CGRect
        let titleFrame: CGRect
        switch self.iconPosition {
            case .left:
                iconFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: floor((buttonFrame.height - iconSize.height) / 2.0)), size: iconSize)
                if !iconSize.width.isZero {
                    nextContentOrigin += iconSize.width + iconSpacing
                }
                titleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: buttonFrame.minY + verticalInset), size: titleSize)
            case .right:
                titleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: buttonFrame.minY + verticalInset), size: titleSize)
                if !iconSize.width.isZero {
                    nextContentOrigin += titleFrame.width + iconSpacing
                }
                iconFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + nextContentOrigin, y: floor((buttonFrame.height - iconSize.height) / 2.0)), size: iconSize)
        }
        let badgeFrame = CGRect(origin: CGPoint(x: titleFrame.maxX + badgeSpacing, y: titleFrame.minY + floor((titleFrame.height - badgeSize.height) * 0.5)), size: badgeSize)
        
        transition.updateFrame(view: self.iconNode, frame: iconFrame)
        if let animationNode = self.animationNode {
            transition.updateFrame(view: animationNode.view, frame: iconFrame)
        }
        transition.updateFrame(view: self.titleNode, frame: titleFrame)
        
        if let badgeNode = self.badgeNode {
            transition.updateFrame(node: badgeNode, frame: badgeFrame)
        }
        
        if self.subtitle != self.subtitleNode.attributedText?.string {
            self.subtitleNode.attributedText = NSAttributedString(string: self.subtitle ?? "", font: Font.medium(11.0), textColor: self.theme.foregroundColor.withAlphaComponent(0.7))
        }
        
        let subtitleSize = self.subtitleNode.updateLayout(buttonSize)
        let subtitleFrame = CGRect(origin: CGPoint(x: buttonFrame.minX + floor((buttonFrame.width - subtitleSize.width) / 2.0), y: buttonFrame.minY + floor((buttonFrame.height - titleSize.height) / 2.0) + spacingOffset + 7.0), size: subtitleSize)
        transition.updateFrame(view: self.subtitleNode, frame: subtitleFrame)
        
        if previousSubtitle == nil && self.subtitle != nil {
            self.titleNode.layer.animatePosition(from: CGPoint(x: 0.0, y: spacingOffset / 2.0), to: CGPoint(), duration: 0.3, additive: true)
            self.subtitleNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -spacingOffset / 2.0), to: CGPoint(), duration: 0.3, additive: true)
            self.subtitleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        }
        
        return buttonSize.height
    }
    
    @objc private func buttonPressed() {
        self.pressed?()
    }
}
