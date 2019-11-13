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

class ChartViewController: UIViewController {
        
    @IBOutlet weak var chtChart: LineChartView!
    
    @IBOutlet weak var accXSwitch: UISwitch!
    @IBOutlet weak var accYSwitch: UISwitch!
    @IBOutlet weak var accZSwitch: UISwitch!
    @IBOutlet weak var gyrXSwitch: UISwitch!
    @IBOutlet weak var gyrYSwitch: UISwitch!
    @IBOutlet weak var gyrZSwitch: UISwitch!
    
    var switchesArray : [UISwitch]?
    var colorArray = [NSUIColor]()
    
    var importedFileName = ""
    var timeStamp : SensorDataSet?
    var availableDataSets : [SensorDataSet]?
    
    var desiredDataSets : [SensorDataSet]?
    
    var averageManager : SampleAverageManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        accXSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        accYSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        accZSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrXSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrYSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        gyrZSwitch.addTarget(self, action: #selector(checkSelectedSwitch), for: .valueChanged)
        
        switchesArray = [accXSwitch,accYSwitch,accZSwitch, gyrXSwitch,gyrYSwitch,gyrZSwitch]
        colorArray = [.orange, .blue, .brown, .cyan, .green, .purple]
        
        availableDataSets = extractDataSets(tableArray: readDataFromCSV(fileName: importedFileName))
        timeStamp = availableDataSets?.remove(at: 0)
        
        desiredDataSets = []
        
        averageManager = SampleAverageManager(nSamples: K.graphSmootherSamples, filterLevel: K.graphSmootherFilterLevel)
        
        chtChart.dragXEnabled = true
        chtChart.dragYEnabled = true
        chtChart.setScaleEnabled(true)
        chtChart.pinchZoomEnabled = true
        chtChart.drawMarkers = false
        chtChart.dragDecelerationEnabled = false
        chtChart.noDataTextColor = .label
        chtChart.noDataText = ""
    }
    
    func readDataFromCSV(fileName: String) -> [[String]]{
        let filePath = importedFileName
        
        do{
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            var result: [[String]] = []
            let rows = contents.components(separatedBy: "\n")
            for row in rows {
                let columns = row.components(separatedBy: ";")
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
        
        if !desiredDataSets!.isEmpty {
            let data = LineChartData()
            
            
            for dataSet in desiredDataSets!{
                
                var lineChartEntry = [ChartDataEntry]()
                
//                Average sensor data
                let smoothData = averageManager?.averageSignal(inputSignal: dataSet.data)
                       
                for (index,value) in smoothData!.enumerated() {
                    
                    let entry = ChartDataEntry(x: timeStamp!.data[index], y: value)
                    lineChartEntry.append(entry)
                }
                
                let line1 = LineChartDataSet(entries: lineChartEntry, label: dataSet.label)

                switch dataSet.label {
                case "Accelerometer X":
                    line1.colors = [colorArray[0]]
                case "Accelerometer Y":
                    line1.colors = [colorArray[1]]
                case "Accelerometer Z":
                    line1.colors = [colorArray[2]]
                case "Gyroscope X":
                    line1.colors = [colorArray[3]]
                case "Gyroscope Y":
                    line1.colors = [colorArray[4]]
                case "Gyroscope Z":
                    line1.colors = [colorArray[5]]
                default:
                    line1.colors = [.darkGray]
                }
                
                line1.drawCirclesEnabled = false
                
                data.addDataSet(line1)
                
            }
            
            chtChart.data = data
            chtChart.legend.enabled = false
            chtChart.xAxis.labelTextColor = .label
            chtChart.leftAxis.labelTextColor = .label
            chtChart.rightAxis.labelTextColor = .label
//            chtChart.zoom(scaleX: 3, scaleY: 3, xValue: 0, yValue: 0, axis: .left)
            chtChart.animate(xAxisDuration: 1.3)
            
        } else {
            chtChart.data = nil
        }
        
    }
    
    @objc func checkSelectedSwitch(){
        
        desiredDataSets?.removeAll(keepingCapacity: true)
        
        for (index,element) in switchesArray!.enumerated() {
            if element.isOn {
                desiredDataSets?.append(availableDataSets![index])
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

}
