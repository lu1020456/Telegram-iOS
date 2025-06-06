import SGSimpleSettings
import Foundation
import UIKit
import AsyncDisplayKit
import Display

private extension ToolbarTheme {
    convenience init(tabBarTheme theme: TabBarControllerTheme) {
        self.init(barBackgroundColor: theme.tabBarBackgroundColor, barSeparatorColor: theme.tabBarSeparatorColor, barTextColor: theme.tabBarTextColor, barSelectedTextColor: theme.tabBarSelectedTextColor)
    }
}

final class TabBarControllerNode: ASDisplayNode {
    private var navigationBarPresentationData: NavigationBarPresentationData
    private let showTabNames: Bool // MARK: Swiftgram
    private var theme: TabBarControllerTheme
    let tabBarNode: TabBarNode
    private let disabledOverlayNode: ASDisplayNode
    private var toolbarNode: ToolbarNode?
    private let toolbarActionSelected: (ToolbarActionOption) -> Void
    private let disabledPressed: () -> Void

    var currentControllerNode: ASDisplayNode?
    
    func setCurrentControllerNode(_ node: ASDisplayNode?) -> () -> Void {
        guard node !== self.currentControllerNode else {
            return {}
        }
        
        let previousNode = self.currentControllerNode
        self.currentControllerNode = node
        if let currentControllerNode = self.currentControllerNode {
            if let previousNode {
                self.insertSubnode(currentControllerNode, aboveSubnode: previousNode)
            } else {
                self.insertSubnode(currentControllerNode, at: 0)
            }
        }
        
        return { [weak self, weak previousNode] in
            if previousNode !== self?.currentControllerNode {
                previousNode?.removeFromSupernode()
            }
        }
    }
    
    init(showTabNames: Bool, theme: TabBarControllerTheme, navigationBarPresentationData: NavigationBarPresentationData, itemSelected: @escaping (Int, Bool, [ASDisplayNode]) -> Void, contextAction: @escaping (Int, ContextExtractedContentContainingNode, ContextGesture) -> Void, swipeAction: @escaping (Int, TabBarItemSwipeDirection) -> Void, toolbarActionSelected: @escaping (ToolbarActionOption) -> Void, disabledPressed: @escaping () -> Void) {
        self.theme = theme
        self.showTabNames = showTabNames
        self.navigationBarPresentationData = navigationBarPresentationData
        self.tabBarNode = TabBarNode(showTabNames: showTabNames, theme: theme, itemSelected: itemSelected, contextAction: contextAction, swipeAction: swipeAction)
        self.tabBarNode.isHidden = SGSimpleSettings.shared.hideTabBar
        self.disabledOverlayNode = ASDisplayNode()
        self.disabledOverlayNode.backgroundColor = theme.backgroundColor.withAlphaComponent(0.5)
        self.disabledOverlayNode.alpha = 0.0
        self.toolbarActionSelected = toolbarActionSelected
        self.disabledPressed = disabledPressed
        
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = theme.backgroundColor
        
        self.addSubnode(self.tabBarNode)
        self.addSubnode(self.disabledOverlayNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.disabledOverlayNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.disabledTapGesture(_:))))
    }
    
    @objc private func disabledTapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.disabledPressed()
        }
    }
    
    func updateTheme(_ theme: TabBarControllerTheme, navigationBarPresentationData: NavigationBarPresentationData) {
        self.theme = theme
        self.navigationBarPresentationData = navigationBarPresentationData
        self.backgroundColor = theme.backgroundColor
        
        self.tabBarNode.updateTheme(theme)
        self.disabledOverlayNode.backgroundColor = theme.backgroundColor.withAlphaComponent(0.5)
        self.toolbarNode?.updateTheme(ToolbarTheme(tabBarTheme: theme))
    }
    
    func updateIsTabBarEnabled(_ value: Bool, transition: ContainedViewLayoutTransition) {
        transition.updateAlpha(node: self.disabledOverlayNode, alpha: value ? 0.0 : 1.0)
    }
    
    var tabBarHidden = SGSimpleSettings.shared.hideTabBar
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, toolbar: Toolbar?, transition: ContainedViewLayoutTransition) {
        var tabBarHeight: CGFloat
        var options: ContainerViewLayoutInsetOptions = []
        if layout.metrics.widthClass == .regular {
            options.insert(.input)
        }
        let bottomInset: CGFloat = layout.insets(options: options).bottom
        if !layout.safeInsets.left.isZero {
            tabBarHeight = 34.0 + bottomInset
            tabBarHeight = sgTabBarHeightModifier(showTabNames: self.showTabNames, tabBarHeight: tabBarHeight, layout: layout, defaultBarSmaller: true)  // MARK: Swiftgram
        } else {
            tabBarHeight = 49.0 + bottomInset
            tabBarHeight = sgTabBarHeightModifier(showTabNames: self.showTabNames, tabBarHeight: tabBarHeight, layout: layout, defaultBarSmaller: false)  // MARK: Swiftgram
        }
        
        let tabBarFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - (self.tabBarHidden ? 0.0 : tabBarHeight)), size: CGSize(width: layout.size.width, height: tabBarHeight))
        
        transition.updateFrame(node: self.tabBarNode, frame: tabBarFrame)
        self.tabBarNode.updateLayout(size: layout.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, additionalSideInsets: layout.additionalInsets, bottomInset: bottomInset, transition: transition)
        
        transition.updateFrame(node: self.disabledOverlayNode, frame: tabBarFrame)
        
        if let toolbar = toolbar {
            if let toolbarNode = self.toolbarNode {
                transition.updateFrame(node: toolbarNode, frame: tabBarFrame)
                toolbarNode.updateLayout(size: tabBarFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, additionalSideInsets: layout.additionalInsets, bottomInset: bottomInset, toolbar: toolbar, transition: transition)
            } else {
                let toolbarNode = ToolbarNode(theme: ToolbarTheme(tabBarTheme: self.theme), displaySeparator: true, left: { [weak self] in
                    self?.toolbarActionSelected(.left)
                }, right: { [weak self] in
                    self?.toolbarActionSelected(.right)
                }, middle: { [weak self] in
                    self?.toolbarActionSelected(.middle)
                })
                toolbarNode.frame = tabBarFrame
                toolbarNode.updateLayout(size: tabBarFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, additionalSideInsets: layout.additionalInsets, bottomInset: bottomInset, toolbar: toolbar, transition: .immediate)
                self.addSubnode(toolbarNode)
                self.toolbarNode = toolbarNode
                if transition.isAnimated {
                    toolbarNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                }
            }
        } else if let toolbarNode = self.toolbarNode {
            self.toolbarNode = nil
            transition.updateAlpha(node: toolbarNode, alpha: 0.0, completion: { [weak toolbarNode] _ in
                toolbarNode?.removeFromSupernode()
            })
        }
    }
}
