/*
NathanWick.com
March, 2022
*/

const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

/*
Notes:
Firebase needs to be deployed from the FirebaseTools folder.

Database Structure (Nested):
users
    user
        image
        name
        email
items
    item
        timestamp
        user
        name
        icon
        latitude
        longitude
conversations
    conversation
        timestamp
        users
            user
        messages
            message
                timestamp
                sendingUser
                recievingUser
                messageText
*/

// Set a user in the database
async function createUser(userRef, context) {
    
    // Check that the user is authenticated
    if (context.auth.uid) {

        // Set the user in the database
        const newUser = await userRef.set({
            image: context.auth.token.picture,
            name: context.auth.token.name,
            email: context.auth.token.email
        }).catch(error => {

            // Return an error message
            functions.logger.log(error);
            return error.message;

        });

    } else {

        // Return an error message
        return "Failed to create the user because the user is not authenticated.";

    }
    
    // Return a success message
    return "Successfully created the user.";

}

// Post a lost item for other users to find
exports.postItem = functions.https.onCall(async (data, context) => {
    
    // Check that the user is authenticated
    if (context.auth.uid) {

        // Check that the user exists in the database
        const userRef = db.collection('users').doc(context.auth.uid);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {

            // Add the user to the database
            createUser(userRef, context);

        }

        // Check that the user has the required information
        if (data.name && data.icon && data.latitude && data.longitude) {
            const timestamp = admin.firestore.FieldValue.serverTimestamp();

            // Add the new item to the database
            const newItem = await db.collection('items').add({
                timestamp: timestamp,
                user: context.auth.uid,
                name: data.name,
                icon: data.icon,
                latitude: data.latitude,
                longitude: data.longitude
            }).catch(error => {
                
                // Return an error message
                functions.logger.log(error);
                return error.message;

            });

        } else {

            // Return an error message
            return "Failed to post the item. Please check that you have selected an item type and are sharing your current location. Then, try again.";

        }

    } else {

        // Return an error message
        return "Failed to post the item. Please check that you are signed in and try again.";

    }

    // Return a success message
    return "Successfully posted the item.";
    
});

// Send a message from one user to another user
exports.sendMessage = functions.https.onCall(async (data, context) => {

    // Check that the sending user is authenticated
    if (context.auth.uid) {

        // Check that the sending user exists in the database
        const sendingUserRef = db.collection('users').doc(context.auth.uid);
        const sendingUserDoc = await sendingUserRef.get();
        if (!sendingUserDoc.exists) {
            
            // Add the sending user to the database
            createUser(sendingUserRef, context);

        }

        // Check that the sending user has the required information
        if (data.toUser && data.messageText) {

            // Check that the to recieving user exists in the database
            const recievingUserRef = db.collection('users').doc(data.toUser);
            const recievingUserDoc = await recievingUserRef.get();
            if (!recievingUserDoc.exists) {
                
                // Return an error message
                return "The user that you are trying to send a message to does not exist.";

            }

            let conversationRef;
            const timestamp = admin.firestore.FieldValue.serverTimestamp();

            // Check if the sending user would like the message to be added to an existing conversation
            if (data.conversation) {

                // Find the existing conversation
                conversationRef = db.collection('conversations').doc(data.conversation);
                const conversationDoc = await conversationRef.get().catch(error => {
                    
                    // Return an error message
                    functions.logger.log(error);
                    return error.message;

                });

                // Update the existing conversation
                const updateConversation = await conversationRef.update({
                    timestamp: timestamp
                }).catch(error => {

                    // Return an error message
                    functions.logger.log(error);
                    return error.message;

                });

            } else {

                // Create a new conversation
                const newConversation = await db.collection('conversations').add({
                    timestamp: timestamp,
                    users: [context.auth.uid, data.toUser]
                }).then(async (newConversationRef) => {

                    conversationRef = newConversationRef;

                }).catch(error => {
                    
                    // Return an error message
                    functions.logger.log(error);
                    return error.message;

                });

            }

            // Add the message to the conversation
            const newMessage = await conversationRef.collection('messages').add({
                timestamp: timestamp,
                sendingUser: context.auth.uid,
                recievingUser: data.toUser,
                messageText: data.messageText
            }).catch(error => {
                
                // Return an error message
                functions.logger.log(error);
                return error.message;

            });

        } else {
            
            // Return an error message
            return "Failed to send the message. Please check that you are sending all of the required information and try again.";

        }

    } else {

        // Return an error message
        return "Failed to send the message. Please check that you are signed in and try again.";

    }

    // Return a success message
    return "Successfully sent the message.";

});