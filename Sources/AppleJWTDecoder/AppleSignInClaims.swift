
// Not directly part of this package -- I use it in testing, but going to share it publically in case it's useful to others.

import Foundation
// E.g., {"type":"email-disabled","sub":"001667.7f1e9b1f0d41426d8d8616e7d06be6f1.0433","event_time":1608693364100,"email":"ttckg8zg7s@privaterelay.appleid.com","is_private_email":"true"}
public struct AppleEvent: Codable {
    public let type: String
    public let sub: String
    public let email: String
    public let is_private_email: Bool
    public let event_time: Date
    
    enum RootKeys: String, CodingKey {
        case type
        case sub
        case email
        case is_private_email
        case event_time
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        type = try container.decode(String.self, forKey: .type)
        sub = try container.decode(String.self, forKey: .sub)
        email = try container.decode(String.self, forKey: .email)
        let isPrivate = try container.decode(String.self, forKey: .is_private_email)
        is_private_email = isPrivate == "true" ? true : false
        event_time = try container.decode(Date.self, forKey: .event_time)
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
    enum TestClaimsError: Error {
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
            throw TestClaimsError.couldNotGetData
        }
        
        events = try JSONDecoder().decode(AppleEvent.self, from: eventData)
    }

    public func validateClaims() -> Bool {
        return true
    }
}
