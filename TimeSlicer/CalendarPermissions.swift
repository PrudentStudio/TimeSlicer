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
    @State private var isCalendarPermissionGranted: Bool = false
    @State public var selectedSource: EKSource?
    @State private var allSources: [EKSource] = []
    @State public var hasCalendarAuthorization: Bool = false
    
    @Binding var isPresentingSheet: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Form {
                    Section(header: Text("Step 0 - Permissions")) {
                        if (hasCalendarAuthorization) {
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
                        Text("Which Calendar source do you want us to write the tasks to? If you choose a Google Calendar, you will have to first manually go and create a calendar titled \"TimeSlicer\". If you cannot see any sources here, after reading through these instructions, go to the preferences section.")
                            //.fixedSize(horizontal: false, vertical: true)
                            
                        Picker("Primary Calendar", selection: $selectedSource) {
                            ForEach(allSources, id: \.title) { source in
                                Text(source.title)
                                    .tag(source as EKSource?)
                            }
                            
                        }.onChange(of: selectedSource) { _ in
                            UserDefaults.init(suiteName: "group.com.navanchauhan.timeslicer")!.set(selectedSource!.sourceIdentifier, forKey: "primarySource")
                        }
                    }
                    Section(header: Text("Step 2 - Configure ze App")) {
                        Text("Don't forget to go to the settings section and fine-tune the app")
                    }
                    Section(header: Text("Step 3 - Add Tasks")) {
                        Text("Add tasks and tap the schedule calendar button")
                    }
                    
                    .lineLimit(nil)
                    #if os(macOS)
                    .frame(minWidth: 200, minHeight: 50)
                    #endif
                    
                }
                .navigationTitle("Onboarding")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                            Button("Done") {
                                isPresentingSheet = false
                                UserDefaults.init(suiteName: "group.com.navanchauhan.timeslicer")!.set(true, forKey: "onboarded")
                            }
                            .keyboardShortcut(.cancelAction)
                            .padding(.trailing, 20)
                            .help("Dismiss Onboarding Screen")
                            .accessibility(label: Text("Done"))
                        }
                }
                
            }.onAppear(perform: {
                fetchSources()
            })
            
        }
        
    }
    
    
    func fetchSources(){
        let eventStore = EKEventStore()
        let sources =  eventStore.sources.filter({ $0.sourceType == .calDAV || $0.sourceType == .local })
        
        let calIdentifier: String = UserDefaults.init(suiteName: "group.com.navanchauhan.timeslicer")!.string(forKey: "primarySource") ?? ""
        print(sources)
        if (calIdentifier == "" ) {
            DispatchQueue.main.async {
                self.allSources = sources
                self.selectedSource = sources.first
            }
        } else {
            print("identifier saved is")
            print(calIdentifier)
            for source in sources {
                print("found")
                print(source.sourceIdentifier)
                if (source.sourceIdentifier.trimmingCharacters(in: .whitespaces) == calIdentifier.trimmingCharacters(in: .whitespaces)) {
                    DispatchQueue.main.async {
                        self.allSources = sources
                        self.selectedSource = source
                    }
                }
            }
            
        }
        
    }
    
    func requestCalendarPermission() {
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            isCalendarPermissionGranted = true
            self.hasCalendarAuthorization = true
        case .denied:
            isCalendarPermissionGranted = false
            self.hasCalendarAuthorization = false
        case .notDetermined:
            eventStore.requestAccess(to: .event) { (granted, error) in
                DispatchQueue.main.async {
                    isCalendarPermissionGranted = granted
                    self.hasCalendarAuthorization = granted
                }
                
            }
        case .restricted:
            isCalendarPermissionGranted = false
            self.hasCalendarAuthorization = false
        @unknown default:
            isCalendarPermissionGranted = false
            self.hasCalendarAuthorization = false
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
