//
//  WorkoutSessionsViewController.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import CoreData

class WorkoutSessionsViewController: UITableViewController, SessionCellDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let fileManager = FileManager()
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    var availableSessions : [Session]?
    
    var exportedSessionId : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "WorkoutSessionCell", bundle: nil), forCellReuseIdentifier: "sessionCell")
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(reloadTableWithNewData), name: Notification.Name("NewDataAvailable"), object: nil)
        
        documentDir = paths.firstObject as! String + "/MotionData"
        
        fetchAvailableSessions()
        self.refreshControl?.addTarget(self, action: #selector(fetchAvailableSessions), for: .valueChanged)

        // Do any additional setup after loading the view.
    }
    
    @objc func fetchAvailableSessions(){
        
        let request = NSFetchRequest<Session>(entityName: "Session")
        do {
            let result = try context.fetch(request)
            availableSessions = result
            for session in availableSessions! {
                print("Fetched session with id: \(session.sessionId!)")
            }
        } catch {
            print("Error fetching sessions: \(error)")
        }
        if self.refreshControl!.isRefreshing {
            self.tableView.reloadData()
            self.refreshControl!.endRefreshing()
        }
    }
    
    @objc func reloadTableWithNewData(){
        DispatchQueue.main.async {
            self.fetchAvailableSessions()
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! WorkoutSessionCell
        cell.delegate = self
        cell.currentCellIndex = indexPath
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableSessions!.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        exportedSessionId = availableSessions![indexPath.row].sessionId
        performSegue(withIdentifier: "goToEnds", sender: self)
        exportedSessionId = nil
        
    }
    
    func deleteSelectedCell(atIndex index: IndexPath) {
        
        deleteSession(fromSessionObject: availableSessions![index.row])
        
    }
    
    func deleteSession(fromSessionObject session: Session) {
        
        context.delete(session)
        let endsRequest = NSFetchRequest<MotionDataFile>(entityName: "MotionDataFile")
        endsRequest.predicate = NSPredicate(format: "sessionId = %@", argumentArray: [session.sessionId!])
        do {
            let result = try context.fetch(endsRequest)
            for file in result {
                context.delete(file)
                try fileManager.removeItem(at: URL(fileURLWithPath: documentDir + "/" + file.fileName!))
                try context.save()
            }
        } catch {
            print("Error deleting files from session with id: \(session.sessionId!)")
        }
        reloadTableWithNewData()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEnds" {
            let vc = segue.destination as! filesViewController
            vc.importedSessionId = exportedSessionId
        }
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
