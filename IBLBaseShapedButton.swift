//
//  IBLBaseShapedButton.swift
//  IBLBaseProject
//
//  Created by Ivan_deng on 2018/4/25.
//  Copyright © 2018年 Ivan_deng. All rights reserved.
//

import UIKit

let kAlphaVisibleThreshold:CGFloat = 0.1

extension UIImage {
  func colorAtPixel(point:CGPoint) -> UIColor? {
    // Cancel if point is outside image coordinates
    let rect = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
    if (!rect.contains(point)) {
      print("Point: \(point.debugDescription) is not in Rect: \(rect.debugDescription)")
      return nil;
    }
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    let pointX:Int = Int(trunc(point.x))
    let pointY:Int = Int(trunc(point.y))
    
    let cgimage:CGImage = self.cgImage!
    let width:UInt = UInt(self.size.width)
    let height:UInt = UInt(self.size.height)
    
    let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB();
    let bytesPerPixel:Int = 4
    let bytesPerRow:Int = 1 * bytesPerPixel
    let bitsPerComponent:Int = 8
    let pixelData = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 0)

    let context:CGContext = CGContext.init(data: pixelData, width: 1, height: 1, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setBlendMode(CGBlendMode.copy)
    
    // Draw the pixel we are interested in onto the bitmap context
    context.translateBy(x:CGFloat(-pointX), y:CGFloat(pointY) - CGFloat(height))
    context.draw(cgimage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))

    let rgba = Array(UnsafeBufferPointer(start: pixelData.assumingMemoryBound(to: UInt8.self), count: 4))

    let red:CGFloat = CGFloat(rgba[0] / UInt8(255.0))
    let green:CGFloat = CGFloat(rgba[1] / UInt8(255.0))
    let blue:CGFloat = CGFloat(rgba[2] / UInt8(255.0))
    let alpha:CGFloat = CGFloat(rgba[3] / UInt8(255.0))
    return UIColor.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension UIImageView {
  
    var viewToImageTransform:CGAffineTransform? {
    get {
      let contentMode:UIViewContentMode = self.contentMode
      // failure conditions. If any of these are met – return the identity transform
      if (self.image == nil || self.frame.size.width == 0 || self.frame.size.height == 0 ||
        (contentMode != .scaleToFill && contentMode != .scaleAspectFill && contentMode != .scaleAspectFit)) {
        return CGAffineTransform.identity;
      }
      // the width and height ratios
      let rWidth:CGFloat = self.image!.size.width/self.frame.size.width;
      let rHeight:CGFloat = self.image!.size.height/self.frame.size.height;
      
      // whether the image will be scaled according to width
      let imageWiderThanView:Bool = rWidth > rHeight;
      if (contentMode == .scaleAspectFill || contentMode == .scaleAspectFit) {
        // The ratio to scale both the x and y axis by
        let ratio:CGFloat = ((imageWiderThanView && contentMode == .scaleAspectFit) || (!imageWiderThanView && contentMode == .scaleAspectFill)) ? rWidth:rHeight;
        
        // The x-offset of the inner rect as it gets centered
        let xOffset:CGFloat = (self.image!.size.width-(self.frame.size.width*ratio))*0.5;
        
        // The y-offset of the inner rect as it gets centered
        let yOffset:CGFloat = (self.image!.size.height-(self.frame.size.height*ratio))*0.5;
        
        return CGAffineTransform.init(scaleX: ratio, y: ratio).translatedBy(x: xOffset, y: yOffset)
      }
      else {
        return CGAffineTransform(scaleX: rWidth, y: rHeight);
      }
    }
  }
  
  var imageToViewTransform:CGAffineTransform? {
    get {
      return self.viewToImageTransform!.inverted();
    }
  }
  
}

class IBLBaseShapedButton: UIButton {
  
  var previousTouchPoint:CGPoint?
  var previousTouchHitTestResponse:Bool?
  var buttonImage:UIImage?
  var buttonBackground:UIImage?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setup(){
    self.updateImageCacheForCurrentState()
    self.resetHitTestCache()
  }

  // MARK: - Hit testing
  func isAlphaVisibleAt(point:CGPoint, image:UIImage) -> Bool {
    // Correction for image scaling including contentmode
    let pt:CGPoint = __CGPointApplyAffineTransform(point, (self.imageView?.imageToViewTransform)!)
    let newpoint = pt;
    let pixelColor = image.colorAtPixel(point: newpoint)
    if (pixelColor == nil) {
      print("get pixelColor failed")
      return false
    }
    var alpha:CGFloat = 0
    if(pixelColor?.responds(to: #selector(pixelColor?.getRed(_:green:blue:alpha:))))! {
      pixelColor?.getRed(nil, green: nil, blue: nil, alpha: &alpha)
    }
    else {
      let cgPixelColor:CGColor = (pixelColor?.cgColor)!
      alpha = cgPixelColor.alpha
    }
    return alpha >= kAlphaVisibleThreshold
  }
  
  // UIView uses this method in hitTest:withEvent: to determine which subview should receive a touch event.
  // If pointInside:withEvent: returns YES, then the subview’s hierarchy is traversed; otherwise, its branch
  // of the view hierarchy is ignored.
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    let superResult = super.point(inside: point, with: event)
    if (!superResult) {
      return superResult
    }
    // Don't check again if we just queried the same point
    // (because pointInside:withEvent: gets often called multiple times)
    if (point.equalTo(self.previousTouchPoint!)) {
      return self.previousTouchHitTestResponse!
    }
    else {
      self.previousTouchPoint = point
    }
    
    var response:Bool = false
    
    if (self.buttonImage == nil && self.buttonBackground == nil) {
      response = true
    }
    else if (self.buttonImage != nil && self.buttonBackground == nil) {
      response = self.isAlphaVisibleAt(point: point, image: self.buttonImage!)
    }
    else if (self.buttonImage == nil && self.buttonBackground != nil) {
      response = self.isAlphaVisibleAt(point: point, image: self.buttonBackground!)
    }
    else {
      if (self.isAlphaVisibleAt(point: point, image: self.buttonImage!)) {
        response = true
      }
      else {
        response = self.isAlphaVisibleAt(point: point, image: self.buttonBackground!)
      }
    }
    
    self.previousTouchHitTestResponse = response
    return response
  }
  
  // MARK: - Accessors
  
  // Reset the Hit Test Cache when a new image is assigned to the button
  override func setImage(_ image: UIImage?, for state: UIControlState) {
    super.setImage(image, for: state)
    self.updateImageCacheForCurrentState()
    self.resetHitTestCache()
  }
  
  override func setBackgroundImage(_ image: UIImage?, for state: UIControlState) {
    super.setBackgroundImage(image, for: state)
    self.updateImageCacheForCurrentState()
    self.resetHitTestCache()
  }
  
  override var isEnabled: Bool {
    didSet {
      self.updateImageCacheForCurrentState()
    }
  }
  
  override var isSelected: Bool {
    didSet {
      self.updateImageCacheForCurrentState()
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      self.updateImageCacheForCurrentState()
    }
  }
  
  // MARK: - Helper methods
  func updateImageCacheForCurrentState() {
    buttonBackground = self.currentBackgroundImage
    buttonImage = self.currentImage
  }
  
  func resetHitTestCache() {
    previousTouchPoint = CGPoint(x: CGFloat.leastNormalMagnitude, y: CGFloat.leastNormalMagnitude)
    self.previousTouchHitTestResponse = false
  }
}
