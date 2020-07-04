//
//  ChartViewController.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 17/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import Charts
import Accelerate
import SwiftSpinner

class ChartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
        
    @IBOutlet weak var chtChart: LineChartView!
    @IBOutlet var chartSuperview: UIView!
    
    @IBOutlet weak var accXSwitch: UISwitch!
    @IBOutlet weak var accYSwitch: UISwitch!
    @IBOutlet weak var accZSwitch: UISwitch!
    @IBOutlet weak var gyrXSwitch: UISwitch!
    @IBOutlet weak var gyrYSwitch: UISwitch!
    @IBOutlet weak var gyrZSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timeArrow: UIStackView!
    
    var selectionCells : [String] = {
        if K.isAdmin {
            return ["X axis acceleration [G]", "Y axis acceleration [G]", "Z axis acceleration [G]", "X axis rotation [rad/s]", "Y axis rotation [rad/s]", "Z axis rotation [rad/s]", "Transformed X acceleration", "Transformed Y acceleration", "Transformed Z acceleration"]
        } else {
            return ["X axis acceleration [G]", "Y axis acceleration [G]", "Z axis acceleration [G]", "X axis rotation [rad/s]", "Y axis rotation [rad/s]", "Z axis rotation [rad/s]"]
        }
    }()
    
    var switchesArray : [UISwitch]?
    var colorArray = [NSUIColor]()
    
    var importedFileName = ""
    var timeStamp : SensorDataSet?
    var availableDataSets : [SensorDataSet]?
    
    var pendingIndexPath : IndexPath?
    
    @IBOutlet var fullScreenButton: UIButton!
    
    var chartIsFullScreen = false
    
    var desiredDataSets : [SensorDataSet] = []
    
    var averageManager = SampleAverageManager(nSamples: K.graphSmootherSamples, filterLevel: K.graphSmootherFilterLevel)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        accXSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        accYSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        accZSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrXSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrYSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrZSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        
        switchesArray = [accXSwitch,accYSwitch,accZSwitch, gyrXSwitch,gyrYSwitch,gyrZSwitch]
        colorArray = [.orange, .blue, .brown, .cyan, .green, .purple, .label, .label, .label]
        
        loadAvailableDataSets()
        
        desiredDataSets = []
        
        self.chtChart.legend.enabled = false
        self.chtChart.xAxis.labelTextColor = .label
        self.chtChart.leftAxis.labelTextColor = .label
        self.chtChart.rightAxis.enabled = false
        
        chtChart.xAxis.labelTextColor = .label
        chtChart.xAxis.labelPosition = .bottom
        chtChart.dragXEnabled = true
        chtChart.dragYEnabled = true
        chtChart.setScaleEnabled(true)
        chtChart.pinchZoomEnabled = true
        chtChart.drawMarkers = false
        chtChart.dragDecelerationEnabled = false
        chtChart.noDataTextColor = .label
        chtChart.noDataText = ""
        chtChart.backgroundColor = .systemGroupedBackground
        
        fullScreenButton.layer.cornerRadius = fullScreenButton.frame.size.width / 5
    }
    
    func loadAvailableDataSets(){
        Log.info("Loading available data sets")
        availableDataSets = [SensorDataSet]()
        for _ in selectionCells {
            availableDataSets?.append(SensorDataSet(labelName: "dummy"))
        }
        DispatchQueue.global(qos: .utility).async {
            var dataSets = self.extractDataSets(tableArray: self.readDataFromCSV(fileName: self.importedFileName))
            self.timeStamp = dataSets.remove(at: 0)
            
            var positionIndexes = [Int]()
            for (index,_) in self.selectionCells.enumerated() {
                positionIndexes.append(index)
            }
            var extractIndex = 0
            var isNeedsUpdateGraph = false
            while positionIndexes.count > 0 {
                let dataSet = dataSets.remove(at: extractIndex)
                let index = positionIndexes.remove(at: extractIndex)
                
                let smoothData = self.averageManager.averageSignal(inputSignal: dataSet.data)
                let newDataSet = SensorDataSet(labelName: dataSet.label)
                newDataSet.data = smoothData
                self.availableDataSets?[index] = newDataSet
                
                var count = 0
                for element in self.availableDataSets! {
                    if element.label != "dummy" {
                        count += 1
                    }
                }
                Log.info("availableDataSets now has \(count) elements")
                
                extractIndex = 0
                
                if let pendingDataSetToRender = self.pendingIndexPath{
                    if isNeedsUpdateGraph {
                        DispatchQueue.main.async {
                            self.selectRow(at: pendingDataSetToRender)
                            SwiftSpinner.hide()
                        }
                        self.pendingIndexPath = nil
                        isNeedsUpdateGraph = false
                        continue
                    }
                    
                    let diff = self.selectionCells.count - positionIndexes.count
                    extractIndex = pendingDataSetToRender.row - diff
                    isNeedsUpdateGraph = true
                    
                }
            }
            
//            for (index,dataSet) in dataSets.enumerated() {
//                let smoothData = self.averageManager.averageSignal(inputSignal: dataSet.data)
//                let newDataSet = SensorDataSet(labelName: dataSet.label)
//                newDataSet.data = smoothData
//                self.availableDataSets?[index] = newDataSet
//                Log.info("availableDataSets now has \(self.availableDataSets!.count) elements")
//
//                if let pendingDataSetToRender = self.pendingIndexPath, pendingDataSetToRender.row == self.availableDataSets!.count-1 {
//                    DispatchQueue.main.async {
////                        self.tableView.selectRow(at: pendingDataSetToRender, animated: true, scrollPosition: .none)
//                        self.selectRow(at: pendingDataSetToRender)
//                        SwiftSpinner.hide()
//                        self.pendingIndexPath = nil
////                        self.updateGraph()
//                    }
//                }
//
//                if self.availableDataSets?.count == self.selectionCells.count {
//                    break
//                }
//            }
            DispatchQueue.main.async {
                SwiftSpinner.hide()
//                self.updateGraph()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectionCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "selectionCell") as? ChartSelectionCell {
            cell.selectionTitleLabel?.text = NSLocalizedString(selectionCells[indexPath.row], comment: "")
            cell.colorArray = self.colorArray
            if let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.contains(indexPath) {
                cell.style(at: indexPath, for: true)
            } else {
                cell.style(at: indexPath, for: false)
            }
            return cell
        }
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        deselectRow(at: indexPath)
    }
    
    private func selectRow(at indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ChartSelectionCell
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        cell?.style(at: indexPath, for: true)
        checkSelectedDataSet()
    }
    
    private func deselectRow(at indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ChartSelectionCell
        tableView.deselectRow(at: indexPath, animated: true)
        cell?.style(at: indexPath, for: false)
        checkSelectedDataSet()
    }
    
    func checkSelectedDataSet(){
        desiredDataSets.removeAll()
        if let indexPaths = tableView.indexPathsForSelectedRows {
            for indexPath in indexPaths {
//                if let available = availableDataSets, indexPath.row < available.count  {
                if let available = availableDataSets, available[indexPath.row].label != "dummy"  {
                    desiredDataSets.append(available[indexPath.row])
                } else {
                    SwiftSpinner.show(delay: 0.1, title: NSLocalizedString("spinnerMessage", comment: ""))
                    pendingIndexPath = indexPath
//                    tableView.deselectRow(at: indexPath, animated: true)
                    deselectRow(at: indexPath)
//                    return
                }
            }
        }
        updateGraph()
    }
    
//    MARK: Enable rotation on view controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.enableAllOrientation = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.enableAllOrientation = false
            
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    func readDataFromCSV(fileName: String) -> [[String]]{
        let filePath = importedFileName
        
        do{
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            var result: [[String]] = []
            let rows = contents.components(separatedBy: "\n")
            for row in rows {
                let columns = row.components(separatedBy: ",")
                result.append(columns)
            }
            return result
        } catch {
            print("Error trying to read the file: \(error)")
            return [[]]
        }
        
    }
    
    func extractDataSets(tableArray: [[String]]) -> [SensorDataSet]{
        
        var dataSetTable = tableArray
        
        var dataSet = [SensorDataSet]()
        
        for element in dataSetTable[0] {
            dataSet.append(SensorDataSet(labelName: element))
        }
        
        dataSetTable.remove(at: 0)
        
        for rowValue in dataSetTable {
            for (columnIndex, columnValue) in rowValue.enumerated(){
                dataSet[columnIndex].appendDataPoint(value: columnValue)
            }
        }
        return dataSet
                
    }
    
    func updateGraph () {
        chtChart.clear()
        if !self.desiredDataSets.isEmpty {
//            SwiftSpinner.show(delay: 1.0, title: NSLocalizedString("spinnerMessage", comment: ""))
            DispatchQueue.global(qos: .utility).async {
                let data = LineChartData()


                for dataSet in self.desiredDataSets{
                    
                    Log.trace("Rendering \(dataSet.label)")
                    
                    var lineChartEntry = [ChartDataEntry]()

                    //                Average sensor data
                    let smoothData = dataSet.data
                           
                    for (index,value) in smoothData.enumerated() {
                        
                        let entry = ChartDataEntry(x: self.timeStamp!.data[index], y: value)
                        lineChartEntry.append(entry)
                    }

                    let line1 = LineChartDataSet(entries: lineChartEntry, label: dataSet.label)
                    
                    switch dataSet.label {
                        case "Accelerometer X":
                            line1.colors = [self.colorArray[0]]
                        case "Accelerometer Y":
                            line1.colors = [self.colorArray[1]]
                        case "Accelerometer Z":
                            line1.colors = [self.colorArray[2]]
                        case "Transformed accelerometer X":
                            line1.colors = [self.colorArray[0]]
                        case "Transformed accelerometer Y":
                            line1.colors = [self.colorArray[1]]
                        case "Transformed accelerometer Z":
                            line1.colors = [self.colorArray[2]]
                        case "Gyroscope X":
                            line1.colors = [self.colorArray[3]]
                        case "Gyroscope Y":
                            line1.colors = [self.colorArray[4]]
                        case "Gyroscope Z":
                            line1.colors = [self.colorArray[5]]
                        default:
                            line1.colors = [.darkGray]
                    }

                    line1.drawCirclesEnabled = false

                    data.addDataSet(line1)

                }
                DispatchQueue.main.async {
                    self.chtChart.data = data
                    self.fullScreenButton.isHidden = false
                    self.timeArrow.isHidden = false
                    //            chtChart.zoom(scaleX: 3, scaleY: 3, xValue: 0, yValue: 0, axis: .left)
                    //            chtChart.animate(xAxisDuration: 1.3)

                    SwiftSpinner.hide()
                }
            }
            } else {
                self.fullScreenButton.isHidden = true
                self.timeArrow.isHidden = true
//            self.chtChart.data = nil
//            self.fullScreenButton.isHidden = true
        }
        
    }
    
    @objc func checkSelectedSwitch(){
        
        desiredDataSets.removeAll(keepingCapacity: true)
        
        for (index,element) in switchesArray!.enumerated() {
            var adminIndex = index
            if K.isAdmin, adminIndex < 3 {
                adminIndex += 9
            }
            if element.isOn {
                desiredDataSets.append(availableDataSets![adminIndex])
            }
        }
        updateGraph()
        
    }

    @IBAction func shareButtonPressed(_ sender: Any) {
    
        let items = [URL(fileURLWithPath: importedFileName)]
        
        let action = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(action, animated: true)
    
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
        
    func toggleDeviceOrientation() {
        
        var value : Int = UIInterfaceOrientation.landscapeRight.rawValue
        if UIApplication.shared.windows.first?.windowScene?.interfaceOrientation == .landscapeLeft || UIApplication.shared.windows.first?.windowScene?.interfaceOrientation == .landscapeRight{
           value = UIInterfaceOrientation.portrait.rawValue
        }

        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
    }
    
    @IBAction func fullScreenButtonPressed(_ sender: Any) {
        
        print("Toggle full screen")
        toggleDeviceOrientation()
        
        if chartIsFullScreen {
            self.tabBarController?.tabBar.isHidden = false
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            chtChart.removeFromSuperview()
            chartSuperview.addSubview(chtChart)
            chtChart.pinEdges(to: chartSuperview)
            fullScreenButton.setBackgroundImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
            chartIsFullScreen = false
        } else {
            self.tabBarController?.tabBar.isHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            

            chtChart.removeFromSuperview()
            self.view.addSubview(chtChart)
            chtChart.pinEdges(to: self.view)
            fullScreenButton.setBackgroundImage(UIImage(systemName: "arrow.down.right.and.arrow.up.left"), for: .normal)
            chartIsFullScreen = true
        }
        
    }
    

}

extension UIView {
        
    func pinEdges(to other: UIView) {
        let margins = other.safeAreaLayoutGuide
        leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        
    }

}

class AxisInfoViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction func okButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true) {
            
        }
        
    }
    
}
