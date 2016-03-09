//
//  SmileRoundedTableViewCell.swift
//
//  Created by rain on 2/16/16.
//  Copyright © 2016 rain. All rights reserved.
//

import UIKit

private struct ConstraintHelper {
    enum Anchor: Int {
        case Top
        case Left
        case Right
        case Bottom
        case Count
        
        static var all: [Anchor] {
            let result = (0..<Anchor.Count.rawValue).map { Anchor(rawValue: $0)! }
            return result
        }
        
        static func anchorsExceptAnchor(anchor: Anchor) -> [Anchor] {
            let result = all.filter { $0.rawValue != anchor.rawValue }
            return result
        }
    }
    
    static func constraintWithAnchor(anchor: Anchor, constant: CGFloat = 0, fromView view: UIView, toView: UIView) -> NSLayoutConstraint {
        let constraint: NSLayoutConstraint
        switch anchor {
        case .Top:
            constraint = toView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: -constant)
        case .Left:
            constraint = toView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: -constant)
        case .Right:
            constraint = toView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: constant)
        case .Bottom:
            constraint = toView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: constant)
        case .Count:
            constraint = toView.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        }
        return constraint
    }
    
    static func adjoin(exceptAnchor anchor: Anchor = .Top, hasConstant constant: CGFloat = 0, fromView view: UIView, toView: UIView) {
        var constraints = [NSLayoutConstraint]()
        constraints.append(constraintWithAnchor(anchor, constant: constant, fromView: view, toView: toView))
        Anchor.anchorsExceptAnchor(anchor).forEach {
            constraints.append(constraintWithAnchor($0, fromView: view, toView: toView))
        }
        NSLayoutConstraint.activateConstraints(constraints)
    }
    
    static func adjoin(exceptAnchor anchor: Anchor, hasConstant constant: CGFloat, noAnchor: Anchor, withHeight height: CGFloat, fromView view: UIView, toView: UIView) {
        var constraints = [NSLayoutConstraint]()
        constraints.append(constraintWithAnchor(anchor, constant: constant, fromView: view, toView: toView))
        Anchor.anchorsExceptAnchor(anchor).filter { $0 != noAnchor }.forEach {
            constraints.append(constraintWithAnchor($0, fromView: view, toView: toView))
        }
        constraints.append(view.heightAnchor.constraintEqualToConstant(height))
        NSLayoutConstraint.activateConstraints(constraints)
    }
}

public class SmileRoundedTableViewCell: UITableViewCell {

    //MARK: Property Public
    public var margin: CGFloat = 28
    public var cornerRadius: CGFloat = 6 {
        didSet {
            self.roundView.layer.cornerRadius = cornerRadius
        }
    }
    public var frontColor = UIColor.whiteColor() {
        didSet {
            self.contentViews.forEach {
                $0.backgroundColor = frontColor
            }
        }
    }
    public var selectedColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1)
    override public var selectionStyle: UITableViewCellSelectionStyle {
        didSet(newValue) {
            needSelected = !(newValue.rawValue == 0)
        }
    }
    
    //MARK: Constant
    private let separatorLeftInset: CGFloat = 20
    
    //MARK: Property Private
    private let roundView = UIView()
    private let topView = UIView()
    private let bottomView = UIView()
    private let separatorView = UIView()
    private var contentViews: [UIView] {
        return [roundView, topView, bottomView]
    }
    private var needSelected: Bool = true
    private var separatorColor = UIColor(red: 206/255, green: 206/255, blue: 210/255, alpha: 1) {
        didSet {
            self.separatorView.backgroundColor = separatorColor
        }
    }
    
    //MARK: Setter
    override public var frame: CGRect {
        didSet(newFrame){
            super.frame.origin.x += margin
            guard let tableview = getTableview() else { return }
            guard tableview.frame.width == super.frame.size.width else { return }
            super.frame.size.width -= 2 * margin
        }
    }
    
    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        handleColor(highlighted, animated: animated)
    }

    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        handleColor(selected, animated: animated)
    }
    

    //MARK: Life Cycle
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let tableview = getTableview() else {
            return
        }
        
        //Because have made new separator view, so set separatorStyle to None
        tableview.separatorStyle = .None
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
 
        roundView.backgroundColor = frontColor
        topView.backgroundColor = frontColor
        bottomView.backgroundColor = frontColor
        
        roundView.layer.cornerRadius = cornerRadius
        
        self.insertSubview(roundView, belowSubview: self.contentView)
        self.insertSubview(topView, belowSubview: self.contentView)
        self.insertSubview(bottomView, belowSubview: self.roundView)
        
        self.contentView.backgroundColor = UIColor.clearColor()
        self.backgroundColor = UIColor.clearColor()
        
        roundView.translatesAutoresizingMaskIntoConstraints = false
        topView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        
        ConstraintHelper.adjoin(fromView: roundView, toView: self)
        ConstraintHelper.adjoin(exceptAnchor: .Bottom, hasConstant: cornerRadius, fromView: topView, toView: self)
        ConstraintHelper.adjoin(exceptAnchor: .Top, hasConstant: cornerRadius, fromView: bottomView, toView: self)
        
        //***separator
        separatorView.backgroundColor = separatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        topView.addSubview(separatorView)
        ConstraintHelper.adjoin(exceptAnchor: .Left, hasConstant: separatorLeftInset, noAnchor: .Bottom, withHeight: 0.5, fromView: separatorView, toView: topView)
        
        //Because use new roundView & topView & bottomView for selection, so disable default selectionStyle
        self.selectionStyle = .None
    }

    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateViewStyle()
    }
    
    //MARK: Help Method
    private func getTableview() -> UITableView? {
        guard let view = superview as? UITableView else {
            return superview?.superview as? UITableView
        }
        return view
    }
    
    private func updateViewStyle() {
        guard let tableView = getTableview(),
            let indexPath = tableView.indexPathForRowAtPoint(self.center) else { return }
        if indexPath.row == 0 && tableView.numberOfRowsInSection(indexPath.section) == 1 {
            self.topView.hidden = true
            self.bottomView.hidden = true
        } else if indexPath.row == 0 {
            self.topView.hidden = true
            self.bottomView.hidden = false
        } else if indexPath.row == tableView.numberOfRowsInSection(indexPath.section) - 1 {
            self.topView.hidden = false
            self.bottomView.hidden = true
        } else {
            self.topView.hidden = false
            self.bottomView.hidden = false
        }
        
        //handle tableView style api
        self.separatorView.hidden = (tableView.separatorStyle.rawValue == 0)
        
        guard let color = tableView.separatorColor else {
            return
        }
        self.selectedColor = color
    }
    
    ///Help Method For Cell Selection Color
    private func handleColor(highlighted: Bool, animated: Bool) {
        guard self.needSelected else {
            return
        }
        let color = currentColor(highlighted)
        changeViewsColor(self.contentViews, color: color, animated: animated)
    }
    
    private func changeViewsColor(views: [UIView], color: UIColor, animated: Bool) {
        let handle: [UIView] -> Void = { views in views.forEach { $0.backgroundColor = color } }
        guard animated else {
            handle(views)
            return
        }
        UIView.animateWithDuration(0.6) { () -> Void in
            handle(views)
        }
    }
    
    private func currentColor(highlighted: Bool) -> UIColor {
        guard highlighted else {
            return frontColor
        }
        return selectedColor
    }
    
}
