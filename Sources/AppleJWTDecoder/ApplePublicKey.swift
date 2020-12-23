
import Foundation
import SwiftJWT
import HeliumLogger
import LoggerAPI
import SwiftJWKtoPEM

/// This is a JSON Web Key and must be converted to a PEM (a public certificate) before you can decode
/// a JWT. See also https://blog.curtisherbert.com/so-theyve-signed-in-with-apple-now-what/
/// And see https://github.com/IBM-Swift/Swift-JWT/issues/77
public struct ApplePublicKey<C: AppleClaims>: Decodable {
    public struct Key: Decodable {
        public let kty: String?
        public let kid: String?
        public let use: String?
        public let alg: String?
        public let n: String?
        public let e: String?
    }
    
    public let keys: [Key]
}

extension ApplePublicKey {
    /// Converts the key with the given index.
    /// Returns nil if conversion could not be carried out.
    func toPEM(_ keyIndex: UInt) -> String? {
        guard keyIndex < keys.count else {
            return nil
        }
        
        let key = keys[Int(keyIndex)]
        return getPEM(from: key)
    }
    
    /// Uses the key with the kid given.
    func toPEM(kid: String) -> String? {
        var keyToUse: ApplePublicKey.Key?
        for key in keys {
            if key.kid == kid {
                keyToUse = key
            }
        }
        
        guard let key = keyToUse else {
            return nil
        }

        return getPEM(from: key)
    }
    
    func getPEM(from key: ApplePublicKey.Key) -> String? {
        guard let n = key.n, let e = key.e else {
            return nil
        }
        
        guard let rsaKey = try? RSAKey(n: n, e: e) else {
            return nil
        }

        let publicPem = try? rsaKey.getPublicKey()
        return publicPem
    }
}

// NOTE: I'm not sure if the keys array will ever have more than one key and if so how to choose between them.
// 6/26/20-- Indeed, I just ran into this. Two keys are returned, and the 0th one, which I was using before isn't working. See also https://developer.apple.com/forums/thread/129047 and https://github.com/Techofficer/node-apple-signin/issues/11
/* Example:
 {
   "keys": [
     {
       "kty": "RSA",
       "kid": "AIDOPK1",
       "use": "sig",
       "alg": "RS256",
       "n": "lxrwmuYSAsTfn-lUu4goZSXBD9ackM9OJuwUVQHmbZo6GW4Fu_auUdN5zI7Y1dEDfgt7m7QXWbHuMD01HLnD4eRtY-RNwCWdjNfEaY_esUPY3OVMrNDI15Ns13xspWS3q-13kdGv9jHI28P87RvMpjz_JCpQ5IM44oSyRnYtVJO-320SB8E2Bw92pmrenbp67KRUzTEVfGU4-obP5RZ09OxvCr1io4KJvEOjDJuuoClF66AT72WymtoMdwzUmhINjR0XSqK6H0MdWsjw7ysyd_JhmqX5CAaT9Pgi0J8lU_pcl215oANqjy7Ob-VMhug9eGyxAWVfu_1u6QJKePlE-w",
       "e": "AQAB"
     }
   ]
 }
 */

extension ApplePublicKey {
    public enum TokenVerificationResult {
        case success(Claims)
        
        // Possible failures
        case failedPEMConversion
        case failedPEMConversionToData
        case failedVerification
        case failedDecoding(Error)
        case badIss(String)
        case badAud(String)
        case failedValidateClaims
    }
    
    func getVerifier(using kid: String) -> JWTVerifier?  {
        guard let publicKeyPEM = toPEM(kid: kid) else {
            return nil
        }
        
        guard let publicKeyData = publicKeyPEM.data(using: .utf8) else {
            return nil
        }
        
        // Example of usage:
        // https://ibm-swift.github.io/Swift-JWT/Structs/JWTVerifier.html
        return JWTVerifier.rs256(publicKey: publicKeyData)
    }
    
    /// clientId must be the developers Apple client_id as a String
    /// See https://forums.developer.apple.com/thread/117210
    /// https://developer.apple.com/documentation/signinwithapplejs/clientconfigi/3230948-clientid
    /// And better:
    /// https://developer.okta.com/blog/2019/06/04/what-the-heck-is-sign-in-with-apple
    public func verifyToken(_ token: String, clientId: String) -> TokenVerificationResult {
        // This is from https://developer.apple.com/documentation/signinwithapplerestapi/verifying_a_user
        
        // Verify the JWS E256 signature using the server’s public key
        //  *and* decode the claims.

        let jwtDecoder = JWTDecoder(keyIDToVerifier: getVerifier)

        let claims: C
        do {
            let jwt = try jwtDecoder.decode(JWT<C>.self, fromString: token)
            claims = jwt.claims
        } catch let error {
            return .failedDecoding(error)
        }

        // Verify that the iss field contains https://appleid.apple.com
        guard claims.iss == "https://appleid.apple.com" else {
            return .badIss(claims.iss)
        }

        // Verify that the aud field is the developer’s client_id
        guard claims.aud == clientId else {
            return .badAud(claims.aud)
        }

        if claims.validateClaims() {
            return .success(claims)
        }
        else {
            return .failedValidateClaims
        }
    }
}
