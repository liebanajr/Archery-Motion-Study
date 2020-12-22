//
//  TabBarViewController.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 10/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if K.isAdmin{
            let vc = self.storyboard!.instantiateViewController(identifier: "privatetableId")
            self.viewControllers?.append(vc)
            let vc2 = self.storyboard!.instantiateViewController(identifier: "remoteViewController")
            self.viewControllers?.append(vc2)
        }

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
