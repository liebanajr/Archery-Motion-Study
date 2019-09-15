//
//  ViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

class filesViewController: UITableViewController{
    
    let fileManager = FileManager()
    
    var filesArray : [String] = []
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        documentDir = paths.firstObject as! String + "/MotionData"
        print("Motion data directory: \(documentDir)")
        
        updateTableWithDirectoryData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileItemCell", for: indexPath)
        cell.textLabel?.text = filesArray[indexPath.row]
        
        return cell
    }
    
    
//    Methods for deleting items
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Eliminar todo", message: "¿Seguro que deseas eliminar todos los datos guardados?\nPuede que alguno de los archivos no haya sido sincronizado", preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Eliminar", style: .destructive) { (action) in
            self.deleteItems(itemPath: nil)
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    
    }
    func deleteItems(itemPath: IndexPath?) {
        
        let dir = self.documentDir
        
        if itemPath == nil{
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
            return
        }
        
        let fileName = filesArray[itemPath!.row]
        do {
            try fileManager.removeItem(atPath: dir + "/" + fileName)
            print("Removed item: \(fileName)")
            updateTableWithDirectoryData()
        } catch {
            print("Error removing file \(fileName): \(error)")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItems(itemPath: indexPath)
            updateTableWithDirectoryData()
        }
    }
    
//    Updates the UI with new data
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
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: documentDir)
            print("Contenidos = \(contents)")
        } catch {
            print("Error obtaining contents: \(error)")
        }
        
        updateTableWithDirectoryData()
        
    }
    
//    Sharing data
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let files = [URL(fileURLWithPath: documentDir + "/" + filesArray[indexPath.row])]
        
        let activityVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
        present(activityVC, animated: true) {
            tableView.deselectRow(at: indexPath, animated: true)
//            activityVC.dismiss(animated: true, completion: nil)
        }
    }
    


}

