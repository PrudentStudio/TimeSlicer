//
//  ContentView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isPresentingSheet = true // Hardcoding for demo, otherwise !(checkCalendarAuthorizationStatus)
    @State private var isPresentingAddTask = false
    
    @State private var searchText = ""
    @State private var showCancelButton = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tasks.timestamp, ascending: true)],
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
        NavigationView {
            List {
                ForEach(searchResults, id: \.self) { item in
                    NavigationLink {
                        ItemDetail(item: item)
                    } label: {
                        Text(item.title!)
                            .padding()
                    }
                }
                .onDelete(perform: deleteItems)
            }.searchable(text: $searchText)
            .toolbar {
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
            .navigationBarTitle("TimeSlicer", displayMode: .large)
            Text("Select an item")
                
        }.sheet(isPresented: $isPresentingSheet) {
            CalendarPermissions(isPresentingSheet: $isPresentingSheet)
        }.sheet(isPresented: $isPresentingAddTask) {
            TaskCreatorSheet(isPresentingAddTask: $isPresentingAddTask)
                .environment(\.managedObjectContext, viewContext)
        }
        .overlay(
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                           print("Hellllo")
                            print(UserDefaults.standard.stringArray(forKey: "selectedCals"))
                            print(Date().endOfWeek)
                            let calendar = Calendar.current
                            var components = DateComponents()
                            components.year = 2023
                            components.month = 03
                            components.day = 04
                            components.hour = 01
                            components.minute = 59
                            components.second = 59
                            let start_date = calendar.date(from: components)
                            components.day = 10
                            let end_date = calendar.date(from: components)
                            var myTimeboxes = createTimeboxes(startDate: start_date!, endDate: end_date!)
                            var cnt = 0
                            var avail = 0
                            for box in myTimeboxes {
                                if box.isAvailable {
                                    avail += 1
                                }
                                cnt += 1
                            }
                            print(cnt)
                            print(avail)
                        }) {
                            Image(systemName: "calendar.badge.plus")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, geometry.safeAreaInsets.bottom+16)
                    }
                }
            }
        )
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
    let item: Tasks

    var body: some View {
        VStack {
            Text(item.desc!)
        }
        .navigationTitle(item.title!)
    }
}
