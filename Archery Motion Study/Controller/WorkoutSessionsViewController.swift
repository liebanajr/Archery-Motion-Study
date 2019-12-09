//
//  WorkoutSessionsViewController.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import CoreData

class WorkoutSessionsViewController: UITableViewController, SessionCellDelegate, FIlesDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let fileManager = FileManager()
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    var availableSessions : [Session]?
    
    var exportedSessionId : String?
    
    let defaults = UserDefaults.standard
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func addFillerData(){
        
        for _ in 0...5 {
            
            do {
                let randomSession = Session(context: context)
                randomSession.averageHeartRate = Int64.random(in: 40...120)
                randomSession.bowType = K.categoryValues[Int.random(in: 0...1)]
                randomSession.caloriesBurned = Int64.random(in: 90...500)
                let formatter = DateFormatter()
                formatter.dateFormat = K.dateFormat
                let randomDate = Date(timeIntervalSinceReferenceDate: TimeInterval(Int.random(in: 300000000...597369600)))
                randomSession.sessionId = formatter.string(from: randomDate)
                randomSession.sessionType = K.sessionValues[0]
                randomSession.watchLocation = K.handValues[Int.random(in: 0...1)]
                try context.save()
                
                for number in 0...5 {
                    
                    let randomEnd = MotionDataFile(context: context)
                    randomEnd.sessionId = randomSession.sessionId
                    randomEnd.endIndex = Int64(number + 1)
                    randomEnd.fileName = "Mock file name"
                    randomEnd.isUploaded = true
                    randomEnd.firebaseLocation = K.firebaseFolders[K.sessionValues[0]]
                    try context.save()
                    
                }
                
            } catch {
                print("Error trying to create mock data: \(error)")
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if defaults.value(forKey: K.freshKey) == nil {
            self.tabBarController?.selectedIndex = 1
            defaults.set(true, forKey: K.freshKey)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Registering cell")
        tableView.register(UINib(nibName: "WorkoutSessionCell", bundle: nil), forCellReuseIdentifier: "sessionCell")
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(reloadTableWithNewData), name: Notification.Name("NewDataAvailable"), object: nil)
        print("Done registering cell")
        documentDir = paths.firstObject as! String + K.motionDataFolder
        
        tableView.separatorStyle = .none
        
//        addFillerData()
        
        fetchAvailableSessions()
        self.refreshControl?.addTarget(self, action: #selector(fetchAvailableSessions), for: .valueChanged)

        // Do any additional setup after loading the view.
    }
    
    @objc func fetchAvailableSessions(){
        print("Fetching data from model")
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
        print("Done fetching data from model")
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
        
        let session = availableSessions![indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = K.dateFormat
        let formattedDate = formatter.date(from: session.sessionId!)
        formatter.locale = .current
        formatter.dateFormat = NSLocalizedString("cellTitleDateFormat", comment: "")
        let dateString = formatter.string(from: formattedDate!)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! WorkoutSessionCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.currentCellIndex = indexPath
        cell.titleLabel.text = dateString
        cell.avgHRLabel.text = "\(session.averageHeartRate) bpm \(NSLocalizedString("average", comment: ""))"
        cell.calorieLabel.text = "\(session.caloriesBurned) KCal"
        cell.sessionTypeLabel.text = NSLocalizedString(session.sessionType!, comment: "") + " " + NSLocalizedString(session.bowType!, comment: "") + ","
        cell.watchLocationLabel.text = NSLocalizedString("Watch in", comment: "") + " " + NSLocalizedString(session.watchLocation!, comment: "")
        do{
            let request = NSFetchRequest<MotionDataFile>(entityName: "MotionDataFile")
            request.predicate = NSPredicate(format: "sessionId = %@", argumentArray: [session.sessionId!])
            let result = try context.fetch(request)
            let endsCount = result.count
            
            cell.endsLabel.text = "\(endsCount) \(NSLocalizedString("Ends", comment: ""))"
        } catch {
            print("Error fetching ends count: \(error)")
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if availableSessions!.count == 0 {
            tableView.setEmptyView(title: NSLocalizedString("noDataTitle", comment: ""), message: NSLocalizedString("noDataMessage", comment: ""))
        }
        else {
            tableView.restore()
        }
        
        return availableSessions!.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let session = availableSessions![indexPath.row]
        exportedSessionId = session.sessionId
        performSegue(withIdentifier: "goToEnds", sender: self)
        exportedSessionId = nil
        
    }
    
    func deleteSelectedCell(atIndex index: IndexPath) {
        let rowToDelete = index.row
        let alert = UIAlertController(title: NSLocalizedString("deleteSessionAlertTitle", comment: ""), message: NSLocalizedString("deleteSessionAlertMessage", comment: ""), preferredStyle: .actionSheet)
        let action = UIAlertAction(title: NSLocalizedString("deleteSessionAction", comment: ""), style: .destructive) { (action) in
            self.deleteSession(fromSessionObject: self.availableSessions![rowToDelete])
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            return
        }
        alert.addAction(action)
        alert.addAction(cancelAction)
        present(alert, animated: true)
        
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
            }
            try context.save()
        } catch {
            print("Error deleting files from session with id: \(session.sessionId!)")
        }
        reloadTableWithNewData()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEnds" {
            let vc = segue.destination as! filesViewController
            vc.importedSessionId = exportedSessionId
            vc.filesDelegate = self
        }
    }
    
    func didEmptySession(with id: String){
        print("Deleting empty session")
        
        for session in availableSessions! {
            if session.sessionId == id {
                deleteSession(fromSessionObject: session)
            }
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

extension UITableView {
    func setEmptyView(title: String, message: String) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.label
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        // The only tricky part is here:
        self.backgroundView = emptyView
    }
    func restore() {
        self.backgroundView = nil
    }
}
