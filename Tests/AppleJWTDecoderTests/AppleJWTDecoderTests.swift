import XCTest
@testable import AppleJWTDecoder
import Foundation
import LoggerAPI

final class AppleJWTDecoderTests: XCTestCase {
    let clientId = "biz.SpasticMuffin.SharedImages" // For me, it's my bundle id "biz.SpasticMuffin.SharedImages"
    let token = "eyJraWQiOiJlWGF1bm1MIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiYml6LlNwYXN0aWNNdWZmaW4uU2hhcmVkSW1hZ2VzIiwiZXhwIjoxNjA4ODU0MzYxLCJpYXQiOjE2MDg3Njc5NjEsImp0aSI6IkcyTmN2WlZEcEZ3U2RRRmJvd0NFcFEiLCJldmVudHMiOiJ7XCJ0eXBlXCI6XCJjb25zZW50LXJldm9rZWRcIixcInN1YlwiOlwiMDAxNjY3LjdmMWU5YjFmMGQ0MTQyNmQ4ZDg2MTZlN2QwNmJlNmYxLjA0MzNcIixcImV2ZW50X3RpbWVcIjoxNjA4NzY3OTQ0NjIyfSJ9.T9b7g8njJSSOb-rn09ucdlmjmJrNJ-9RV_4Dsbz-f1yQ6JtTYsl1p7jR5j1xchsZdWKjYrF_cWEcNUkT6wg0sZDnr1JwcJJ_3yGTd6G0uAOCYFxvMNvNwevQcgmMODJFeF204_jMXyPP_f7-mc542tClz_TD_mnkfVYikNIB6wgA3r_PPRVmYIPyma0p1uEiboYMC9L6yjRsJefX43S5bpdL0Jz64_aqp5Vn0aZyuFVv4z7hNKkjNjGC81uTo1mPF--YF7EnJHOT6uOoi-cTgeIzaHBhOhKhkw2uiptvSs70uJJJRqS3y1WxV6RognkYOSN9pxAjIFqRLH_gDQtAIQ"
    
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
