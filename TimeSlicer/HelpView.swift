//
//  HelpView.swift
//  TimeSlicer
//
//  Created by Navan Chauhan on 08/03/23.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Unable to create a calendar")
                Text("If the app is telling you that it is unable to create the calendar, you are most likely using a Google Calendar account. You will manually have to create a calendar titled \"TimeSlicer\".")
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
