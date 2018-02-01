//
//  InfoController.swift
//  3DMED
//
//  Created by Paolo Speziali on 18/09/17.
//  Copyright © 2017 Paolo Speziali. All rights reserved.
//

import UIKit
import Kingfisher



class InfoController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var labDevice: UILabel!
    @IBOutlet var labPrice: UILabel!
    @IBOutlet var labAva: UILabel!
    @IBOutlet var fieldDesc: UITextView!
    
    var outputInfo = Device()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: outputInfo.image)
        imageView.kf.setImage(with: url)
        
        labDevice.text = outputInfo.model
        labPrice.text = "Price: \(outputInfo.price) €"
        labAva.text = outputInfo.available
        fieldDesc.text = outputInfo.description

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
