//
//  TimeSlicerApp.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI

@main
struct TimeSlicerApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isPresentingAddTask = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .sheet(isPresented: $isPresentingAddTask) {
                    TaskCreatorSheet(isPresentingAddTask: $isPresentingAddTask)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .padding(.vertical, 20)
                }
        }.commands {
            CommandGroup(replacing: .newItem, addition: {
                Button(action: {
                    isPresentingAddTask = true
                }) {
                    Label("Add Task", systemImage: "plus")
                }.keyboardShortcut("n")
            })
        }
        #if os(macOS)
            Settings {
                MacSettingsView()
            }
        #endif
    }
}
