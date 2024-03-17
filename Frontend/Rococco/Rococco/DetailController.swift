//
//  detailController.swift
//  Rococco
//
//  Created by Alok Sahay on 17.03.2024.
//

import UIKit

class DetailController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

}
