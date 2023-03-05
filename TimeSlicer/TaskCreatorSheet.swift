//
//  TaskCreatorSheet.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import SwiftUI

struct TaskCreatorSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var duration: Int = 10
    @State private var description: String = ""
    @State private var priority = 1.0
    
    @Binding var isPresentingAddTask: Bool
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                        TextField("Task Title", text: $title)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Text("Priority (1-4)")
                    Slider(
                        value: $priority,
                        in: 1...4,
                        step: 1) {
                            Text("Priority (1-4)")
                        } minimumValueLabel: {
                            Text("1")
                        } maximumValueLabel: {
                            Text("4")
                        }
                        
                    Stepper(value: $duration, in: 10...120, step: 10, label: {
                            Text("Task Duration: \(duration) minute\(duration == 10 ? "" : "s")")
                        })
                        Text("Task Description:")
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(.vertical, 5)
                    }
                }
                .navigationTitle("New Task")
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                    
                        Button(action: {
                            if !(title=="") || !(description=="") {
                            let newItem = Tasks(context: viewContext)
                            newItem.timestamp = Date()
                            newItem.title = title
                            newItem.desc = description
                            newItem.duedate = dueDate
                            newItem.duration = Int16(duration)
                                newItem.priority = Int16(priority)

                                do {
                                    try viewContext.save()
                                } catch {
                                    // Replace this implementation with code to handle the error appropriately.
                                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                    let nsError = error as NSError
                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            }
                            isPresentingAddTask = false
                        }) {
                            Text("Save")
                        }
                    }
                    #endif
                }
            }
        }
}


