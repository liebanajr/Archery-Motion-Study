//
//  PrivateTableViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 19/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import Firebase
import CoreData

class PrivateTableViewController: UITableViewController {
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var itemsList : [StorageReference]?
    
    let fileManager = FileManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var downloadsDir :String = ""
    var documentsDir : String = ""
    
    var selectedFolder : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadsDir = paths.firstObject as! String + K.motionDataFolderDownloads
        documentsDir = paths.firstObject as! String + K.motionDataFolder
        
        if !fileManager.fileExists(atPath: downloadsDir) {
            fileManager.createFile(atPath: downloadsDir, contents: nil, attributes: nil)
        }
        
        deleteLocalFiles()
                
        itemsList = [StorageReference]()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemsList!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fireBaseItemCell", for: indexPath)

        cell.textLabel?.text = itemsList![indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        
        
    }
    
    func deleteLocalFiles() {
        
        do{
            try fileManager.removeItem(atPath: downloadsDir)
        } catch {
            print("Error removing files at \(downloadsDir): \(error)")
        }
        
    }
    
    func updateTableView(){
        
        let storageReference = Storage.storage().reference().child(selectedFolder!)
        storageReference.listAll(completion: { (result, error) in
            if error != nil {
                print("Error trying to list items: \(error!)")
            }
            self.itemsList = result.items
            self.tableView.isEditing = false
            self.deleteButton.isEnabled = false
            self.tableView.reloadData()
            self.title = self.selectedFolder
        })
        
    }

    @IBAction func shareButtonPressed(_ sender: Any) {
        
        var downloadedURLs = [URL]()
        var pendingDownloads = 0
        let spinnerView = createSpinnerView()
        
        if let itemsPaths = tableView.indexPathsForSelectedRows {
            for index in itemsPaths {
                let filePath = URL(fileURLWithPath: downloadsDir + itemsList![index.row].name)
                pendingDownloads += 1
                itemsList![index.row].write(toFile: filePath) { (url, error) in
                    pendingDownloads -= 1
                    if error != nil {
                        print("Error while getting download URL: \(error!)")
                    } else {
                        downloadedURLs.append(url!)
                        if pendingDownloads <= 0 {
                            self.removeSpinnerView(child: spinnerView)
                            let vc = UIActivityViewController(activityItems: downloadedURLs, applicationActivities: nil)
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        for item in itemsList! {
            let filePath = URL(fileURLWithPath: downloadsDir + item.name)
            pendingDownloads += 1
            item.write(toFile: filePath) { (url, error) in
                pendingDownloads -= 1
                if error != nil {
                    print("Error while getting download URL: \(error!)")
                } else {
                    downloadedURLs.append(url!)
                    if pendingDownloads <= 0 {
                        self.removeSpinnerView(child: spinnerView)
                        let vc = UIActivityViewController(activityItems: downloadedURLs, applicationActivities: nil)
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            }
        }
        
        
    }
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let itemsPaths = tableView.indexPathsForSelectedRows ?? []
        
        var items : [StorageReference]
        
        if itemsPaths.isEmpty {
            items = itemsList!
        } else {
            items = itemsPaths.map({ (path) -> StorageReference in
                return itemsList![path.row]
            })
        }
        
        var pendingDeletes = 0
        let spinnerView = createSpinnerView()
        
        for item in items {
            pendingDeletes += 1
            item.delete { error in
                pendingDeletes -= 1
                if error != nil {
                    print("Error while deleting file: \(error!)")
                } else {
                    if pendingDeletes <= 0 {
                        self.updateTableView()
                        self.removeSpinnerView(child: spinnerView)
                    }
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
    
    @IBAction func editButtonPressed(_ sender: Any) {
                
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            self.deleteButton.isEnabled = false
        } else {
            tableView.setEditing(true, animated: true)
            self.deleteButton.isEnabled = true
        }
        
        
    }
    
    @IBAction func selectAllButtonPressed(_ sender: Any) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            self.deleteButton.isEnabled = false
        } else {
            tableView.setEditing(true, animated: true)
            self.deleteButton.isEnabled = true
            if let list = itemsList {
                for (index,row) in list.enumerated() {
                    let indexPath = IndexPath(row: index, section: 0)
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    @IBAction func filterButtonPressed(_ sender: Any) {
                
        let list = UIAlertController(title: "Select folder", message: "", preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: K.firebaseFoldersBase[K.sessionValues[0]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersBase[K.sessionValues[0]]!
            self.updateTableView()
        }
        let action2 = UIAlertAction(title: K.firebaseFoldersBase[K.sessionValues[1]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersBase[K.sessionValues[1]]!
            self.updateTableView()
        }
        let action3 = UIAlertAction(title: K.firebaseFoldersBase[K.sessionValues[2]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersBase[K.sessionValues[2]]!
            self.updateTableView()
        }
        
        let action4 = UIAlertAction(title: K.firebaseFoldersAdmin[K.sessionValues[0]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersAdmin[K.sessionValues[0]]!
            self.updateTableView()
        }
        let action5 = UIAlertAction(title: K.firebaseFoldersAdmin[K.sessionValues[1]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersAdmin[K.sessionValues[1]]!
            self.updateTableView()
        }
        let action6 = UIAlertAction(title: K.firebaseFoldersAdmin[K.sessionValues[2]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersAdmin[K.sessionValues[2]]!
            self.updateTableView()
        }
        
        let action7 = UIAlertAction(title: K.firebaseFoldersFriends[K.sessionValues[0]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersFriends[K.sessionValues[0]]!
            self.updateTableView()
        }
        let action8 = UIAlertAction(title: K.firebaseFoldersFriends[K.sessionValues[1]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersFriends[K.sessionValues[1]]!
            self.updateTableView()
        }
        let action9 = UIAlertAction(title: K.firebaseFoldersFriends[K.sessionValues[2]]!, style: .default) { (action) in
            self.selectedFolder = K.firebaseFoldersFriends[K.sessionValues[2]]!
            self.updateTableView()
        }
        
        list.addAction(action1)
        list.addAction(action2)
        list.addAction(action3)
        list.addAction(action4)
        list.addAction(action5)
        list.addAction(action6)
        list.addAction(action7)
        list.addAction(action8)
        list.addAction(action9)
        
        present(list,animated: true)
        
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
