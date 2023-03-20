//
//  MacSettingsView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 10/03/23.
//

#if os(macOS)
    import EventKit
    import SwiftUI

    extension EKCalendar: Identifiable {
        public var id: String {
            calendarIdentifier
        }
    }

    extension View {
        @discardableResult
        func openInWindow(title: String, sender: Any?) -> NSWindow {
            let controller = NSHostingController(rootView: self)
            let win = NSWindow(contentViewController: controller)
            win.contentViewController = controller
            win.title = title
            win.makeKeyAndOrderFront(sender)
            return win
        }
    }

    struct CalendarSettingsView: View {
        let eventStore = EKEventStore()
        @State public var selectedSource: EKSource?
        @State private var allSources: [EKSource] = []
        @State private var allCalendars: [EKCalendar] = []
        @State public var dayStart = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents(hour: 8))!
        @State public var dayEnd = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents(hour: 20))!
        @State public var aggressive = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.bool(forKey: "Aggressive")

        @State private var isShowingCalendarPicker = false

        var body: some View {
            HStack {
                Spacer()
                Form {
                    Section {
                        Picker("Primary Calendar Account to Write To", selection: $selectedSource) {
                            ForEach(allSources, id: \.title) { source in
                                Text(source.title)
                                    .tag(source as EKSource?)
                            }

                        }.onChange(of: selectedSource) { _ in
                            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(selectedSource!.sourceIdentifier, forKey: "primarySource")
                        }
                        Button("Pick Calendars to Sync With") {
                            isShowingCalendarPicker = true
                        }
                    }

                    Section {
                        Text("Select your working hours:")
                        DatePicker("Start Time", selection: $dayStart, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $dayEnd, displayedComponents: [.hourAndMinute])
                    }
                    Section {
                        Text("Scheduling Behaviour:")
                        Toggle("Aggressive", isOn: $aggressive)
                    }
                    Section {
                        Button("Save Changes") {
                            print("Saving")
                            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(aggressive, forKey: "Aggressive")
                            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(dayStart, forKey: "DayStart")
                            UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(dayEnd, forKey: "DayEnd")
                        }
                    }
                }
                .onAppear {
                    fetchSources()
                    aggressive = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.bool(forKey: "Aggressive")
                    dayStart = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents(hour: 8))!
                    dayEnd = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents(hour: 20))!
                    print(dayStart)
                }

                Spacer()
            }
            .sheet(isPresented: $isShowingCalendarPicker) {
                EKCalendarPickerView()
            }
        }

        func fetchSources() {
            let eventStore = EKEventStore()
            let sources = eventStore.sources.filter { $0.sourceType == .calDAV || $0.sourceType == .local }

            let calIdentifier: String = UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.string(forKey: "primarySource") ?? ""

            if calIdentifier == "" {
                DispatchQueue.main.async {
                    allSources = sources
                    selectedSource = sources.first
                }
            } else {
                for source in sources {
                    print(source)
                    if source.sourceIdentifier.trimmingCharacters(in: .whitespaces) == calIdentifier.trimmingCharacters(in: .whitespaces) {
                        DispatchQueue.main.async {
                            allSources = sources
                            selectedSource = source
                        }
                    }
                }
            }
        }
    }

    struct DangerZoneView: View {
        var body: some View {
            Form {
                Section {
                    Button("Force Delete App Calendar", role: .destructive) {
                        cleanCalendar()
                    }
                    Button("Reset Onboarding Screen", role: .destructive) {
                        UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.set(false, forKey: "onboarded")
                        print(!(UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.bool(forKey: "onboarded")))
                        print(UserDefaults(suiteName: "group.com.navanchauhan.timeslicer")!.bool(forKey: "onboarded"))
                    }
                }
            }
        }
    }

    struct MacSettingsView: View {
        var body: some View {
            TabView {
                CalendarSettingsView()
                    .tabItem {
                        Label("Calendars", systemImage: "calendar.circle")
                    }

                DangerZoneView()
                    .tabItem {
                        Label("Danger Zone", systemImage: "exclamationmark.octagon")
                    }
            }
            .frame(minWidth: 450, minHeight: 250)
        }
    }

    struct MacSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            MacSettingsView()
        }
    }
#endif
