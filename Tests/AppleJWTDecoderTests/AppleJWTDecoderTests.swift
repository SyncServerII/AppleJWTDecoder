import XCTest
@testable import AppleJWTDecoder
import Foundation
import LoggerAPI

final class AppleJWTDecoderTests: XCTestCase {
    let clientId = "YOUR CLIENT ID" // For me, it's my bundle id "biz.SpasticMuffin.SharedImages"
    let token = "-- YOUR JWT TOKEN FROM APPLE --"
    
    func testVerify() {
        let exp = expectation(description: "exp")
        
        ApplePublicKey.httpFetch { (result: Swift.Result<ApplePublicKey<AppleSignInClaims>, FailureResult>) in
            let applePublicKey:ApplePublicKey<AppleSignInClaims>
            switch result {
            case .success(let key):
                applePublicKey = key
                
            case .failure(let failure):
                XCTFail("\(failure)")
                exp.fulfill()
                return
            }
            
            let verifyResult = applePublicKey.verifyToken(self.token, clientId: self.clientId)
            switch verifyResult {
            case .success(let claims):
                print("\(claims)")
            default:
                XCTFail("\(verifyResult)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
