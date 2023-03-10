//
//  HelpView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 08/03/23.
//

import SwiftUI

#if os(macOS)
class HelpWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Help"
        window.contentView = NSHostingView(rootView: HelpView())
        self.init(window: window)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.center()
    }

    override func close() {
        super.close()
        window = nil // Release the window and its associated views
    }
}
#endif

struct HelpView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("Unable to create a calendar")
                    Text("If the app is telling you that it is unable to create the calendar, you are most likely using a Google Calendar account. You will manually have to create a calendar titled \"TimeSlicer\".")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
