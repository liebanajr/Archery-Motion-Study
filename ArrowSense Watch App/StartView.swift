//
//  ContentView.swift
//  ArrowSense Watch App
//
//  Created by Juan Rodríguez on 16/7/23.
//  Copyright © 2023 liebanajr. All rights reserved.
//

import SwiftUI
import WatchKit
import Foundation
import HealthKit
import WatchConnectivity
import ShotsWorkoutManager
import watchOSUtils

struct StartView: View {
    
    @State private var isShowingSettingsView = false
    @State private var isShowingSessionView = false
    
    private let session = WCSession.default
    
    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    startButtonPressed()
                } label: {
                    Circle()
                        .foregroundColor(.yellow.opacity(0.6))
                        .overlay {
                            Image(systemName: "figure.archery")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.yellow)
                                .padding(40)
                        }
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    HStack {
                        Button {
                            isShowingSettingsView.toggle()
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .resizable()
                                .imageScale(.large)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .opacity(0.8)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingSettingsView) {
                SettingsView()
            }
        }
        .task {
            setInitialDefaults()
            deleteAllLocalData()
            authorizeHealthKit()
        }
        .fullScreenCover(isPresented: $isShowingSessionView) {
            ActiveSessionView(isShowingActiveSessionView: $isShowingSessionView)
        }
    }
    
    private func authorizeHealthKit() {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data already available")
            return
        }
        
        let types = Set([HKObjectType.workoutType(),
                         HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: .heartRate)!
                        ])
        let healthStore = HKHealthStore()
        
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            if !success {
                print(error!)
            } else {
                print("HealthKit successfully authorized!")
                UserDefaults.standard.setValue(true, forKey: K.healthkitKey)
                self.syncUserDefaults()
            }
        }
        
    }
    
    private func userDefaultsExists () -> Bool {
        
        if UserDefaults.standard.string(forKey: K.bowTypeKey) == nil || UserDefaults.standard.string(forKey: K.handKey) == nil {
            UserDefaults.standard.set("Recurve", forKey: K.bowTypeKey)
            UserDefaults.standard.set("Bow", forKey: K.handKey)
            UserDefaults.standard.set("Shot", forKey: K.sessionTypeKey)
            return false
        }
        return true
        
    }
    
    private func setInitialDefaults() {
        
        var needsSyncUserDefaults = false
        
        if UserDefaults.standard.value(forKey: K.bowTypeKey) == nil {
            UserDefaults.standard.setValue(K.categoryValues[0], forKey: K.bowTypeKey)
            needsSyncUserDefaults = true
        }
        
        if UserDefaults.standard.value(forKey: K.handKey) == nil {
            UserDefaults.standard.setValue(K.handValues[0], forKey: K.handKey)
            needsSyncUserDefaults = true
        }
        
        if UserDefaults.standard.value(forKey: K.sessionTypeKey) == nil {
            UserDefaults.standard.setValue(K.sessionValues[0], forKey: K.sessionTypeKey)
            needsSyncUserDefaults = true
        }
        
        if needsSyncUserDefaults {
            syncUserDefaults()
        }
        
    }
    
    private func syncUserDefaults(){
        let info = [K.bowTypeKey:UserDefaults.standard.value(forKey: K.bowTypeKey)!, K.handKey : UserDefaults.standard.value(forKey: K.handKey)!, K.sessionTypeKey:UserDefaults.standard.value(forKey: K.sessionTypeKey)!]
        session.transferUserInfo(info)
    }
    
    private func startButtonPressed() {
                
        if !userDefaultsExists() {
            return
        } else {
            isShowingSessionView.toggle()
        }
        
    }
    
    private func deleteButtonPressed() {
        self.deleteAllLocalData()
    }
    
    func deleteAllLocalData() {
        do {
            if let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let fileManager = FileManager()
                let directoryContents = try fileManager.contentsOfDirectory(atPath: documentsDirectory)
                print(directoryContents)
                for path in directoryContents {
                    let filePath = documentsDirectory + "/" + (path)
                    if filePath.contains(".csv") {
                        Log.info("Deleting \(filePath)")
                        try fileManager.removeItem(atPath: filePath)
                    }
                }
            }
        } catch {
            print("Error deleting files: \(error)")
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
