//
//  RemoveBars.swift
//  BNIVideoBooth
//
//  Created by Altaf Razzaque on 11/01/2023.
//

import Foundation
import UIKit

class NoBarsController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
