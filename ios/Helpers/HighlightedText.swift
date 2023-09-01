//
//  HighlightedText.swift
//  react-native-place-picker
//
//  Created by b0iq on 01/09/2023.
//

import Foundation

func highlightedText(_ text: String, inRanges ranges: [NSValue]) -> NSAttributedString {
    let attributedText = NSMutableAttributedString(string: text)
    for value in ranges {
        attributedText.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.black.withAlphaComponent(0.25), range: value.rangeValue)
    }
    return attributedText
}
