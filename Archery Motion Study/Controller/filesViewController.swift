//
//  ViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class filesViewController: UITableViewController{
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var updateButton: UIBarButtonItem!
    
    let fileManager = FileManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var filesArray : [MotionDataFile] = []
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateTableWithDirectoryData), name: Notification.Name("NewDataAvailable"), object: nil)
        
        documentDir = paths.firstObject as! String + "/MotionData"
        print("Motion data directory: \(documentDir)")
        
        updateTableWithDirectoryData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileItemCell", for: indexPath)
        let item = filesArray[indexPath.row]
        cell.textLabel?.text = item.fileName
        cell.accessoryType = item.isUploaded ? .checkmark : .none
        cell.isUserInteractionEnabled = item.isUploaded ? false : true
        
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
                for object in filesArray {
                    context.delete(object)
                }
                try context.save()
                print("Removed all items at \(dir)")
                updateTableWithDirectoryData()
            } catch {
                print("Error removing files: \(error)")
            }
            return
        }
        
        let file = filesArray[itemPath!.row]
        let fileName = file.fileName!
        do {
            try fileManager.removeItem(atPath: dir + "/" + fileName)
            context.delete(file)
            try context.save()
            print("Removed item: \(fileName)")
            updateTableWithDirectoryData()
        } catch {
            print("Error removing file \(fileName): \(error)")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItems(itemPath: indexPath)
        }
    }
    
//    Updates the UI with new data
    @objc func updateTableWithDirectoryData (){
        
        do {

//            let files = try fileManager.contentsOfDirectory(atPath: documentDir)
            filesArray.removeAll(keepingCapacity: false)

//            for path in files {
//                filesArray.append(path)
//            }
            let request : NSFetchRequest<MotionDataFile> = MotionDataFile.fetchRequest()
            filesArray = try context.fetch(request)
            
            print("Updated table view with data:")
            for item in filesArray{
                print("\(item.fileName!) isUploaded: \(item.isUploaded)")
            }

        } catch {
            print("Error looking for files in database: \(error)")
        }
        DispatchQueue.main.async {
            self.tableView.isEditing = false
            self.editButton.title = "Edit"
            self.editButton.style = .plain
            self.uploadButton.isEnabled = false
            self.deleteButton.isEnabled = true
            self.updateButton.isEnabled = true
            self.tableView.reloadData()
        }
        
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: documentDir)
            print("Contenidos del directorio= \(contents)")
        } catch {
            print("Error obtaining contents: \(error)")
        }
        
        updateTableWithDirectoryData()
        
    }
//    Sharing data
    
    @IBAction func uploadButtonPressed(_ sender: Any) {
        
        let paths = tableView.indexPathsForSelectedRows!
        var currentUploads = 0
        
        tableView.isEditing = false
        editButton.title = "Edit"
        editButton.style = .plain
        uploadButton.isEnabled = false
        deleteButton.isEnabled = true
        updateButton.isEnabled = true
        
        let spinnerView = createSpinnerView()
        
        print("Files to upload: ")
        for index in paths {
            
            currentUploads += 1
            
            let motionDataFileItem = filesArray[index.row]
            let fileName = motionDataFileItem.fileName!
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let motionDataDestination = storageRef.child("motion-study-v1/" + fileName)
            let srcURL = URL(fileURLWithPath: documentDir + "/" + fileName)
            

            let uploadTask = motionDataDestination.putFile(from: srcURL, metadata: nil) { metadata, error in
                if error != nil {
                  // Uh-oh, an error occurred!
                    print("Error uploading file: \(error!)")
                    return
                }
            }

            uploadTask.observe(.success) { (snapshot) in
                
                print("Uploaded \(fileName) successfully!!")
                motionDataFileItem.setValue(true, forKey: "isUploaded")
                do {
                    try self.context.save()
                } catch {
                    print("Error while saving context: \(error)")
                }
                self.updateTableWithDirectoryData()
                uploadTask.removeAllObservers()
                
                currentUploads -= 1
                print("CurrentUploads: \(currentUploads)")
                if currentUploads <= 0 {
                    self.removeSpinnerView(child: spinnerView)
                }
            }
        }
        
    }
    
    func createSpinnerView() -> SpinnerViewController{
        let child = SpinnerViewController()

        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)

        // wait two seconds to simulate some work happening
        return child
    }
    
    func removeSpinnerView(child: SpinnerViewController) {
        DispatchQueue.main.async() {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil {
            uploadButton.isEnabled = false
            deleteButton.isEnabled = true
            updateButton.isEnabled = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        uploadButton.isEnabled = true
        deleteButton.isEnabled = false
        updateButton.isEnabled = false
        
//        let files = [URL(fileURLWithPath: documentDir + "/" + filesArray[indexPath.row].fileName!)]
//
//        let activityVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
//        present(activityVC, animated: true) {
//            tableView.deselectRow(at: indexPath, animated: true)
//
//        }
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            editButton.title = "Edit"
            editButton.style = .plain
            uploadButton.isEnabled = false
            deleteButton.isEnabled = true
            updateButton.isEnabled = true
        } else {
            tableView.setEditing(true, animated: true)
            editButton.title = "Done"
            editButton.style = .done
            deleteButton.isEnabled = false
            updateButton.isEnabled = false
        }
        
    }
    
    
    

}

