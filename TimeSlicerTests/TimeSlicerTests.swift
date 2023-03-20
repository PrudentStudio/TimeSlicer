//
//  TimeSlicerTests.swift
//  TimeSlicerTests
//
//  Created by Navan Chauhan on 20/03/23.
//

@testable import EventKit
@testable import TimeSlicer
import XCTest

final class TimeSlicerTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // Test case for the `numBoxes(from_start:to_end:time_interval:)` function
    func testNumBoxes() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(60 * 60 * 2) // 2 hours later
        XCTAssertEqual(numBoxes(from_start: startDate, to_end: endDate, time_interval: 30), 4)
        XCTAssertEqual(numBoxes(from_start: startDate, to_end: endDate, time_interval: 15), 8)
    }

    // Test case for the `getEvents(from_start:to_end:)` function
    func testGetEvents() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(60 * 60 * 2) // 2 hours later
        let events = getEvents(from_start: startDate, to_end: endDate)
        XCTAssertNotNil(events)
    }

    // Test case for the `createTimeboxes(startDate:endDate:time_interval:)` function
    func testCreateTimeboxes() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(60 * 60 * 2) // 2 hours later
        let timeboxes = createTimeboxes(startDate: startDate, endDate: endDate, time_interval: 30)
        XCTAssertNotNil(timeboxes)
        XCTAssertGreaterThan(timeboxes.count, 0)
    }

    func testPerformanceExample() throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(60 * 60 * 24 * 7) // 1 week later
        let timeInterval = 10 // 10 minutes

        // This measures the time it takes to create the timeboxes
        measure {
            _ = createTimeboxes(startDate: startDate, endDate: endDate, time_interval: timeInterval)
        }
    }
}
