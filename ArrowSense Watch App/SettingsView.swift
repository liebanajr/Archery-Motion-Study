//
//  SettingsView.swift
//  ArrowSense Watch App
//
//  Created by Juan Rodríguez on 16/7/23.
//  Copyright © 2023 liebanajr. All rights reserved.
//

import SwiftUI
import WatchConnectivity

struct SettingsView: View {
    
    private let userDefaults = UserDefaults.standard
    private let session = WCSession.default
    
    @State private var isShowingBowTypeView = false
    @State private var isShowingWatchLocationView = false
    @State private var isShowingSessionTypeView = false
    
    @State private var settings: [Setting] = []
    
    var body: some View {
        NavigationStack {
            Form {
                if settings.indices.contains(0) {
                    Button("Bow type") {
                        isShowingBowTypeView.toggle()
                    }
                    .navigationDestination(isPresented: $isShowingBowTypeView) {
                        EditSettingsView(setting: $settings[0])
                    }
                }
                
                if settings.indices.contains(1) {
                    Button("Watch location") {
                        isShowingWatchLocationView.toggle()
                    }
                    .navigationDestination(isPresented: $isShowingWatchLocationView) {
                        EditSettingsView(setting: $settings[1])
                    }
                }
                
                if settings.indices.contains(2), let name = userDefaults.value(forKey: K.nameKey) as? String, name != "" || K.isAdmin {
                    Button("Session type") {
                        isShowingSessionTypeView.toggle()
                    }
                    .navigationDestination(isPresented: $isShowingSessionTypeView) {
                        EditSettingsView(setting: $settings[2])
                    }
                }
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            initializeSettings()
        }
    }
    
    private func initializeSettings() {
        setInitialDefaults()
        settings.append(Setting(title: "Bow type", value: userDefaults.string(forKey: K.bowTypeKey) ?? K.categoryValues[0], possibleValues: K.categoryValues))
        settings.append(Setting(title: "Watch location", value: userDefaults.string(forKey: K.handKey) ?? K.handValues[0], possibleValues: K.handValues))
        settings.append(Setting(title: "Session type", value: userDefaults.string(forKey: K.sessionTypeKey) ?? K.sessionValues[0], possibleValues: K.sessionValues))
    }
    
    private func setInitialDefaults() {
        
        var needsSyncUserDefaults = false
        
        if userDefaults.value(forKey: K.bowTypeKey) == nil {
            userDefaults.setValue(K.categoryValues[0], forKey: K.bowTypeKey)
            needsSyncUserDefaults = true
        }
        
        if userDefaults.value(forKey: K.handKey) == nil {
            userDefaults.setValue(K.handValues[0], forKey: K.handKey)
            needsSyncUserDefaults = true
        }
        
        if userDefaults.value(forKey: K.sessionTypeKey) == nil {
            userDefaults.setValue(K.sessionValues[0], forKey: K.sessionTypeKey)
            needsSyncUserDefaults = true
        }
        
        if needsSyncUserDefaults {
            syncUserDefaults()
        }
        
    }
    
    private func syncUserDefaults(){
        let info = [K.bowTypeKey:userDefaults.value(forKey: K.bowTypeKey)!, K.handKey : userDefaults.value(forKey: K.handKey)!, K.sessionTypeKey:userDefaults.value(forKey: K.sessionTypeKey)!]
        session.transferUserInfo(info)
    }
}

struct EditSettingsView: View {
    
    @Binding var setting: Setting
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(setting.possibleValues, id: \.self) { possibleValue in
                    Button {
                        setting.value = possibleValue
                    } label: {
                        HStack {
                            Text(NSLocalizedString(possibleValue, comment: ""))
                            Spacer()
                            if setting.value == possibleValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text(setting.title))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}

struct Setting {
    var title: LocalizedStringKey
    var value: String
    let possibleValues: [String]
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
