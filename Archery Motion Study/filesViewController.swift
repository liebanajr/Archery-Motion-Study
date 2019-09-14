//
//  ViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

class filesViewController: UITableViewController {
    
    let fileManager = FileManager()
    
    var filesArray : [String] = ["Path 1:", "Path 2:","Path 3:"]
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        documentDir = paths.firstObject as! String + "/MotionData"
        print("Motion data directory: \(documentDir)")
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileItemCell", for: indexPath)
        cell.textLabel?.text = filesArray[indexPath.row]
        
        return cell
    }
    
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: documentDir)
            print("Contenidos = \(contents)")
        } catch {
            print("Error obtaining contents: \(error)")
        }
        
        updateTableWithDirectoryData()
        
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        let dir = documentDir
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: dir)
            for path in contents {
                try fileManager.removeItem(atPath: dir + "/" + path)
            }
            print("Removed all items at \(dir)")
            updateTableWithDirectoryData()
        } catch {
            print("Error removing files: \(error)")
        }
    
    }
    
    
    func updateTableWithDirectoryData (){
        
        do {

            let files = try fileManager.contentsOfDirectory(atPath: documentDir)
            filesArray.removeAll(keepingCapacity: false)

            for path in files {
                filesArray.append(path)
            }

        } catch {
            print("Error looking for files in directory: \(error)")
        }
        
        tableView.reloadData()
        
    }


}

