//
//  MacSettingsView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 10/03/23.
//

#if os(macOS)
import SwiftUI
import EventKit

extension EKCalendar: Identifiable {
    public var id: String {
        return self.calendarIdentifier
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
    @State public var dayStart = UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!
    @State public var dayEnd = UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!
    @State public var aggressive = UserDefaults.standard.bool(forKey: "Aggressive")
    
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
                        UserDefaults.standard.set(selectedSource!.sourceIdentifier, forKey: "primarySource")
                    }
                    Button("Pick Calendars to Sync With") {
                        isShowingCalendarPicker = true
                    }
                    
                    
                }
                
                Section{
                    Text("Select your working hours:")
                    DatePicker("Start Time", selection: $dayStart , displayedComponents: [.hourAndMinute])
                    DatePicker("End Time", selection: $dayEnd, displayedComponents: [.hourAndMinute])
                }
                Section{
                    Text("Scheduling Behaviour:")
                    Toggle("Aggressive", isOn: $aggressive)
                    
                }
                Section {
                    Button("Save Changes") {
                        print("Saving")
                        UserDefaults.standard.set(aggressive, forKey: "Aggressive")
                        UserDefaults.standard.set(dayStart, forKey: "DayStart")
                        UserDefaults.standard.set(dayEnd, forKey: "DayEnd")
                    }
                }
            }
            .onAppear(){
                fetchSources()
                aggressive = UserDefaults.standard.bool(forKey: "Aggressive")
                dayStart = UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!
                dayEnd = UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!
                print(dayStart)
            }
            
            Spacer()
        }
        .sheet(isPresented: $isShowingCalendarPicker) {
            EKCalendarPickerView()
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
                if source.title == nil { // The picker does not display labels without this option
                    continue
                }
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
 
struct DangerZoneView: View {
    var body: some View {
        Form {
            Section {
                Button("Force Delete App Calendar", role: .destructive) {
                    cleanCalendar()
                }
                Button("Reset Onboarding Screen", role: .destructive) {
                    UserDefaults.standard.set(false, forKey: "onboarded")
                    print(!(UserDefaults.standard.bool(forKey: "onboarded")))
                    print((UserDefaults.standard.bool(forKey: "onboarded")))
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
