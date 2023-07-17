//
//  ActiveSessionView.swift
//  ArrowSense Watch App
//
//  Created by Juan Rodríguez on 16/7/23.
//  Copyright © 2023 liebanajr. All rights reserved.
//

import SwiftUI
import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import HealthKit
import ShotsWorkoutManager
import watchOSUtils
import Combine

struct ActiveSessionView: View {
    
    @StateObject var sessionController = ActiveSessionController()
    @State private var tabIndex: Int = 1
    
    @Binding var isShowingActiveSessionView: Bool
    
    var body: some View {
        TabView(selection: $tabIndex) {
            SessionControllerView(tabIndex: $tabIndex, isShowingActiveSessionView: $isShowingActiveSessionView)
                .environmentObject(sessionController)
                .tag(0)
            SessionView()
                .environmentObject(sessionController)
                .environmentObject(sessionController.workoutManager.sessionData)
                .tag(1)
            NowPlayingView()
                .tag(2)
        }
    }
}

struct SessionControllerView: View {
        
    @EnvironmentObject private var sessionController: ActiveSessionController
    
    @Binding var tabIndex: Int
    @Binding var isShowingActiveSessionView: Bool
    
    @State private var isShowingEndWorkoutView = false
    
    var body: some View {
        HStack {
            VStack {
                Button {
                    if sessionController.workoutManager.state == .workoutRunning {
                        sessionController.workoutManager.pauseWorkout()
                    } else if sessionController.workoutManager.state == .workoutPaused {
                        sessionController.workoutManager.resumeWorkout()
                        sessionController.workoutManager.sessionData.endCounter += 1
                    }
                    withAnimation {
                        tabIndex = 1
                    }
                } label: {
                    let imageName = sessionController.workoutManager.state == .workoutRunning ? "pause" : "plus"
                    Image(systemName: imageName)
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .foregroundColor(.blue)
                let text: LocalizedStringKey = sessionController.workoutManager.state == .workoutRunning ? "Pause end" : "New end"
                Text(text)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            VStack {
                Button {
                    endWorkout()
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .foregroundColor(.red)
                Text("Finish")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!sessionController.buttonsEnabled)
        .fullScreenCover(isPresented: $isShowingEndWorkoutView) {
            isShowingActiveSessionView = false
        } content: {
            EndWorkoutView()
                .environmentObject(sessionController)
                .environmentObject(sessionController.workoutManager.sessionData)
        }

    }
    
    private func endWorkout() {
        if sessionController.workoutManager.state == .workoutRunning {
            sessionController.workoutManager.pauseWorkout()
        }
        isShowingEndWorkoutView = true
    }
    
}

struct SessionView: View {
    
    @EnvironmentObject private var sessionController: ActiveSessionController
    @EnvironmentObject private var sessionData: ShotsSessionDetails
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 30, height: 30)
                Image(systemName: "figure.archery")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.green)
            }
            HStack {
                Text("\(Duration.seconds(sessionController.timerTimeElapsed), format: .time(pattern: .hourMinuteSecond))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.yellow)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            VStack {
                HStack {
                    HStack {
                        HStack {
                            Image(systemName: "flame.fill")
                                .aspectRatio(contentMode: .fit)
                            Spacer()
                        }
                        .frame(width: 15)
                        Text("\(sessionData.cumulativeCaloriesBurned) kCal")
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        HStack {
                            Image(systemName: "target")
                                .aspectRatio(contentMode: .fit)
                            Spacer()
                        }
                        .frame(width: 15)
                        Text("End \(sessionData.endCounter)")
                        Spacer()
                    }
                }
                HStack {
                    HStack {
                        Image(systemName: "heart.fill")
                            .aspectRatio(contentMode: .fit)
                        Spacer()
                    }
                    .frame(width: 15)
                    Text("\(sessionData.currentHeartRate) bpm")
                    Spacer()
                }
            }
            .font(.footnote)
            .minimumScaleFactor(0.8)
            Spacer()
            VStack {
                HStack {
                    Button {
                        sessionController.workoutManager.removeArrow()
                    } label: {
                        Image(systemName: "minus.square.fill")
                            .resizable()
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 35, height: 35)
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    VStack {
                        Text("\(sessionData.arrowCounter)")
                    }
                    .font(.system(.title2, design: .rounded))
                    .foregroundColor(.yellow)
                    Spacer()
                    Button {
                        sessionController.workoutManager.addArrow()
                    } label: {
                        Image(systemName: "plus.square.fill")
                            .resizable()
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 35, height: 35)
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                }
                .disabled(!sessionController.buttonsEnabled)
                Text("Arrows shot")
                    .font(.footnote)
            }
        }
    }
    
}

class ActiveSessionController: ObservableObject, ShotsWorkoutDelegate, SyncWorkoutManagerDelegate {
    
    //Timer
    @Published var timerStartDate = Date.now
    @Published var timerTimeElapsed: TimeInterval = .zero
    let timer = Timer.publish(every: 1.0, on: .main, in: .common)
    private var cancellableTimer: AnyCancellable?
    
    @Published
    var workoutManager = ShotsWorkoutManager.shared
    let syncManager = SyncWorkoutManager.shared
    
    @Published var buttonsEnabled = true
    
    init() {
        startSession()
    }
    
    func startSession() {
        workoutManager.delegate = self
        workoutManager.isSaveWorkoutActive = K.isSaveWorkoutActive
        let formatter = DateFormatter()
        let timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let id = formatter.string(from: Date())
        workoutManager.startWorkout(id: id, type: .FREE)
        syncManager.delegate = self
        restartTimer()
    }
    
    //Timer
    func restartTimer(){
        stopTimer()
        timerTimeElapsed = .zero
        timerStartDate = Date.now
        startTimer()
    }
    
    func startTimer() {
        timerStartDate = Date.now.addingTimeInterval(-timerTimeElapsed)
        cancellableTimer = timer.autoconnect().receive(on: DispatchQueue.main).sink { firedDate in
            self.timerTimeElapsed = firedDate.timeIntervalSince(self.timerStartDate)
        }
    }
    
    func stopTimer(){
        cancellableTimer?.cancel()
    }
    
    //Saving data
    func didFinishSaveTasks(){
        print("Task finished. Enabling buttons")
        DispatchQueue.main.async {
            self.buttonsEnabled = true
        }
        
    }
    
    func didStartSaveTasks(){
        print("Task starting. Disabling buttons")
        DispatchQueue.main.async {
            self.buttonsEnabled = false
        }
        
    }
    
    //Workout manager
    func workoutManager(didUpdateSession data: ShotsSessionDetails) {
        //
    }
    
    func workoutManager(didStopWorkout withData: ShotsSessionDetails) {
        stopTimer()
        syncManager.sendArrowCount()
    }
    func workoutManager(didLockScreen withData: ShotsSessionDetails?) {
        //Nothing to do
    }
    func workoutManager(didStartWorkout withData: ShotsSessionDetails) {
        //Nothing to do
    }
    func workoutManager(didPauseWorkout withData: ShotsSessionDetails) {
        stopTimer()
        syncManager.saveWorkout()
    }
    func workoutManager(didResumeWorkout withData: ShotsSessionDetails) {
        restartTimer()
    }
    
}

struct ActiveSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveSessionView(isShowingActiveSessionView: .constant(true))
    }
}
