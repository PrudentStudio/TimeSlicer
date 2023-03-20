//
//  CalendarFunctions.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 14/03/23.
//

import EventKit
import Foundation

func getCalendarsByIdentifiers(_ identifiers: [String]) -> Set<EKCalendar>? {
    let eventStore = EKEventStore()
    let calendars = eventStore.calendars(for: .event)
    var result: [EKCalendar] = []

    for calendar in calendars {
    if identifiers.contains(calendar.calendarIdentifier) {
            result.append(calendar)
        }
    }

    return result.isEmpty ? [] : Set(result)
}
