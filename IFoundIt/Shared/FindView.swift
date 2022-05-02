//
//  FindView.swift
//  IFoundIt
//
//  Created by Nathan Wick on 2/24/22.
//

import SwiftUI
import Combine
import Firebase
import FirebaseFunctions
import MapKit

struct Item: Identifiable {
    let id: String
    let user: String
    let name: String
    let icon: String
    let latitude: Double
    let longitude: Double
}

class ItemsContainer: ObservableObject {
    @Published var items = [Item]()
    func getItems() {
        Firestore.firestore().collection("items").getDocuments() { snapshot, error in
            if error == nil {
                if let snapshot = snapshot {
                    self.items = snapshot.documents.map { itemDocument in
                        return Item(id: itemDocument.documentID,
                                    user: itemDocument["user"] as? String ?? "",
                                    name: itemDocument["name"] as? String ?? "",
                                    icon: itemDocument["icon"] as? String ?? "",
                                    latitude: itemDocument["latitude"] as? Double ?? 0,
                                    longitude: itemDocument["longitude"] as? Double ?? 0)
                    }
                }
            } else {
                // TODO Handle error
            }
        }
    }
}

struct FindView: View {
    @StateObject var userLocation = UserLocation.shared
    @StateObject var itemsContainer = ItemsContainer()
    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (latitude: Double, longitude: Double) = (39.103119, -84.512016)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.103119, longitude: -84.512016),
            latitudinalMeters: 1400,
            longitudinalMeters: 1400
    )
    @State var focusedItem = Item(id: "nil", user: "nil", name: "nil", icon: "questionmark", latitude: 0, longitude: 0)
    @State var describingItem = false
    @State var sendingMessage = false
    @State var sentMessage = false
    @State var itemDescription = ""
    @State var resultMessage = ""
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: itemsContainer.items) { item in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)) {
                    VStack(spacing: -5) {
                        Menu {
                            Button(action: {
                                focusedItem = item
                                withAnimation {
                                    sentMessage = false
                                    describingItem = true
                                    region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                                            latitudinalMeters: 100,
                                            longitudinalMeters: 100
                                    )
                                }
                            }, label: {
                                Text("Claim This " + item.name)
                            })
                        } label: {
                            Image(systemName: item.icon)
                                .frame(width: 40, height: 40, alignment: .center)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .foregroundColor(Color.blue)
                    }
                }
            }
            if (describingItem || sendingMessage || sentMessage) {
                VStack(alignment: .trailing) {
                    if (describingItem) {
                        Text("Please provide a description of the " + focusedItem.name + " with details that only you would know:")
                        TextEditor(text: $itemDescription)
                            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 100)
                            .foregroundColor(Color.blue)
                            .cornerRadius(25)
                        HStack {
                            Button(action: {
                                describingItem = false
                            }, label: {
                                Text("Cancel")
                            })
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.white)
                                .foregroundColor(Color.blue)
                                .cornerRadius(25)
                            Button(action: {
                                claimItem()
                            }, label: {
                                Text("Submit")
                            })
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.blue)
                                .foregroundColor(Color.white)
                                .cornerRadius(25)
                        }
                    }
                    if (sendingMessage) {
                        Text(resultMessage)
                    }
                    if (sentMessage) {
                        Text(resultMessage)
                        Button(action: {
                            sentMessage = false
                        }, label: {
                            Text("Okay")
                        })
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .cornerRadius(25)
                    }
                }
                .padding(.all)
            }
        }
        .onAppear {
            self.itemsContainer.getItems()
            observeCoordinateUpdates()
            observeLocationAccessDenied()
            userLocation.requestLocationUpdates()
            updateRegion()
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
    
    func updateRegion() {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude),
                latitudinalMeters: 1400,
                longitudinalMeters: 1400
        )
    }
    
    func claimItem() {
        if (!sendingMessage) {
            resultMessage = "Loading. Please wait."
            describingItem = false
            sendingMessage = true
            Functions.functions().httpsCallable("sendMessage").call([
                "toUser": focusedItem.user,
                "messageText": "Hi, I lost a " + focusedItem.name + " at the same location that you found a " + focusedItem.name + ". Here's a description of the " + focusedItem.name + " that I lost: " + itemDescription + ". Does this describe the " + focusedItem.name + " that you found?"
            ]) { result, error in
                guard let newResultMessage = result?.data as? String else {
                    if let error = error {
                        print(error)
                    }
                    return
                }
                resultMessage = newResultMessage
                sendingMessage = false
                sentMessage = true
            }
        }
    }
}
