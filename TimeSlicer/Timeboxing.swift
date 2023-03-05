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


func createTimeboxes(from startDate: Date, to endDate: Date) -> [Timebox] {
    var timeboxes = [Timebox]()
    
    // Helper function to check if a timebox is within working hours
    func isWithinWorkingHours(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let workingHoursStart = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: start)!
        let workingHoursEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: start)!
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        return start >= workingHoursStart && end <= workingHoursEnd && startComponents.hour! >= 8 && endComponents.hour! <= 20
    }
    
    let interval = 600.0 // 10 minutes
    var currentStart = startDate
    var currentEnd = currentStart.addingTimeInterval(interval)
    
    while currentEnd <= endDate {
        var timebox = Timebox(start: currentStart, end: currentEnd, events: [], isWorkingHours: false, isAvailable: false)
        if isWithinWorkingHours(start: currentStart, end: currentEnd) {
            timebox.isWorkingHours = true
            timebox.isAvailable = true
        }
        timeboxes.append(timebox)
        currentStart = currentEnd
        currentEnd = currentStart.addingTimeInterval(interval)
    }
    
    return timeboxes
}
