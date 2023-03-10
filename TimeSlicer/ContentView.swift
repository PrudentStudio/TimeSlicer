//
//  ContentView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI
import CoreData

import AlertToast

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    #if os(iOS)
    @State private var isPresentingSheet = !(UserDefaults.standard.bool(forKey: "onboarded"))
    #elseif os(macOS)
    @State private var isPresentingSheet = false
    #endif
    @State private var isPresentingAddTask = false
    
    @State private var searchText = ""
    @State private var showCancelButton = false
    
    @State private var showToast = false
    @State private var showErrorToast = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tasks.timestamp, ascending: true)],
        predicate: NSPredicate(format: "done == nil OR done == false"),
        animation: .default)
    private var items: FetchedResults<Tasks>
    
    var searchResults: [Tasks] {
        if searchText.isEmpty {
            return Array(items);
        } else {
            return items.filter { $0.title?.lowercased().contains(searchText.lowercased()) == true || $0.description.lowercased().contains(searchText.lowercased()) == true }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults, id: \.self) { item in
                    NavigationLink {
                        ItemDetail(item: item)
                    } label: {
                        Text(item.title!)
                            .padding()
                    }.swipeActions(edge: .leading) {
                        Button(action: {
                            item.done = true
                            
                        }) {
                            Label("Done", systemImage: "briefcase")
                        }.tint(.teal)
                    }
                }
                .onDelete(perform: deleteItems)
            }.searchable(text: $searchText)
            .toolbar {
                ToolbarItem {
                    #if os(iOS)
                    NavigationLink(destination: HelpView()) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    #elseif os(macOS)
                    Button(action: {
                        let windowController = HelpWindowController()
                        windowController.showWindow(nil)
                    }) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    #endif
                }
                ToolbarItem {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: {isPresentingAddTask=true}){//addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitle("TimeSlicer", displayMode: .large)
            #elseif os(OSX)
            .navigationTitle("TimeSlicer")
            #endif
                
        }.sheet(isPresented: $isPresentingSheet, onDismiss: {
            UserDefaults.standard.set(true, forKey: "onboarded")
            print("just set", UserDefaults.standard.bool(forKey: "onboarded"))
        }) {
            CalendarPermissions(isPresentingSheet: $isPresentingSheet)
        }.sheet(isPresented: $isPresentingAddTask) {
            TaskCreatorSheet(isPresentingAddTask: $isPresentingAddTask)
                .environment(\.managedObjectContext, viewContext)
                .padding(.vertical, 20)
        }.toast(isPresenting: $showToast, duration: 4){
            
            // `.alert` is the default displayMode
            AlertToast(type: .complete(.teal), title: "Calendar Organized!")
            
        }.toast(isPresenting: $showErrorToast, duration: 4) {
            AlertToast(displayMode: .hud, type: .error(.red), title: "Error Creating Calendar", subTitle: "Please click on the help icon for more details")
        }
        .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    let aggressive: Bool = UserDefaults.standard.bool(forKey: "Aggressive")
                                    
                                    var timeInterval = 60
                                    if aggressive {
                                        timeInterval = 10
                                    }
                                    
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.year, .month, .day], from: Date())
                                    
                                    
                                    /*
                                     components.year = 2023
                                     components.month = 03
                                     components.day = 06
                                     components.hour = 01
                                     components.minute = 59
                                     components.second = 59
                                     let start_date = calendar.date(from: components)
                                     components.day = 10
                                     let end_date = calendar.date(from: components)
                                     */
                                    
                                    let start_date = calendar.date(from: components)!
                                    let end_date = start_date.addingTimeInterval(7*24*60*60) // 7 days = 7*24*60*60
                                    
                                    let myTimeboxes = createTimeboxes(startDate: start_date, endDate: end_date, time_interval: timeInterval)
                                    var cnt = 0
                                    var avail = 0
                                    for box in myTimeboxes {
                                        if box.isAvailable {
                                            avail += 1
                                        }
                                        cnt += 1
                                    }
                                    let myTasks = scheduleTasks(tasks: Array(items), timeboxes: myTimeboxes, time_interval: timeInterval)
                                    if myTasks.count < items.count {
                                        showErrorToast = true
                                    } else {
                                        showToast = true
                                    }
                                    
                                }) {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, geometry.safeAreaInsets.bottom)
                            }
                        }
                    }
        )
    }
    
    private func commit() {
        withAnimation {
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Tasks(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct ItemDetail : View {
    @Environment(\.managedObjectContext) private var viewContext
    let item: Tasks
    
    let date = Date()
        let formatter = ISO8601DateFormatter()

    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                Text(item.desc ?? "No Description Provided")
                HStack {
                    Text("Due")
                    Text(formatter.string(from: item.duedate!))
                }
            }
            Section(header: Text("Actions")) {
                Button(action: {
                    item.done = true
                    do {
                        try viewContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }) {
                    Text("Mark as Done")
                }
                
            }
            
            
        }
        .navigationTitle(item.title!)
    }
}
