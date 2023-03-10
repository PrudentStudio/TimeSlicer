//
//  EKCalendarPickerView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 10/03/23.
//

import SwiftUI
import EventKit

//TODO: Add Done and Cancel Button

extension EKSource: Comparable {
    public static func < (lhs: EKSource, rhs: EKSource) -> Bool {
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

extension EKCalendar {
    var shouldSync: Bool {
        get {
            return UserDefaults.standard.bool(forKey: self.calendarIdentifier)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: self.calendarIdentifier)
            print("just set \(newValue) for calendar \(self.calendarIdentifier)")
        }
    }
}

class CalendarViewModel: ObservableObject {
    @Published var calendarDict: [EKSource: [EKCalendar]]
    
    init(calendarDict: [EKSource: [EKCalendar]]) {
            self.calendarDict = calendarDict
        }
    
    func updateShouldSync(for calendar: EKCalendar, shouldSync: Bool) {
        for (source, calendars) in self.calendarDict {
            if let index = calendars.firstIndex(of: calendar) {
                self.calendarDict[source]?[index].shouldSync = shouldSync
                UserDefaults.standard.set(shouldSync, forKey: calendar.calendarIdentifier)
                UserDefaults.standard.synchronize() // Force the changes to be saved immediately
                break
            }
        }
    }
}


struct EKCalendarPickerView: View {
     
    @State private var calendarDict: [EKSource: [EKCalendar]] = [:]
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CalendarViewModel
        
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.calendarDict.keys.sorted(), id: \.self) { source in
                    Section(header: Text(source.title)) {
                        ForEach(viewModel.calendarDict[source]!, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: Binding(
                                get: {
                                    calendar.shouldSync
                                },
                                set: { newValue in
                                    viewModel.updateShouldSync(for: calendar, shouldSync: newValue)
                                }
                            )) {
                                Text(calendar.title)
                            }
                            .toggleStyle(SwitchToggleStyle())
                        }
                    }
                }
            }
            .onAppear(perform: fetchCalendars)
            .onDisappear(perform: {
                let calendarIDs = viewModel.calendarDict.values.flatMap { calendar in
                    calendar.filter { $0.shouldSync}.map { $0.calendarIdentifier }
                }
                print(calendarIDs)
//                print("whoops")
//                var toSave: [String] = []
//                for source in viewModel.calendarDict.keys.sorted() {
//                    for myCal in viewModel.calendarDict[source]! {
//                        if myCal.shouldSync {
//                            toSave.append(myCal.calendarIdentifier)
//                        }
//                    }
//                }
//                UserDefaults.standard.set(toSave, forKey: "selectedCals")
//                UserDefaults.standard.synchronize()
            })
            
        }
        
    }
        
        init() {
            let eventStore = EKEventStore()
            let sources = eventStore.sources
            
            var calendarDict: [EKSource: [EKCalendar]] = [:]
            for source in sources {
                let cals = source.calendars(for: .event)
                if !cals.isEmpty {
                    calendarDict[source] = Array(cals)
                }
            }
            
            _viewModel = StateObject(wrappedValue: CalendarViewModel(calendarDict: calendarDict))
        }
    
    private func fetchCalendars() {
            viewModel.objectWillChange.send()
        }
}

struct EKCalendarPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EKCalendarPickerView()
    }
}
