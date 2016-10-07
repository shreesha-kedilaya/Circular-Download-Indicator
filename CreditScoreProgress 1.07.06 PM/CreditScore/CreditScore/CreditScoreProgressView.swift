//
//  CreditScoreProgressView.swift
//  CreditScore
//
//  Created by Shreesha on 26/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import UIKit

/// This view is used to show the current credit score on top of the credit score 'headerView'.
/// View takes startLimit, endLimit and the currentValue of the credit score to plot the respective graph.

class CreditScoreProgressView: UIView {

    ///This is the path used to plot static backgroudCircularLayer.
    private var backgrounCircularPath: UIBezierPath!
    ///This is the path used for current progress of the credit score value.
    private var progressPath: UIBezierPath!
    ///This is the backgroud static grayed out part.
    private var backgroundCircularLayer: CAShapeLayer!
    ///The layer used to show the present value of the progress.
    private var progressLayer: CAShapeLayer!
    ///The label to show the startLimit of the creditScore.
    private var leftIndicatorLable: UILabel!
    ///The label to show the endLimit of the creditScore.
    private var rightIndicatorLable: UILabel!
    ///The label to show the current Value of the credit score.
    private var centerCurrentValueLabel: UILabel!

    ///Start angle can be give to the graph default 135.
    var startAngle: CGFloat = 135
    ///End angle can be give to the graph default 45.
    var endAngle: CGFloat = 45

    ///Start value limit given to the graph.
    var startValueLimit: CGFloat = 300 {
        didSet{
            leftIndicatorLable.text = startValueLimit.string0
        }
    }

    ///End value limit given to the graph.
    var endValueLimit: CGFloat = 800 {
        didSet {
            rightIndicatorLable.text = endValueLimit.string0
        }
    }

    ///Current value of the creditScore given to the graph.
    var currentValue: CGFloat = 700 {
        didSet {
            centerCurrentValueLabel.text = currentValue.string0
        }
    }

    ///Changing the font of the left and right value indicators.
    var fontForValueIndicators = UIFont.systemFont(ofSize: 15) {
        didSet {
            leftIndicatorLable.font = fontForValueIndicators
            rightIndicatorLable.font = fontForValueIndicators
        }
    }

    ///Font the label at the center of the view.
    var fontForCenterValueLabel = UIFont.systemFont(ofSize: 24) {
        didSet {
            centerCurrentValueLabel.font = fontForCenterValueLabel
        }
    }

    ///Property to change the color for all the labels.
    var textColorForLabels = UIColor.white {
        didSet {
            centerCurrentValueLabel.textColor = textColorForLabels
            rightIndicatorLable.textColor = textColorForLabels
            leftIndicatorLable.textColor = textColorForLabels
        }
    }

