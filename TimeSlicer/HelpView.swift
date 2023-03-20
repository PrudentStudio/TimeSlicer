//
//  HelpView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 08/03/23.
//

import EventKit
import SwiftUI

#if os(macOS)
    class HelpWindowController: NSWindowController {
        convenience init() {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.center()
            window.title = "Help"
            window.contentView = NSHostingView(rootView: HelpView())
            self.init(window: window)
        }

        override func windowDidLoad() {
            super.windowDidLoad()
            window?.center()
        }

        override func close() {
            super.close()
            window = nil // Release the window and its associated views
        }
    }
#endif

struct HelpView: View {
    @State private var isCalendarPermissionGranted: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Setting up Calendars and Permissions")
                        .font(.title)
                    #if os(iOS)
                        Text("Click on the Settings icon and customise the following options:")
                    #elseif os(macOS)
                        Text("Open the app preferences by using CMD+, and customise the following options:")
                    #endif
                    Text("1. Pick Calendars to Sync With - The calendars you choose to sync from are used to block timeslots when the app will not organise any events.")
                    Text("2. Primary Calendar Account to Write to - The primary account source you choose will have a new Calendar be created called \"TimeSlicer\", this is where the app writes the events to.")
                    Text("3. Working Hours - This is used to enforce blackout times, tasks will not be scheduled outside this time range.")
                    Text("Organizing your Calendar")
                        .font(.title)
                    Text("Click the Schedule Calendar on the bottom right of the screen.")
                    Text("Unable to create a calendar")
                        .font(.title)
                    Text("If the app is telling you that it is unable to create the calendar, you are most likely using a Google Calendar account. You will manually have to create a calendar titled \"TimeSlicer\".\n")
                    if checkCalendarAuthorizationStatus() {
                        Text("TimeSlicer requires permission for the Calendar to be able to work properly, but you have already granted these permissions")
                    } else {
                        Button(action: {
                            requestCalendarPermission()
                        }) {
                            Text("TimeSlicer requires permission for the Calendar to be able to work properly. Grant Calendar Permission")
                        }
                    }
                }
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            }
            .navigationTitle("Help!")
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
            eventStore.requestAccess(to: .event) { granted, _ in
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

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
