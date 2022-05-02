//
//  UserView.swift
//  IFoundIt
//
//  Created by Nathan Wick on 3/4/22.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct UserView: View {
    @AppStorage("userImage") var userImage = URL("https://nathanwick.com/img/user.png")
    @AppStorage("userName") var userName = "Unknown Name"
    @AppStorage("userEmail") var userEmail = "Unknown Email"
    @AppStorage("logStatus") var logStatus = false
    var body: some View {
        VStack {
            AsyncImage(url: userImage)
                .padding(.horizontal, 20)
            VStack(spacing: 20) {
                Text(userName)
                    .font(.title)
                    .fontWeight(.bold)
                Text(userEmail)
                Button(action: {
                    GIDSignIn.sharedInstance.signOut()
                    try? Auth.auth().signOut()
                    withAnimation {
                        logStatus = false
                    }
                }, label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(25)
                })
                .padding(.top, 80)
            }
            .padding()
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 80)
    }
}
