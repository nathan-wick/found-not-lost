//
//  PostView.swift
//  IFoundIt
//
//  Created by Nathan Wick on 2/24/22.
//

import SwiftUI
import Combine
import FirebaseFunctions

struct Group: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    init(id: UUID = UUID(), name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

struct PostView: View {
    @StateObject var userLocation = UserLocation.shared
    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (latitude: Double, longitude: Double) = (0, 0)
    @State var itemIsExpanded = false
    @State var selectedItemGroup = Group(name: "Select", icon: "questionmark")
    let itemGroups = [
        Group(name: "Phone", icon: "iphone"),
        Group(name: "Key", icon: "key"),
        Group(name: "Eyeglass", icon: "eyeglasses"),
        Group(name: "Apparel", icon: "snow"),
        Group(name: "Wallet", icon: "wallet.pass"),
        Group(name: "Bag", icon: "bag"),
        Group(name: "Tool", icon: "wrench.and.screwdriver"),
        Group(name: "Toy", icon: "gamecontroller"),
        Group(name: "Computer", icon: "laptopcomputer"),
        Group(name: "Headphone", icon: "headphones")
    ]
    @State var resultMessage = ""
    
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        Text("Type")
                            .fontWeight(.bold)
                        Image(systemName: selectedItemGroup.icon)
                    }
                    DisclosureGroup(selectedItemGroup.name, isExpanded: $itemIsExpanded) {
                        ScrollView {
                            VStack {
                                ForEach(0..<itemGroups.count) { i in
                                    HStack {
                                        Image(systemName: itemGroups[i].icon)
                                            .frame(minWidth: 30, alignment: .leading)
                                        Text(itemGroups[i].name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.all)
                                    }
                                    .onTapGesture {
                                        selectedItemGroup = itemGroups[i]
                                        withAnimation {
                                            itemIsExpanded.toggle()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                    }
                }
                Button(action: {
                    PostItem()
                }, label: {
                    Text("Post Item")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(25)
                })
                .listRowBackground(Color.clear)
                Text(resultMessage)
                    .listRowBackground(Color.clear)
            }
        }
        .onAppear {
            observeCoordinateUpdates()
            observeLocationAccessDenied()
            userLocation.requestLocationUpdates()
        }
    }
    
    func observeCoordinateUpdates() {
        userLocation.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.coordinates = (coordinates.latitude, coordinates.longitude)
            }
            .store(in: &tokens)
    }
    
    func observeLocationAccessDenied() {
        userLocation.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("TODO Alert the user that they denied location access")
            }
            .store(in: &tokens)
    }
    
    func PostItem() {
        if (resultMessage != "Loading. Please wait.") {
            resultMessage = "Loading. Please wait."
            if (selectedItemGroup.name != "Select" && selectedItemGroup.icon != "questionmark") {
                if (coordinates.latitude != 0 && coordinates.longitude != 0) {
                    Functions.functions().httpsCallable("postItem").call([
                        "name": selectedItemGroup.name,
                        "icon": selectedItemGroup.icon,
                        "latitude": coordinates.latitude,
                        "longitude": coordinates.longitude
                    ]) { result, error in
                        guard let newResultMessage = result?.data as? String else {
                            if let error = error {
                                print(error)
                            }
                            return
                        }
                        resultMessage = newResultMessage
                    }
                } else {
                    resultMessage = "Please share your location and try again."
                }
            } else {
                resultMessage = "Please select the item's type and try again."
            }
        }
    }
}
