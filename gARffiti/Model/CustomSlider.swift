//
//  CustomSlider.swift
//  gARffiti
//
//  Created by Paulus Michael on 18/05/24.
//

import Foundation
import UIKit

class CustomSlider: UISlider{
    let coinEnd = UIImage(/*HERE_LEFT_BLANK_IMG*/).resizableImage(withCapInsets:
                                                                    UIEdgeInsets(top: 0,left: 7,bottom: 0,right: 7), resizingMode: .stretch)

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.origin.x = 0
        result.size.width = bounds.size.width
        result.size.height = 10 //added height for desired effect
        return result
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        return super.thumbRect(forBounds:
            bounds, trackRect: rect, value: value)
            .offsetBy(dx: 0/*Set_0_value_to_center_thumb*/, dy: 0)
    }
}
