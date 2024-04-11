//
//  OrderConfirmationViewController.swift
//  OrderApp
//
//  Created by Berlin Thomas on 2024-04-10.
//

import UIKit

class OrderConfirmationViewController: UIViewController {
    
    let minutesToPrepare: Int
    
    @IBOutlet var orderConfirmationLabel: UILabel!
    
    init?(coder: NSCoder, minutesToPrepare: Int) {
        self.minutesToPrepare = minutesToPrepare
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        orderConfirmationLabel.text = "Thank you for your order! Your Wait time is approximately \(minutesToPrepare) minutes"
    }

}
