//
//  MediaCell.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit

extension UIViewController {
    func commonAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}