    //MARK: view life cycle.
    override func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }

    ///Default initializer.
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    ///Layout subviews method.
    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundCircularLayer = getBackgroundLayer()
        let radius = bounds.width > bounds.height ? bounds.height: bounds.width
        backgrounCircularPath = UIBezierPath(arcCenter: backgroundCircularLayer.position, radius: (radius - 20) / 2, startAngle: startAngle.rad, endAngle: endAngle.rad, clockwise: true)

        backgroundCircularLayer.path = backgrounCircularPath.cgPath
        layer.insertSublayer(backgroundCircularLayer, at: 0)

        recalculateAllFrames()
    }

    ///Method to recalculate all the subview frames.
    private func recalculateAllFrames() {
        let leftFrame = frameForLeftLabel()
        let rightFrame = frameForRightLabel()

        leftIndicatorLable?.frame = leftFrame
        rightIndicatorLable?.frame = rightFrame

        centerCurrentValueLabel?.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        centerCurrentValueLabel?.center = backgroundCircularLayer.position
        rightIndicatorLable.sizeToFit()
        leftIndicatorLable.sizeToFit()
        centerCurrentValueLabel.sizeToFit()
    }

    ///Method to return the background static layer.
    private func getBackgroundLayer() -> CAShapeLayer {
        let backgroundCircularLayer = CAShapeLayer()
        self.backgroundCircularLayer?.removeFromSuperlayer()
        backgroundCircularLayer.frame = bounds

        backgroundCircularLayer.fillColor = backgroundColor?.cgColor
        backgroundCircularLayer.lineWidth = 13
        backgroundCircularLayer.fillRule = kCAFillRuleEvenOdd
        backgroundCircularLayer.strokeColor = UIColor.lightGray.cgColor
        backgroundCircularLayer.strokeStart = 0
        backgroundCircularLayer.strokeEnd = 1
        backgroundCircularLayer.lineCap = kCALineCapRound
        return backgroundCircularLayer
    }

    ///Common method for all the initializers.
    private func sharedInit() {

        addAllLabels()
        backgroundColor = UIColor.brown

    }

    ///Gives the frame for right label.
    private func frameForRightLabel() -> CGRect{
        let radius = bounds.width > bounds.height ? bounds.height: bounds.width
        let originPoint = getPointOnCircumference(center: backgroundCircularLayer.position, radius: radius / 2, angle: endAngle.rad)
        let frame = CGRect(x: originPoint.x - (rightIndicatorLable.bounds.width / 2), y: originPoint.y + 10, width: 50, height: 20)
        return frame
    }

    ///Gives the frame for left label.
    private func frameForLeftLabel() -> CGRect{
        let radius = bounds.width > bounds.height ? bounds.height: bounds.width
        let originPoint = getPointOnCircumference(center: backgroundCircularLayer.position, radius: radius / 2, angle: startAngle.rad)
        let frame = CGRect(x: originPoint.x - (leftIndicatorLable.bounds.width / 2), y: originPoint.y + 10, width: 50, height: 20)
        return frame
    }

    ///Method which adds all the labels in this view.
    private func addAllLabels() {
        leftIndicatorLable = UILabel()
        rightIndicatorLable = UILabel()
        centerCurrentValueLabel = UILabel()

        leftIndicatorLable.text = startValueLimit.string0
        rightIndicatorLable.text = endValueLimit.string0
        centerCurrentValueLabel.text = currentValue.string0

        rightIndicatorLable.sizeToFit()
        leftIndicatorLable.sizeToFit()
        centerCurrentValueLabel.sizeToFit()

        rightIndicatorLable.textAlignment = .center
        leftIndicatorLable.textAlignment = .center
        centerCurrentValueLabel.textAlignment = .center

        rightIndicatorLable.font = fontForValueIndicators
        leftIndicatorLable.font = fontForValueIndicators
        centerCurrentValueLabel.font = fontForCenterValueLabel

        rightIndicatorLable.textColor = textColorForLabels
        leftIndicatorLable.textColor = textColorForLabels
        centerCurrentValueLabel.textColor = textColorForLabels

        addSubview(leftIndicatorLable)
        addSubview(rightIndicatorLable)
        addSubview(centerCurrentValueLabel)
    }

    ///Gives the point on the circumference to take the position of the left and right labels to be placed.
    /// parameter center: It is the center of the circle which is drawn.
    /// parameter radius: The radius of the circle.
    /// paramter angle: At which angle the circumference position is required.

    private func getPointOnCircumference(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)

        return CGPoint(x: x, y: y)
    }

    ///The method which adds the layer of the current value to the view.
    /// parameter animation: Tells that the progress layer to be added with animation or not.
    func addProgressLayer(withAnimation animation: Bool) {
        progressLayer?.removeFromSuperlayer()

        progressLayer = CAShapeLayer()
        progressLayer.frame = bounds
        let radius = bounds.width > bounds.height ? bounds.height: bounds.width

        progressPath = UIBezierPath(arcCenter: progressLayer.position, radius: (radius - 20) / 2, startAngle: startAngle.rad, endAngle: endAngle.rad, clockwise: true)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 13
        progressLayer.fillRule = kCAFillRuleEvenOdd
        progressLayer.strokeColor = UIColor.green.cgColor
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = endStrokeValue()
        progressLayer.lineCap = kCALineCapRound

        layer.addSublayer(progressLayer)


        if animation {
            let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            basicAnimation.fromValue = 0
            basicAnimation.toValue = endStrokeValue()
            basicAnimation.duration = 1
            progressLayer.add(basicAnimation, forKey: "downloadAnimation")
        }
    }

    ///Gives the end stroke value based on the current value.
    private func endStrokeValue() -> CGFloat {
        let differenceBetweenLimits = abs(startValueLimit - endValueLimit)

        let percentageOfCurrentLimit = abs(currentValue - startValueLimit) / differenceBetweenLimits

        return percentageOfCurrentLimit
    }
}

private extension CGFloat{
    var rad: CGFloat{
        return (self * CGFloat(M_PI)) / 180.0
    }

    var ang: CGFloat {
        return (self * 180) / CGFloat(M_PI)
    }
}

private extension Int {
    var f: CGFloat  {
        return CGFloat(self)
    }
}

private extension Double {
    var f: CGFloat  {
        return CGFloat(self)
    }
}

private extension CGFloat {
    var string1: String {
        return String(format: "%.1f", self)
    }
    var string2: String {
        return String(format: "%.2f", self)
    }
    var string0: String {
        return String(format: "%.0f", self)
    }
}
