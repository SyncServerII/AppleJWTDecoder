
import Foundation
import KituraNet
import HeliumLogger
import LoggerAPI

public enum FailureResult: Swift.Error {
    case badResponse
    case statusCode(HTTPStatusCode)
    case failedGettingBodyData
    case failedDecodingPublicKey
}
    
extension ApplePublicKey {
    static public func httpFetch(completion: @escaping (Result<ApplePublicKey, FailureResult>)->()) {
        // Get Apple's public key to validate the token
        // https://developer.apple.com/documentation/signinwithapplerestapi/fetch_apple_s_public_key_for_verifying_token_signature

        var requestOptions: [ClientRequest.Options] = []
        requestOptions.append(.schema("https://"))
        requestOptions.append(.hostname("appleid.apple.com"))
        requestOptions.append(.method("GET"))
        requestOptions.append(.path("/auth/keys"))

        let req = HTTP.request(requestOptions) { response in
            guard let response = response else {
                completion(.failure(FailureResult.badResponse))
                return
            }

            guard response.statusCode == HTTPStatusCode.OK else {
                completion(.failure(FailureResult.statusCode(response.statusCode)))
                return
            }
            
            var body = Data()
            do {
                try response.readAllData(into: &body)
            } catch let error {
                Log.error("\(error)")
                completion(.failure(FailureResult.failedGettingBodyData))
                return
            }

            let applePublicKey:ApplePublicKey
            
            do {
                applePublicKey = try JSONDecoder().decode(ApplePublicKey.self, from: body)
            } catch let error {
                Log.error("Failed to decode public key: \(error)")
                completion(.failure(FailureResult.failedDecodingPublicKey))
                return
            }
            
            completion(.success(applePublicKey))
        }
        
        req.end()
    }
}
