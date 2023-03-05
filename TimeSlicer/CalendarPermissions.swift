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
    @State private var selectedCalendar: EKCalendar?
    @State private var calendars: [EKCalendar] = []
    
    var body: some View {
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            Button(action: {requestCalendarPermission()}) {
                Text("Grant Calendar Permission")
            }
            Picker("Select a calendar", selection: $selectedCalendar) {
                            ForEach(calendars, id: \.calendarIdentifier) { calendar in
                                Text(calendar.title)
                            }
                        }
                        .disabled(calendars.isEmpty)
        }.onAppear(perform: fetchCalendars)
    }
    
    func fetchCalendars() {
            let eventStore = EKEventStore()
            let calendars = eventStore.calendars(for: .event)

            // Filter the calendars to include only those that are visible and writable
            let visibleCalendars = calendars.filter { calendar in
                calendar.allowsContentModifications && calendar.allowedEntityTypes.contains(.event)
            }

            DispatchQueue.main.async {
                self.calendars = visibleCalendars
                self.selectedCalendar = visibleCalendars.first
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
}

struct CalendarPermissions_Previews: PreviewProvider {
    static var previews: some View {
        CalendarPermissions()
    }
}
