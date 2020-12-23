
import SwiftJWT
import Foundation

public protocol AppleClaims: Claims {
    // The issuer-registered claim key, which has the value https://appleid.apple.com.
    var iss: String {get}
    
    // Your client_id in your Apple Developer account.
    var aud: String {get}
    
    // The time the token was issued.
    var iat: Date? {get}
    
    func validateClaims() -> Bool
}
