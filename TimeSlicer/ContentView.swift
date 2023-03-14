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
    
    @State private var isPresentingSheet = !(UserDefaults.standard.bool(forKey: "onboarded"))
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
        ZStack {
            NavigationStack {
                List {
                    ForEach(searchResults, id: \.self) { item in
                        NavigationLink {
                            ItemDetail(item: item)
                        } label: {
                            
#if os(macOS)
                            VStack {
                                
                                HStack{Text(item.title!)
                                        .padding()
                                    
                                }
                                Divider()
                                
                            }
#elseif os(iOS)
                            Text(item.title!)
                                .padding()
#endif
                        }.swipeActions(edge: .leading) {
                            Button(action: {
                                item.done = true
                                
                            }) {
                                Label("Done", systemImage: "briefcase")
                            }.tint(.teal)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }.refreshable(action: {
                    do {
                            try viewContext.save() // Save any pending changes to the data store
                            viewContext.refreshAllObjects() // Reload data from the data store
                        } catch let error as NSError {
                            print("Could not update data. \(error), \(error.userInfo)")
                        }
                })
                
                .searchable(text: $searchText)
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
#if os(iOS)
                        ToolbarItem {
                            NavigationLink(destination: SettingsView()) {
                                Label("Settings", systemImage: "gear")
                            }
                        }
#endif
                        ToolbarItem {
                            Button(action: {isPresentingAddTask=true}){
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
            FloatingButton(action: {
                let aggressive: Bool = UserDefaults.standard.bool(forKey: "Aggressive")
                
                var timeInterval = 60
                if aggressive {
                    timeInterval = 10
                }
                let myTimeboxes = createAndInitTimeboxes()
                let myTasks = scheduleTasks(tasks: Array(items), timeboxes: myTimeboxes, time_interval: timeInterval)
                if myTasks.count < items.count {
                    showErrorToast = true
                } else {
                    showToast = true
                }
                            }, icon: "hourglass.badge.plus")
        }
        
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


struct FloatingButton: View {
    let action: () -> Void
    let icon: String
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    #if os(iOS)
                    Image(systemName: icon)
                        .accessibilityLabel(Text("Schedule Calendar"))
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(.teal)
                        .cornerRadius(30)
                    #elseif os(macOS)
                    Text("Schedule Calendar")
                    #endif
                }
                
                .shadow(radius: 10)
                .offset(x: -25, y: -30)
                
            }
        }
    }
}
