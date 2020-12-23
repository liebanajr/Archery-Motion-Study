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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timeArrow: UIStackView!
    @IBOutlet weak var separator: UIImageView!
    
    var selectionCells : [String] = {
        if K.isAdmin {
            return ["X axis acceleration [G]", "Y axis acceleration [G]", "Z axis acceleration [G]", "X axis rotation [rad/s]", "Y axis rotation [rad/s]", "Z axis rotation [rad/s]", "Transformed X acceleration", "Transformed Y acceleration", "Transformed Z acceleration","Transformed X axis rotation [rad/s]", "Transformed Y axis rotation [rad/s]", "Transformed Z axis rotation [rad/s]", "Gravity X", "Gravity Y", "Gravity Z"]
        } else {
            return ["X axis acceleration [G]", "Y axis acceleration [G]", "Z axis acceleration [G]", "X axis rotation [rad/s]", "Y axis rotation [rad/s]", "Z axis rotation [rad/s]"]
        }
    }()
    
    var selectionColumnsToPrint : [Int] = {
        if K.isAdmin {
            return [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        } else {
            return [0,7,8,9,10,11,12]
        }
    }()
    
    var switchesArray : [UISwitch]?
    var colorArray : [NSUIColor] = [.orange, .blue, .brown, .cyan, .green, .purple, .label, .systemBlue, .systemPink, .systemRed, .systemIndigo, .systemYellow, .systemTeal, .systemPurple, .systemOrange]
    
    var importedFileName = ""
    var timeStamp : SensorDataSet?
    var availableDataSets : [SensorDataSet]?
    var sharpDataSets : [SensorDataSet]?
    
    var pendingIndexPath : IndexPath?
    
    @IBOutlet var fullScreenButton: UIButton!
    
    var chartIsFullScreen = false
    
    var desiredDataSets : [SensorDataSet] = []
    
    var averageManager = SampleAverageManager(nSamples: K.graphSmootherSamples, filterLevel: K.graphSmootherFilterLevel)
    
    var backgroundWorkItem : DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
        separator.layer.cornerRadius = separator.frame.size.height / 2
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.backgroundWorkItem?.cancel()
        }
    }
    
    func loadAvailableDataSets(){
        backgroundWorkItem = DispatchWorkItem(block: {
            Log.info("Loading available data sets")
            self.availableDataSets = [SensorDataSet]()
            var dataSets = self.extractDataSets(tableArray: self.readDataFromCSV(fileName: self.importedFileName))
            self.timeStamp = dataSets.remove(at: 0)
            
            self.sharpDataSets = [SensorDataSet]()
            for (index,_) in self.selectionCells.enumerated() {
                self.availableDataSets?.append(SensorDataSet(labelName: "dummy"))
                self.sharpDataSets?.append(dataSets[index])
            }
            
            var positionIndexes = [Int]()
            for (index,_) in self.selectionCells.enumerated() {
                positionIndexes.append(index)
            }
            var extractIndex = 0
            var index = 0
            var isNeedsUpdateGraph = false
            while positionIndexes.count > 0 {
                if self.backgroundWorkItem!.isCancelled {
                    Log.info("Cancelling data processing background task")
                    break
                }
                if let pendingDataSetToRender = self.pendingIndexPath{
                    if isNeedsUpdateGraph {
                        DispatchQueue.main.async {
                            SwiftSpinner.hide()
                        }
                        self.pendingIndexPath = nil
                        isNeedsUpdateGraph = false
                        
                    } else {
                        if pendingDataSetToRender.row != index {
                            let diff = self.selectionCells.count - positionIndexes.count
                            extractIndex = pendingDataSetToRender.row - diff
                        }
                        isNeedsUpdateGraph = true
                    }
                    DispatchQueue.main.async {
                        self.checkSelectedDataSet()
                    }
                }
                
                let dataSet = dataSets.remove(at: extractIndex)
                index = positionIndexes.remove(at: extractIndex)
                
                var smoothData : [Double]
                Log.debug("Data points: \(dataSet.data.count); Samples window: \(K.graphSmootherSamples)")
                if K.graphSmootherSamples > 0 && dataSet.data.count / 30 > K.graphSmootherSamples {
                    smoothData = self.averageManager.averageSignal(inputSignal: dataSet.data)
                } else {
                    Log.warning("Not enough data for smoothing")
                    smoothData = dataSet.data
                }
                let newDataSet = SensorDataSet(labelName: dataSet.label)
                newDataSet.data = smoothData
                self.availableDataSets?[index] = newDataSet
                if self.pendingIndexPath?.row == index {
                    isNeedsUpdateGraph = true
                }
                
                var count = 0
                for element in self.availableDataSets! {
                    if element.label != "dummy" {
                        count += 1
                    }
                }
                Log.info("availableDataSets now has \(count) elements")
                extractIndex = 0
            }

            DispatchQueue.main.async {
                SwiftSpinner.hide()
            }
        })
        
        DispatchQueue.global(qos: .utility).async(execute: backgroundWorkItem!)
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
                if let available = availableDataSets, available[indexPath.row].label != "dummy"  {
                    desiredDataSets.append(available[indexPath.row])
                } else {
                    pendingIndexPath = indexPath
                    if let dataSet = sharpDataSets?[indexPath.row] {
                        Log.info("Smooth data not available. Appending sharp data")
                        desiredDataSets.append(dataSet)
                    }

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
            result.remove(at: result.count - 1)
            return result
        } catch {
            print("Error trying to read the file: \(error)")
            return [[]]
        }
        
    }
    
    func extractDataSets(tableArray: [[String]]) -> [SensorDataSet]{
        
        var dataSetTable = tableArray
//        print(dataSetTable)
        var dataSet = [SensorDataSet]()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let appVersionDouble = Double(appVersion) ?? 0.0
        
//        We check app version to prevent crashes for missing data
        if appVersionDouble < 2.1 {
            Log.info("App version \(appVersionDouble) is lower. Using old extract method")
            for element in dataSetTable[0] {
                dataSet.append(SensorDataSet(labelName: element))
            }
            
            dataSetTable.remove(at: 0)
            
            for rowValue in dataSetTable {
                for (columnIndex, columnValue) in rowValue.enumerated(){
                    dataSet[columnIndex].appendDataPoint(value: columnValue)
                }
            }
//            New version of the extraction method
        } else {
            Log.info("App version \(appVersionDouble) is good. Using new extract method")
            for value in selectionColumnsToPrint {
                let labelName = dataSetTable[0][value]
                print("Setting data \(value) for \(labelName)")
                var data = dataSetTable.map { $0[ value ] }
                data.remove(at: 0)
                let dataSetPoint = SensorDataSet(labelName: labelName)
                dataSetPoint.setData(values: data)
                dataSet.append(dataSetPoint)
            }
        }
        
        return dataSet
                
    }
    
    func updateGraph () {
        chtChart.clear()
        if !self.desiredDataSets.isEmpty {
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
                    
                    let titlesArray = self.availableDataSets!.map { (data) -> String in
                        return data.label
                    }
                    
                    let colorIndex = titlesArray.firstIndex(of: dataSet.label) ?? 0
                    line1.colors = [self.colorArray[colorIndex]]
                    line1.drawCirclesEnabled = false
                    line1.drawValuesEnabled = false
                    line1.lineWidth = 2.0
                    data.addDataSet(line1)

                }
                DispatchQueue.main.async {
                    self.chtChart.data = data
                    self.fullScreenButton.isHidden = false
                    self.timeArrow.isHidden = false
                    //            chtChart.zoom(scaleX: 3, scaleY: 3, xValue: 0, yValue: 0, axis: .left)
                    //            chtChart.animate(xAxisDuration: 1.3)

//                    SwiftSpinner.hide()
                }
            }
            } else {
                self.fullScreenButton.isHidden = true
                self.timeArrow.isHidden = true
//            self.chtChart.data = nil
//            self.fullScreenButton.isHidden = true
        }
        
    }
    
//    @objc func checkSelectedSwitch(){
//
//        desiredDataSets.removeAll(keepingCapacity: true)
//
//        for (index,element) in switchesArray!.enumerated() {
//            var adminIndex = index
//            if K.isAdmin, adminIndex < 3 {
//                adminIndex += 9
//            }
//            if element.isOn {
//                desiredDataSets.append(availableDataSets![adminIndex])
//            }
//        }
//        updateGraph()
//
//    }

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
