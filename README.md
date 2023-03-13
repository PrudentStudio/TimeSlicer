# TimeSlicer

Open-Source timeboxing app with multi-calendar sync support. This project was 
originally written for CU Hack 9. We decided to continue developing the app.

## Why would you wantt to timebox?

Timeboxing is a project management technique that involves setting a fixed amount of time to complete a task or project. By setting a time limit, you can focus on completing the task at hand and avoid distractions. 

## Features

* On-Device Scheduling
	* Using EventKit, all the calendar access and sync happens on device.
	* No data is sent off the device.
* Multi-Calendar Support
	* Any Calendar account added on the device can be used.
	* Chosen calendars are used to check availability.
	* A primary calendar source can be choosen to write the tasks to.
* Blackout Times
    * Option to block out times when you don't want tasks to be scheduled.
* Scheduling Priorities
    * Tasks with a higher priority level are scheduled first.
* Different Scheduling Behaviours
    * Aggressive Scheduling: Schedules tasks to get them all done as soon as possible.
    * Relaxed Scheduling: Schedule tasks by spacing them out evenly over the next seven days.
* Mac Support
    * By the grace of SwiftUI and a lot of `if os(macOS)`, the macOS and iOS apps sync seamlessly.
* Pester! Pester! Pester!
    * Unless you mark the task as done, the app will keep scheduling the task..

