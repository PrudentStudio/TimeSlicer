//
//  SettingsView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI
import EventKit
#if os(iOS)
import EventKitUI
#endif

struct SettingsView: View {
    @State public var dayStart = UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!
    @State public var dayEnd = UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!
    @State public var aggressive = UserDefaults.standard.bool(forKey: "Aggressive")
    let eventStore = EKEventStore()
    @State var selectedCals: [String] = UserDefaults.standard.stringArray(forKey: "selectedCals") ?? []
    @State private var isPresentingCalendarChooser = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("About")) {
                    Link(destination: URL(string: "https://www.example.com")!) {
                        Label("Visit our website", systemImage: "globe")
                    }
                }
#if os(iOS)
                Section(header: Text("Calendars")) {
                    Text("Selected calendars: \(selectedCals.count)")
                    Button("Choose Calendars") {
                        isPresentingCalendarChooser = true
                    }
                    .sheet(isPresented: $isPresentingCalendarChooser) {
                        CalendarChooserView(selectedCalendars: $selectedCals)
                    }
                }
                Section(header: Text("Blackout Dates")){
                    Text("Select your working hours:")
                    DatePicker("Start Time", selection: $dayStart , displayedComponents: [.hourAndMinute])
                    DatePicker("End Time", selection: $dayEnd, displayedComponents: [.hourAndMinute])
                }
                Section(header: Text("Scheduling Style")){
                    Toggle("Aggressive", isOn: $aggressive)
                }
                
#endif
            }
#if os(iOS)
            .listStyle(GroupedListStyle())
#endif
            .navigationTitle("Settings")
        }
        .onDisappear(){
            print("Closing and saving")
            UserDefaults.standard.set(aggressive, forKey: "Aggressive")
            UserDefaults.standard.set(dayStart, forKey: "DayStart")
            UserDefaults.standard.set(dayEnd, forKey: "DayEnd")
        }
        .onAppear(){
            aggressive = UserDefaults.standard.bool(forKey: "Aggressive")
            dayStart = UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!
            dayEnd = UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!
        }
    }

    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#if os(iOS)
struct CalendarChooserView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = EKCalendarChooser
    
    @Binding var selectedCalendars: [String]
    
    func makeUIViewController(context: Context) -> EKCalendarChooser {
        let calendarChooser = EKCalendarChooser(selectionStyle: .multiple, displayStyle: .allCalendars, entityType: .event, eventStore: EKEventStore())
        calendarChooser.selectedCalendars = getCalendarsByIdentifiers(selectedCalendars) ?? []
        calendarChooser.showsDoneButton = true
        calendarChooser.showsCancelButton = true
        calendarChooser.delegate = context.coordinator
        return calendarChooser
    }
    
    func updateUIViewController(_ uiViewController: EKCalendarChooser, context: Context) {
        uiViewController.selectedCalendars = getCalendarsByIdentifiers(selectedCalendars) ?? []
        print(selectedCalendars)
    }
    
    func makeCoordinator() -> Coordinator {
        let calendars = getCalendarsByIdentifiers(selectedCalendars) ?? []
        return Coordinator(selectedCalendars: Binding<Set<EKCalendar>>(
            get: { Set(calendars) },
            set: { newValue in
                let identifiers = newValue.map { $0.calendarIdentifier }
                selectedCalendars = identifiers
                UserDefaults.standard.set(identifiers, forKey: "selectedCals")
            }
        ))
    }
    
    class Coordinator: NSObject, EKCalendarChooserDelegate {
        
        @Binding var selectedCalendars: Set<EKCalendar>
        
        init(selectedCalendars: Binding<Set<EKCalendar>>) {
            _selectedCalendars = selectedCalendars
        }
        
        func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
            selectedCalendars = calendarChooser.selectedCalendars
            print(selectedCalendars)
            var selectedCals: [String] = []
            for cal in selectedCalendars {
                selectedCals.append(cal.calendarIdentifier)
            }
            UserDefaults.standard.set(selectedCals, forKey: "selectedCals")
        }
        
        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            selectedCalendars = calendarChooser.selectedCalendars
            calendarChooser.dismiss(animated: true, completion: nil)
        }
        
        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            calendarChooser.dismiss(animated: true, completion: nil)
        }
    }
}
    
func getCalendarsByIdentifiers(_ identifiers: [String]) -> Set<EKCalendar>? {
    let eventStore = EKEventStore()
    let calendars = eventStore.calendars(for: .event)
    var result: [EKCalendar] = []
    
    for calendar in calendars {
        if identifiers.contains(calendar.calendarIdentifier) {
            result.append(calendar)
        }
    }
    
    return result.isEmpty ? [] : Set(result)
}
#endif
