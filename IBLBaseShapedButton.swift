import UIKit

extension UIView {
    func alphaFromPoint(point: CGPoint) -> CGFloat {
        var pixel: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let alphaInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: alphaInfo.rawValue)
        
        context?.translateBy(x: -point.x, y: -point.y)
        
        layer.render(in: context!)
        
        let floatAlpha = CGFloat(pixel[3])
        return floatAlpha
    }
}

@IBDesignable
class SwiftShapedTapButton: UIButton {
    
    @IBInspectable var treshold: CGFloat = 1.0 {
        didSet {
            if treshold > 1.0 {
                treshold = 1.0
            }
            if treshold < 0.0 {
                treshold = 0.0
            }
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return alphaFromPoint(point: point) > treshold
    }
}
