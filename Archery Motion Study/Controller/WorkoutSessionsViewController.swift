//
//  WorkoutSessionsViewController.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import CoreData

class WorkoutSessionsViewController: UITableViewController, FIlesDelegate {
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    
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
    
    func removeAllData(){
        
        fetchAvailableSessions()
        for session in availableSessions! {
            deleteSession(fromSessionObject: session)
            
        }
        
    }
    
    func addFillerData(){
        
        print("ADDING FILLER DATA!!")
        for _ in 0...5 {
            
            do {
                let randomSession = Session(context: context)
                randomSession.averageHeartRate = Int64.random(in: 40...120)
                randomSession.bowType = K.categoryValues[Int.random(in: 0...1)]
                randomSession.caloriesBurned = Int64.random(in: 90...500)
                let formatter = DateFormatter()
                formatter.dateFormat = K.dateFormat
                let randomDate = Date(timeIntervalSinceReferenceDate: TimeInterval(Int.random(in: 300000000...597369600)))
                randomSession.dateFinished = randomDate
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
                    randomEnd.firebaseLocation = K.firebaseFoldersBase[K.sessionValues[0]]
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
        documentDir = paths.firstObject as! String + K.motionDataFolder
        
        tableView.separatorStyle = .none
        
//        removeAllData()
//        addFillerData()
        
        fetchAvailableSessions()
        self.refreshControl?.isEnabled = false
//        self.refreshControl?.addTarget(self, action: #selector(fetchAvailableSessions), for: .valueChanged)

        // Do any additional setup after loading the view.
    }
    
    @objc func fetchAvailableSessions(){
        print("Fetching data from model")
//        availableSessions = []
        let request = NSFetchRequest<Session>(entityName: "Session")
        request.sortDescriptors = [NSSortDescriptor(key: "dateFinished", ascending: false)]
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
    }
    
    @objc func reloadTableWithNewData(){
        self.fetchAvailableSessions()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("Setting cell number: \(indexPath.row)")
        let session = availableSessions![indexPath.row]
        let formatter = DateFormatter()
        formatter.dateFormat = K.dateFormat
        let formattedDate = formatter.date(from: session.sessionId!)
        formatter.locale = .current
        formatter.dateFormat = NSLocalizedString("cellTitleDateFormat", comment: "")
        let dateString = formatter.string(from: formattedDate!)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! WorkoutSessionCell
        cell.selectionStyle = .none
//        cell.delegate = self
        cell.currentCellIndex = indexPath
        cell.titleLabel.text = dateString
        cell.avgHRLabel.text = "\(session.averageHeartRate) \(NSLocalizedString("average", comment: ""))"
        cell.calorieLabel.text = "\(session.caloriesBurned) KCal"
        cell.sessionTypeLabel.text = NSLocalizedString(session.sessionType!, comment: "") + " " + NSLocalizedString(session.bowType!, comment: "") + ","
        cell.watchLocationLabel.text = NSLocalizedString("Watch in", comment: "") + " " + NSLocalizedString(session.watchLocation!, comment: "")
        
        var arrowCountText = ""
        if session.arrowCount > 0 {
            arrowCountText = " \(session.arrowCount) \(NSLocalizedString("arrows", comment: ""))"
        }
        
        var maxHRText = "---"
        var minHRText = "---"
        if session.maxHeartRate > 0 && session.minHeartRate > 0{
            var endsString = NSLocalizedString("Ends", comment: "")
            endsString = String(endsString.dropLast())
            maxHRText = "\(session.maxHeartRate) max. \(endsString) \(session.maxHeartRateEnd)"
            minHRText = "\(session.minHeartRate) min. \(endsString) \(session.minHeartRateEnd)"
        }
        
        var durationText = "---"
        if session.duration > 0 {
            var minutes = Int(session.duration/60)
            let hours = Int(minutes/60)
            minutes = minutes - hours*minutes
            
            durationText = "\(hours)h \(minutes)m"
        }
        
        do{
            let request = NSFetchRequest<MotionDataFile>(entityName: "MotionDataFile")
            request.predicate = NSPredicate(format: "sessionId = %@", argumentArray: [session.sessionId!])
            let result = try context.fetch(request)
            let endsCount = result.count
            cell.endsLabel.text = "\(endsCount) \(NSLocalizedString("Ends", comment: "")) \(arrowCountText)"
            cell.maxHRLabel.text = maxHRText
            cell.minHRLabel.text = minHRText
            cell.durationLabel.text = durationText
        } catch {
            print("Error fetching ends count: \(error)")
        }
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of rows in section: \(availableSessions!.count)")
        if availableSessions!.count == 0 {
            tableView.setEmptyView(title: NSLocalizedString("noDataTitle", comment: ""), message: NSLocalizedString("noDataMessage", comment: ""))
        }
        else {
            tableView.restore()
        }
        
        return availableSessions!.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableView.isEditing {
            let session = availableSessions![indexPath.row]
            exportedSessionId = session.sessionId
            performSegue(withIdentifier: "goToEnds", sender: self)
            exportedSessionId = nil
        }
        deleteButton.isEnabled = true
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteSelectedCell(atIndex: indexPath)
        }
    }
    
    func deleteSelectedCell(atIndex index: IndexPath) {
        let rowToDelete = index.row
//        let alert = UIAlertController(title: NSLocalizedString("deleteSessionAlertTitle", comment: ""), message: NSLocalizedString("deleteSessionAlertMessage", comment: ""), preferredStyle: .actionSheet)
//        let action = UIAlertAction(title: NSLocalizedString("deleteSessionAction", comment: ""), style: .destructive) { (action) in
//            self.deleteSession(fromSessionObject: self.availableSessions![rowToDelete])
//        }
//        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
//            return
//        }
//        alert.addAction(action)
//        alert.addAction(cancelAction)
//        present(alert, animated: true)
        
        self.deleteSession(fromSessionObject: self.availableSessions![rowToDelete])
        reloadTableWithNewData()
        
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: NSLocalizedString("Delete data", comment: ""), message: NSLocalizedString("deleteDataMessage", comment: ""), preferredStyle: .actionSheet)
        let actionDelete = UIAlertAction(title: NSLocalizedString("Delete selected", comment: ""), style: .destructive) { (action) in
            if let items = self.tableView.indexPathsForSelectedRows {
                self.deleteSessions(with: items)
            }
        }
//        REMOVE FROM FINAL RELEASE
//        let actionDeleteAll = UIAlertAction(title: "Eliminar todo", style: .destructive) { (action) in
//            self.deleteItems(itemPath: nil)
//        }
//        alert.addAction(actionDeleteAll)
        alert.addAction(actionDelete)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
    }
    
    
    @IBAction func editButtonPressed(_ sender: Any) {
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            editButton.title = NSLocalizedString("Edit", comment: "")
            editButton.style = .plain
            deleteButton.isEnabled = false
        } else {
            tableView.setEditing(true, animated: true)
            editButton.title = NSLocalizedString("Done", comment: "")
            editButton.style = .done
//            deleteButton.isEnabled = true
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil {
            deleteButton.isEnabled = false
        }
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
        
    }
    
    func deleteSessions(with indexPaths: [IndexPath]){
        for index in indexPaths {
            let row = index.row
            deleteSession(fromSessionObject: self.availableSessions![row])
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
        print("Deleting empty session...")
        
        for session in availableSessions! {
            if session.sessionId == id {
                deleteSession(fromSessionObject: session)
            }
        }
        fetchAvailableSessions()
        tableView.reloadData()
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
