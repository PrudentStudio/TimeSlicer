//
//  CalendarPermissions.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI
import EventKit

let eventStore = EKEventStore()

struct CalendarPermissions: View {
    @State private var isCalendarPermissionGranted = false
    @State public var selectedSource: EKSource?
    @State private var allSources: [EKSource] = []
    
    @Binding var isPresentingSheet: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Step 0 - Permissions")) {
                    if (checkCalendarAuthorizationStatus()) {
                        Text("You have already granted these permissions")
                    } else {
                        Button(action: {
                            requestCalendarPermission()
                            fetchSources()
                        }) {
                            Text("Grant Calendar Permission")
                        }
                    }
                }
                Section(header: Text("Step 1 - Primary Calendar Source")) {
                    Text("Which Calendar source do you want us to write the tasks to?")
                    Picker("Primary Calendar", selection: $selectedSource) {
                        ForEach(allSources, id: \.sourceIdentifier) { source in
                            Text(source.title)
                        }
                        
                    }
                }
                Section(header: Text("Step 2 - Configure ze App")) {
                    Text("Don't forget to go to the settings section and fine-tune the app")
                }
        }
            .navigationTitle("Onboarding")
        }.onAppear(perform: {
            fetchSources()
        })
    }
    
    func fetchSources(){
        let eventStore = EKEventStore()
        let sources =  eventStore.sources.filter({ $0.sourceType == .calDAV || $0.sourceType == .local })
        
        DispatchQueue.main.async {
            self.allSources = sources
            self.selectedSource = sources.first
        }
    }
    
    func requestCalendarPermission() {
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            isCalendarPermissionGranted = true
        case .denied:
            isCalendarPermissionGranted = false
        case .notDetermined:
            eventStore.requestAccess(to: .event) { (granted, error) in
                DispatchQueue.main.async {
                    isCalendarPermissionGranted = granted
                }
                
            }
        case .restricted:
            isCalendarPermissionGranted = false
        @unknown default:
            isCalendarPermissionGranted = false
        }
    }
    
    func checkCalendarAuthorizationStatus() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            // The app has permission to access the user's calendar
            return true
        case .denied, .restricted:
            // The app does not have permission to access the user's calendar
            return false
        case .notDetermined:
            // The user has not yet been asked to grant permission to the app
            return false
        @unknown default:
            return false
        }
    }
    
    
}
