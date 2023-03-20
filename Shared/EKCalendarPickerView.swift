//
//  EKCalendarPickerView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 10/03/23.
//

import EventKit
import SwiftUI

// TODO: Add Done and Cancel Button

extension EKSource: Comparable {
    public static func < (lhs: EKSource, rhs: EKSource) -> Bool {
        lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

extension EKCalendar {
    var shouldSync: Bool {
        get {
            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.bool(forKey: calendarIdentifier)
        }
        set {
            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(newValue, forKey: calendarIdentifier)
            print("just set \(newValue) for calendar \(calendarIdentifier)")
        }
    }
}

class CalendarViewModel: ObservableObject {
    @Published var calendarDict: [EKSource: [EKCalendar]]

    init(calendarDict: [EKSource: [EKCalendar]]) {
        self.calendarDict = calendarDict
    }

    func updateShouldSync(for calendar: EKCalendar, shouldSync: Bool) {
        for (source, calendars) in calendarDict {
            if let index = calendars.firstIndex(of: calendar) {
                calendarDict[source]?[index].shouldSync = shouldSync
                UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(shouldSync, forKey: calendar.calendarIdentifier)
                UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.synchronize() // Force the changes to be saved immediately
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
            .frame(minWidth: 400, minHeight: 400)
            .onAppear(perform: fetchCalendars)
            .onDisappear(perform: {
                let calendarIDs = viewModel.calendarDict.values.flatMap { calendar in
                    calendar.filter(\.shouldSync).map(\.calendarIdentifier)
                }
                print(calendarIDs)
            })
            .navigationTitle("Calendar Picker")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .padding(.trailing, 20)
                    .help("Dismiss Calendar Picker")
                    .accessibility(label: Text("Done"))
                }
            }
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
