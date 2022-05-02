//
//  MessageView.swift
//  IFoundIt
//
//  Created by Nathan Wick on 2/24/22.
//

import SwiftUI
import Firebase
import FirebaseFunctions
import simd
import CoreMIDI

struct Message: Identifiable {
    let id: String
    let sendingUser: String
    let recievingUser: String
    let messageText: String
}

struct Conversation: Identifiable {
    let id: String
    let image: String
    let name: String
    let users: [String]
    var messages: [Message]
}

class ConversationsContainer: ObservableObject {
    @Published var conversations = [Conversation]()
    func getConversations() {
        let conversationsRef = Firestore.firestore().collection("conversations")
        let conversationsQuery = conversationsRef.order(by: "timestamp").limit(to: 25)
        conversationsQuery.getDocuments() { conversationsSnapshot, error in
            if error == nil {
                if let conversationsSnapshot = conversationsSnapshot {
                    @AppStorage("userID") var userID = "Unknown ID"
                    self.conversations = [Conversation]()
                    for newConversationDocument in conversationsSnapshot.documents {
                        let newUsers = newConversationDocument["users"] as? [String] ?? [String]()
                        var image = ""
                        var name = ""
                        var newMessages = [Message]()
                        func getOtherUser(_ completion:@escaping () -> ()) {
                            for newUser in newUsers {
                                if (newUser != userID) {
                                    Firestore.firestore().collection("users").document(newUser).getDocument() { userSnapshot, error  in
                                        if let userSnapshot = userSnapshot {
                                            image = userSnapshot.data()?["image"] as? String ?? ""
                                            name = userSnapshot.data()?["name"] as? String ?? ""
                                            completion()
                                        } else {
                                            // TODO Handle Error
                                        }
                                    }
                                }
                            }
                        }
                        func getMessages(_ completion:@escaping () -> ()) {
                            let messagesQuery = conversationsRef.document(newConversationDocument.documentID).collection("messages").order(by: "timestamp", descending: false).limit(to: 25)
                            messagesQuery.getDocuments() { messagesSnapshot, error in
                                if error == nil {
                                    if let messagesSnapshot = messagesSnapshot {
                                        newMessages = messagesSnapshot.documents.map { newMessageDocument in
                                            return Message(id: newMessageDocument.documentID,
                                                           sendingUser: newMessageDocument["sendingUser"] as? String ?? "",
                                                           recievingUser: newMessageDocument["recievingUser"] as? String ?? "",
                                                           messageText: newMessageDocument["messageText"] as? String ?? "")
                                        }
                                        completion()
                                    }
                                } else {
                                    // TODO Handle Error
                                }
                            }
                        }
                        getOtherUser({
                            getMessages({
                                self.conversations.append(Conversation(id: newConversationDocument.documentID,
                                                        image: image,
                                                        name: name,
                                                        users: newUsers,
                                                        messages: newMessages))
                            })
                        })
                    }
                }
            } else {
                // TODO Handle Error
            }
        }
    }
}

struct MessageView: View {
    @AppStorage("userID") var userID = "Unknown ID"
    @StateObject var conversationsContainer = ConversationsContainer()
    @State var focusedConversationID = ""
    @State var focusedConversation = Conversation(id: "", image: "", name: "", users: [], messages: [])
    @State var focusedConversationOtherUser = ""
    @State var newMessageText = ""
    var body: some View {
        VStack {
            if (focusedConversationID != "") {
                HStack {
                    Button(action: {
                        focusedConversationID = ""
                        focusedConversation = Conversation(id: "", image: "", name: "", users: [], messages: [])
                        focusedConversationOtherUser = ""
                        newMessageText = ""
                    }, label: {
                        Image(systemName: "arrowshape.turn.up.backward")
                    })
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .foregroundColor(Color.blue)
                        .cornerRadius(25)
                    Text(focusedConversation.name)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                ScrollView {
                    ForEach(focusedConversation.messages, id: \.id) { message in
                        if (message.sendingUser == userID) {
                            HStack {
                                Text(message.messageText)
                                    .padding(.all)
                                    .background(Color.blue)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.all)
                        } else {
                            HStack {
                                Text(message.messageText)
                                    .padding(.all)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.all)
                        }
                    }
                }
                .background(Color(.systemGray6))
            } else {
                ScrollView {
                    ForEach(conversationsContainer.conversations, id: \.id) { conversation in
                        HStack {
                            VStack {
                                HStack {
                                    AsyncImage(url: URL(string: conversation.image))
                                        .padding(.horizontal, 20)
                                    VStack {
                                        Text(conversation.name)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.blue)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top)
                                        Text(conversation.messages[(conversation.messages.count - 1)].messageText)
                                            .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
                                    }
                                }
                                if (conversation.messages[(conversation.messages.count - 1)].recievingUser == userID) {
                                    Button(action: {
                                        focusedConversationID = conversation.id
                                        focusedConversation = conversation
                                        if (conversation.users[0] == userID) {
                                            focusedConversationOtherUser = conversation.users[1]
                                        } else {
                                            focusedConversationOtherUser = conversation.users[0]
                                        }
                                    }, label: {
                                        Text("Reply")
                                    })
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(Color.blue)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(25)
                                } else {
                                    Button(action: {
                                        focusedConversationID = conversation.id
                                        focusedConversation = conversation
                                        if (conversation.users[0] == userID) {
                                            focusedConversationOtherUser = conversation.users[1]
                                        } else {
                                            focusedConversationOtherUser = conversation.users[0]
                                        }
                                    }, label: {
                                        Text("View Conversation")
                                    })
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(Color.white)
                                        .foregroundColor(Color.blue)
                                        .cornerRadius(25)
                                }
                            }
                            .padding(.all)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                        .padding(.all)
                    }
                }
                .background(Color(.systemGray6))
            }
            if (focusedConversationID != "") {
                VStack(alignment: .trailing) {
                    HStack {
                        TextEditor(text: $newMessageText)
                            .frame(width: .infinity, height: 75)
                        Button(action: {
                            Functions.functions().httpsCallable("sendMessage").call([
                                "conversation": focusedConversation.id,
                                "toUser": focusedConversationOtherUser,
                                "messageText": newMessageText
                            ]) { result, error in
                                guard (result?.data as? String) != nil else {
                                    if let error = error {
                                        print(error)
                                    }
                                    return
                                }
                                focusedConversation.messages.append(Message(id: "new", sendingUser: userID, recievingUser: focusedConversationOtherUser, messageText: newMessageText))
                                newMessageText = ""
                            }
                        }, label: {
                            Image(systemName: "arrow.up")
                        })
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .cornerRadius(25)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.conversationsContainer.getConversations()
        }
    }
}
