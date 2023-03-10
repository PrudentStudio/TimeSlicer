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
    @State public var selectedSource: EKSource?
    @State private var allSources: [EKSource] = []
    @State private var isPresentingCalendarChooser = false
    
    var body: some View {
        NavigationStack {
            Form {/*
                Section(header: Text("About")) {
                    Link(destination: URL(string: "https://www.example.com")!) {
                        Label("Visit our website", systemImage: "globe")
                    }
                }
                   */
#if os(iOS)
                Section(header: Text("Calendars")) {
                    Text("Selected calendars: \(selectedCals.count)")
                    Button("Choose Calendars to View Events For") {
                        isPresentingCalendarChooser = true
                    }
                    .sheet(isPresented: $isPresentingCalendarChooser, onDismiss: {
                        selectedCals = UserDefaults.standard.stringArray(forKey: "selectedCals") ?? []
                    }) {
                        CalendarChooserView(selectedCalendars: $selectedCals)
                    }
                    Picker("Primary Calendar", selection: $selectedSource) {
                        ForEach(allSources, id: \.title) { source in
                            Text(source.title)
                                .tag(source as EKSource?)
                        }
                        
                    }.onChange(of: selectedSource) { _ in
                        UserDefaults.standard.set(selectedSource!.sourceIdentifier, forKey: "primarySource")
                    }
                    Button("Clear selected calendars", role: .destructive){
                        UserDefaults.standard.set([], forKey: "selectedCals")
                        selectedCals = []
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
                Section(header: Text("Danger Zone")) {
                    Button("Force Delete App Calendar", role: .destructive) {
                        cleanCalendar()
                    }
                    Button("Reset OnBoarding Screen", role: .destructive) {
                        UserDefaults.standard.set(false, forKey: "onboarded")
                        print(!(UserDefaults.standard.bool(forKey: "onboarded")))
                        print((UserDefaults.standard.bool(forKey: "onboarded")))
                    }
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
            UserDefaults.standard.set(selectedCals, forKey: "selectedCals")
            UserDefaults.standard.set(aggressive, forKey: "Aggressive")
            UserDefaults.standard.set(dayStart, forKey: "DayStart")
            UserDefaults.standard.set(dayEnd, forKey: "DayEnd")
        }
        .onAppear(){
            fetchSources()
            aggressive = UserDefaults.standard.bool(forKey: "Aggressive")
            dayStart = UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!
            dayEnd = UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!
            selectedCals = UserDefaults.standard.stringArray(forKey: "selectedCals") ?? []
        }
    }

    func fetchSources(){
        let eventStore = EKEventStore()
        let sources =  eventStore.sources.filter({ $0.sourceType == .calDAV || $0.sourceType == .local })
        
        let calIdentifier: String = UserDefaults.standard.string(forKey: "primarySource") ?? ""
        
        if (calIdentifier == "" ) {
            DispatchQueue.main.async {
                self.allSources = sources
                self.selectedSource = sources.first
            }
        } else {
            for source in sources {
                if (source.sourceIdentifier.trimmingCharacters(in: .whitespaces) == calIdentifier.trimmingCharacters(in: .whitespaces)) {
                    DispatchQueue.main.async {
                        self.allSources = sources
                        self.selectedSource = source
                    }
                }
            }
            
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
        let chooser = EKCalendarChooser(selectionStyle: .multiple, displayStyle: .allCalendars, entityType: .event, eventStore: EKEventStore())
        
        chooser.selectedCalendars = getCalendarsByIdentifiers(UserDefaults.standard.stringArray(forKey: "selectedCals") ?? [])!
        chooser.delegate = context.coordinator
        return chooser
    }
    
    func updateUIViewController(_ uiViewController: EKCalendarChooser, context: Context) {
        uiViewController.selectedCalendars = getCalendarsByIdentifiers(UserDefaults.standard.stringArray(forKey: "selectedCals") ?? [])!
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedCalendars: $selectedCalendars)
        
    }
    
    class Coordinator: NSObject, EKCalendarChooserDelegate {
        
        let eventStore = EKEventStore()
            let calendarChooser: EKCalendarChooser
            
            init(selectedCalendars: Binding<[String]>) {
                
                self.calendarChooser = EKCalendarChooser(
                    selectionStyle: .multiple,
                    displayStyle: .allCalendars,
                    entityType: .event,
                    eventStore: eventStore
                )
                self.calendarChooser.selectedCalendars = getCalendarsByIdentifiers(UserDefaults.standard.stringArray(forKey: "selectedCals") ?? [])!
                self.calendarChooser.showsDoneButton = true
                self.calendarChooser.showsCancelButton = true
                super.init()
                self.calendarChooser.delegate = self
            }
        
        func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
            print(calendarChooser.selectedCalendars)
            var myCalendarStrings: [String] = []
            // Can be reduced to a map but im exhausted
            for cal in calendarChooser.selectedCalendars {
                myCalendarStrings.append(cal.calendarIdentifier)
            }
            UserDefaults.standard.set(myCalendarStrings, forKey: "selectedCals")
        }
    }
}
#endif

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
