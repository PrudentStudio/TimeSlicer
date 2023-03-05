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
    
    @State private var isPresentingSheet = false //UserDefaults.standard.bool(forKey: "permission");
    @State private var isPresentingAddTask = false
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tasks.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Tasks>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                }
                .onDelete(perform: deleteItems)
            }
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
            Text("Select an item")
                
        }.sheet(isPresented: $isPresentingSheet) {
            CalendarPermissions()
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
                            isPresentingAddTask = true
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
