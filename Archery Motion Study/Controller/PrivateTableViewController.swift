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
    
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    
    var itemsList : [StorageReference]?
    
    let fileManager = FileManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var downloadsDir :String = ""
    var documentsDir : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadsDir = paths.firstObject as! String + "/MotionData/Downloads"
        documentsDir = paths.firstObject as! String + "/MotionData"
        
        do{
            try fileManager.removeItem(atPath: downloadsDir)
        } catch {
            
        }
        
        if !fileManager.fileExists(atPath: downloadsDir) {
            fileManager.createFile(atPath: downloadsDir, contents: nil, attributes: nil)
        }
                
        itemsList = [StorageReference]()
        
        updateTableView()
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
        shareButton.isEnabled = true
        deleteButton.isEnabled = true
        downloadButton.isEnabled = true
    }
    func updateTableView(){
        
        let storageReference = Storage.storage().reference().child("motion-study-v1")
        storageReference.listAll(completion: { (result, error) in
            if error != nil {
                print("Error trying to list items: \(error!)")
            }
            self.itemsList = result.items
            self.tableView.isEditing = false
            self.tableView.reloadData()
        })
        
    }

    @IBAction func shareButtonPressed(_ sender: Any) {
        
        let itemsPaths = tableView.indexPathsForSelectedRows
        var downloadedURLs = [URL]()
        var pendingDownloads = 0
        let spinnerView = createSpinnerView()
        for index in itemsPaths! {
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
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let itemsPaths = tableView.indexPathsForSelectedRows
        var pendingDeletes = 0
        let spinnerView = createSpinnerView()
        for index in itemsPaths! {
            pendingDeletes += 1
            itemsList![index.row].delete { error in
                pendingDeletes -= 1
                if error != nil {
                    print("Error while deleting file: \(error!)")
                } else {
                    if pendingDeletes <= 0 {
                        self.editButton.title = "Select"
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
        
        let button = sender as! UIBarButtonItem
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            shareButton.isEnabled = false
            deleteButton.isEnabled = false
            downloadButton.isEnabled = false
            button.title = "Select"
            button.style = .plain
        } else {
            tableView.setEditing(true, animated: true)
            button.title = "Done"
            button.style = .done
        }
        
        
    }
    
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        
        let itemsPaths = tableView.indexPathsForSelectedRows
        var pendingDownloads = 0
        let spinnerView = createSpinnerView()
        for index in itemsPaths! {
            let filePath = URL(fileURLWithPath: documentsDir + itemsList![index.row].name)
            pendingDownloads += 1
            itemsList![index.row].write(toFile: filePath) { (url, error) in
                pendingDownloads -= 1
                if error != nil {
                    print("Error while getting download URL: \(error!)")
                } else {
                    let item = MotionDataFile(context: self.context)
                    item.fileName = self.itemsList![index.row].name
                    item.isUploaded = true
                    do {
                        try self.context.save()
                    } catch {
                        print("Error saving context \(error)")
                    }
                    if pendingDownloads <= 0 {
                        self.removeSpinnerView(child: spinnerView)
                    }
                }
            }
        }
        
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
