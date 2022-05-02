//
//  ContentView.swift
//  Shared
//
//  Created by Nathan Wick on 2/23/22.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("logStatus") var logStatus = false
    @State private var selection = 2
    var body: some View {
        if logStatus {
            TabView(selection:$selection) {
                PostView().tabItem {
                    Image(systemName: "plus.circle")
                    Text("Return")
                }.tag(1)
                FindView().tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Find")
                }.tag(2)
                MessageView().tabItem {
                    Image(systemName: "message")
                    Text("Message")
                }.tag(3)
                UserView().tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }.tag(4)
            }
        } else {
            AuthenticationView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
