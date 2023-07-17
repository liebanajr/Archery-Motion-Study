//
//  EndWorkoutView.swift
//  ArrowSense Watch App
//
//  Created by Juan Rodríguez on 17/7/23.
//  Copyright © 2023 liebanajr. All rights reserved.
//

import SwiftUI

struct EndWorkoutView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var sessionController: ActiveSessionController
    
    @State private var digitalCrownAmount = 0.0
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("End session")
                        .font(.title3)
                    Text("How many arrows did you shoot?")
                        .font(.footnote)
                        .multilineTextAlignment(.trailing)
                }
            }
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
                        Text("\(sessionController.workoutManager.sessionData?.arrowCounter ?? 0)")
                            .font(.system(.title2, design: .rounded))
                            .foregroundColor(.yellow)
//                            .focusable(true)
//                            .digitalCrownRotation(detent: $digitalCrownAmount, from: -.infinity, through: .infinity, by: 0.1, sensitivity: .high, isContinuous: true, isHapticFeedbackEnabled: true)
//                            .onChange(of: digitalCrownAmount) { newValue in
//                                print("digital crown value:\(newValue)")
//                                sessionController.workoutManager.sessionData?.arrowCounter += Int(digitalCrownAmount)
//                            }
                    }
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
                Button("Save") {
                    sessionController.workoutManager.stopWorkout()
                    dismiss()
                }
                .foregroundColor(.yellow)
            }
        }
        .padding()
        .task {
            if let arrowCount = sessionController.workoutManager.sessionData?.arrowCounter, arrowCount == 0 {
                let arrowsPerHour = 66.0
                let arrowsPerSecond = arrowsPerHour/(60*60)
                
                let elapsedTime = sessionController.workoutManager.sessionData?.elapsedSeconds ?? 0
                
                print("\(elapsedTime)*\(arrowsPerSecond) = \(-Double(elapsedTime) * arrowsPerSecond)")
                sessionController.workoutManager.sessionData?.arrowCounter = Int(-Double(elapsedTime) * arrowsPerSecond)
            }
        }
    }
}

struct EndWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        EndWorkoutView()
            .environmentObject(ActiveSessionController())
    }
}
