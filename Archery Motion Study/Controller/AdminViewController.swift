//
//  PrivateTableViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 19/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import FirebaseStorage
import CoreData
import iOSUtils

class AdminViewController: UITableViewController {
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    var itemsList : [StorageReference]?
    
    let fileManager = FileManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var downloadsDir :String = ""
    var documentsDir : String = ""
    
    var selectedFolder : String?
    
    var selectedFolderPrefix = K.firebaseFoldersPrefix

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadsDir = paths.firstObject as! String + K.motionDataFolderDownloads
        documentsDir = paths.firstObject as! String + K.motionDataFolder
                
        print("Downloads dir = \(downloadsDir)")
                
        if !fileManager.fileExists(atPath: downloadsDir) {
            try! fileManager.createDirectory(atPath: downloadsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        deleteLocalFiles()
                
        itemsList = [StorageReference]()
        
        filterButton.menu = UIMenu(title: "Select folder", image: nil, identifier: nil, options: [], children: self.filterButtonActions())
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
        
        do {
            let directoryContents : NSArray = try fileManager.contentsOfDirectory(atPath: downloadsDir) as NSArray
            print("Contents of downloads folder")
            print(directoryContents)
            
            for path in directoryContents {
                let filePath = downloadsDir + "/" + (path as! String)
                if filePath.contains(".csv") {
                    Log.debug("Deleting \(filePath)")
                    try fileManager.removeItem(atPath: filePath)
                }
            }
                        
        } catch {
            print("Error deleting files: \(error)")
        }
        
    }
    
    func updateTableView(){
        
        let storageReference = Storage.storage().reference().child(selectedFolder!)
        storageReference.listAll(completion: { (result, error) in
            if error != nil {
                print("Error trying to list items: \(error!)")
            }
            
            self.itemsList = result?.items
            self.tableView.isEditing = false
            self.deleteButton.isEnabled = false
            self.tableView.reloadData()
            
            if let items = self.itemsList, items.count > 0 {
                self.title = "\(items.count) items"
            } else {
                self.title = "No items"
            }
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
        } else {
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
                for (index,_) in list.enumerated() {
                    let indexPath = IndexPath(row: index, section: 0)
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    func filterButtonActions() -> [UIAction] {
            
        var actions = [UIAction]()
        
        for sessionValue in K.sessionValues {
            let baseAction = UIAction(title: "\(K.firebaseFoldersBase[sessionValue]!)".replacingOccurrences(of: "/", with: "")) { (action) in
                self.selectedFolder = "\(K.firebaseFoldersPrefix)\( K.firebaseFoldersBase[sessionValue]!)"
                self.updateTableView()
            }

            let friendsAction = UIAction(title: "\(K.firebaseFoldersFriends[sessionValue]!)".replacingOccurrences(of: "/", with: "")) { (action) in
                self.selectedFolder = "\(K.firebaseFoldersPrefix)\(K.firebaseFoldersFriends[sessionValue]!)"
                self.updateTableView()
            }
            
            actions.append(baseAction)
            actions.append(friendsAction)
        }
        
        let v3Action = UIAction(title: "Version 3") { (action) in
            self.selectedFolder = K.fireBaseFolder
            self.updateTableView()
        }
        
        actions.append(v3Action)
        return actions
        
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
