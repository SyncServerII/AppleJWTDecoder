
// Not directly part of this package -- I use it in testing, but going to share it publically in case it's useful to others.

import Foundation
// E.g., {"type":"email-disabled","sub":"001667.7f1e9b1f0d41426d8d8616e7d06be6f1.0433","event_time":1608693364100,"email":"ttckg8zg7s@privaterelay.appleid.com","is_private_email":"true"}
public struct AppleEvent: Codable {
    public enum AppleEventType: String, Codable {
        // User has decided to stop receiving emails on their email relay.
        case emailDisabled = "email-disabled"
        
        // User decided to opt back into receiving emails. This and `emailDisabled` only occur if the user is using the private email relay.
        case emailEnabled = "email-enabled"

        // User decided to stop using their Apple Id with your application. And should be treated as a sign-out by the user. E.g., when a user decides to disconnect your application from Settings. (From https://developer.apple.com/videos/play/wwdc2020/10173/)
        // Also considered a request from user to "delete their app account" (broader context: "Server to Server Notification Endpoint Sign in with Apple server to server notifications allow you to receive important updates about your users and their accounts. Notifications are sent for each app group when users change mail forwarding preferences, delete their app account, or permanently delete their Apple ID. Each group of apps can have one URL, which must be absolute and include the scheme, host, and path. TLS 1.2 or higher is required to receive notifications. Learn more.") To see these docs, go to: developer.apple.com > Account > Certificates, Identifiers & Profiles > Identifiers > Select your app identifier > Click 'Edit' next to 'Sign In with Apple' > Server to Server Notification Endpoint
        // "If you stop using your Apple ID with this app, you may be asked to create a new account the next time you use the app." and "Next time you use this app, you may be asked to create a new account." (https://appleid.apple.com/account/manage)
        //      This seems to give some latitude to how apps want to handle this.
        case consentRevoked = "consent-revoked"
        
        // User has asked Apple to delete their Apple Id. The user identifier will now no longer be valid.
        case accountDelete = "account-delete"
    }

    public let type: AppleEventType
    
    // The users id
    public let sub: String
    
    public let event_time: Date

    // nil in `consentRevoked` and `accountDelete`.
    public let email: String?
    public let is_private_email: Bool?
    
    enum RootKeys: String, CodingKey {
        case type
        case sub
        case email
        case is_private_email
        case event_time
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        type = try container.decode(AppleEventType.self, forKey: .type)
        sub = try container.decode(String.self, forKey: .sub)
        event_time = try container.decode(Date.self, forKey: .event_time)
        
        do {
            email = try container.decode(String.self, forKey: .email)
        } catch let error {
            guard let decodingError = error as? DecodingError else {
                throw error
            }
            
            if case .keyNotFound = decodingError {
                // It's OK if we don't have this field.
                email = nil
            }
            else {
                throw error
            }
        }
        
        do {
            let isPrivate = try container.decode(String.self, forKey: .is_private_email)
            is_private_email = isPrivate == "true" ? true : false
        } catch let error {
            guard let decodingError = error as? DecodingError else {
                throw error
            }
            
            if case .keyNotFound = decodingError {
                // It's OK if we don't have this field.
                is_private_email = nil
            }
            else {
                throw error
            }
        }
    }
}

// A difference from the WWDC Video: The `events` field is not an array. Just a single value.
/*
TestClaims(
iss: "https://appleid.apple.com",
aud: "biz.SpasticMuffin.SharedImages",
iat: Optional(2020-12-23 03:16:23 +0000),
jti: Optional("CTCXpmYl2zKvjcND1Z5x1w"),
events: Optional("{
    \"type\":\"email-disabled\",
    \"sub\":\"001667.7f1e9b1f0d41426d8d8616e7d06be6f1.0433\",
    \"event_time\":1608693364100,
    \"email\":\"ttckg8zg7s@privaterelay.appleid.com\",
    \"is_private_email\":\"true\"}"))
 */

public struct AppleSignInClaims: AppleClaims {
    enum ClaimsError: Error {
        case couldNotGetData
    }
    
    public let iss: String
    public let aud: String
    public let iat: Date?
    public let jti: String?
    public let events:AppleEvent?

    enum RootKeys: String, CodingKey {
        case iss
        case aud
        case iat
        case jti
        case events
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        iss = try container.decode(String.self, forKey: .iss)
        aud = try container.decode(String.self, forKey: .aud)
        iat = try container.decode(Date.self, forKey: .iat)
        jti = try container.decode(String.self, forKey: .jti)
        
        // Not sure why I have to do this work-around. But if I do the following, it fails with: failedDecoding(Swift.DecodingError.typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [RootKeys(stringValue: "events", intValue: nil)], debugDescription: "Expected to decode Dictionary<String, Any> but found a string/data instead.", underlyingError: nil)))
        // let events = try container.decode(AppleEvent.self, forKey: .events)
        
        let eventsString = try container.decode(String.self, forKey: .events)
        
        guard let eventData = eventsString.data(using: .utf8) else {
            throw ClaimsError.couldNotGetData
        }
        
        events = try JSONDecoder().decode(AppleEvent.self, from: eventData)
    }

    public func validateClaims() -> Bool {
        return true
    }
}
