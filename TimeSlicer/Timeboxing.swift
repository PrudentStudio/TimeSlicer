//
//  Timeboxing.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 04/03/23.
//

import Foundation
import EventKit

extension Date {
    var startOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 1, to: sunday)
    }

    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 7, to: sunday)
    }
}


func numBoxes(from_start: Date, to_end: Date) -> Int {
    let minutes = Int(to_end.timeIntervalSince(from_start)/60)
    return minutes / 10
}

func getEvents(from_start: Date, to_end: Date) -> [EKEvent] {
    let myCalendarIdentifiers = UserDefaults.standard.stringArray(forKey: "selectedCals")
    let myCalendars = getCalendarsByIdentifiers(myCalendarIdentifiers ?? [])
    let eventStore = EKEventStore()
    let predicate = eventStore.predicateForEvents(withStart: from_start, end: to_end, calendars: Array(myCalendars ?? []))
    let events = eventStore.events(matching: predicate)
    return events
    
}

struct Timebox {
    var start: Date
    var end: Date
    var events: [EKEvent]
    var isWorkingHours: Bool
    var isAvailable: Bool
}


func createTimeboxes(startDate: Date, endDate: Date) -> [Timebox] {
    var timeboxes = [Timebox]()
    let events = getEvents(from_start: startDate, to_end: endDate)
    
    // Helper function to check if a timebox is within working hours
    func isWithinWorkingHours(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let userDefinedStartComponents = calendar.dateComponents([.hour, .minute], from: UserDefaults.standard.object(forKey: "DayStart") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 8))!)
        let userDefinedEndComponents = calendar.dateComponents([.hour, .minute], from: UserDefaults.standard.object(forKey: "DayEnd") as? Date ?? Calendar.current.date(from: DateComponents.init(hour: 20))!)
        let workingHoursStart = calendar.date(
            bySettingHour: userDefinedStartComponents.hour!,
            minute: userDefinedStartComponents.minute!,
            second: 0, of: start)!
        let workingHoursEnd = calendar.date(bySettingHour: userDefinedEndComponents.hour!, minute: userDefinedEndComponents.minute!, second: 0, of: start)!
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        return start >= workingHoursStart && end <= workingHoursEnd
    }
    
    let interval = 600.0 // 10 minutes
    var currentStart = startDate
    var currentEnd = currentStart.addingTimeInterval(interval)
    
    while currentEnd <= endDate {
        var timebox = Timebox(start: currentStart, end: currentEnd, events: [], isWorkingHours: false, isAvailable: false)
        timebox.isWorkingHours = false
        timebox.isAvailable = false
        if isWithinWorkingHours(start: currentStart, end: currentEnd) {
            timebox.isWorkingHours = true
            timebox.isAvailable = true
        }
        
        for myEvent in events {
            if (myEvent.isAllDay) {
                continue
            }
            if (myEvent.startDate < timebox.end && myEvent.endDate > timebox.start) {
                timebox.isAvailable = false
            }
            
        }
        
        timeboxes.append(timebox)
        currentStart = currentEnd
        currentEnd = currentStart.addingTimeInterval(interval)
    }
    
    return timeboxes
}

func scheduleTasks(tasks: [Tasks], timeboxes: [Timebox]) -> [Timebox] {
//    var sortedTasks = tasks.sorted {
//        $0.priority > $1.priority
//    }
    let priority1 = tasks.filter {$0.priority == 1}.sorted {$0.priority > $1.priority}
    let priority2 = tasks.filter {$0.priority == 2}.sorted {$0.priority > $1.priority}
    let priority3 = tasks.filter {$0.priority == 3}.sorted {$0.priority > $1.priority}
    let priority4 = tasks.filter {$0.priority == 4}.sorted {$0.priority > $1.priority}
    var sortedTasks = [priority1, priority2, priority3, priority4]
    
    var scheduledTimeboxes = timeboxes
    
    for tasks in sortedTasks {
        for myTask in tasks {
            print(myTask.title)
            var taskComplete = false
            if taskComplete {
                continue
            }
            var num_boxes_needed = myTask.duration / 10
            
            for i in 0..<scheduledTimeboxes.count {
                var timebox = scheduledTimeboxes[i]
                var validStartTime = true
                for j in 0..<num_boxes_needed{
                    if !timeboxes[i+Int(j)].isAvailable{
                        validStartTime = false
                        break
                    }
                }
                
                if scheduledTimeboxes[i].isAvailable == false {
                    continue
                }
                
                if validStartTime && !taskComplete {
                    var eventStart = timebox.start
                    var eventEnd = eventStart.addingTimeInterval(TimeInterval(myTask.duration * 60))
                    
                    var event = EKEvent(eventStore: eventStore)
                    event.title = myTask.title
                    event.startDate = eventStart
                    event.endDate = eventEnd
                    event.calendar = eventStore.calendars(for: .event).first(where: { $0.title == "RyanMcTime" }) ?? {
                        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
                        newCalendar.title = "RyanMcTime"
                        newCalendar.source = EKEventStore().sources.filter({ $0.sourceType == .calDAV || $0.sourceType == .local }).first
                        try? eventStore.saveCalendar(newCalendar, commit: true)
                        return newCalendar
                    }()
                    
                    do {
                        try eventStore.save(event, span: .thisEvent)
                        timebox.events.append(event)
                        timebox.isAvailable = false
                        for j in 0..<num_boxes_needed {
                            print(i+Int(j))
                            scheduledTimeboxes[i+Int(j)].isAvailable = false
                        }
                        print(scheduledTimeboxes[i].isAvailable)
                        taskComplete = true
                        
                        
                    } catch let error {
                        print("Error saving event: \(error.localizedDescription)")
                    }
                }
                
            }
        }
    }
    return scheduledTimeboxes
}


/*
func getWritableCalendar() -> EKCalendar {
    let myCalendarIdentifiers = UserDefaults.standard.stringArray(forKey: "selectedCals")
    let myCalendars = getCalendarsByIdentifiers(myCalendarIdentifiers ?? [])!
    for cal in myCalendars {
        if cal.isImmutable {
            continue
        } else {
            
        }
    }
}
*/
