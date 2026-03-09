import XCTest
@testable import CoreNetwork

final class CoreNetworkTests: XCTestCase {
    
    var client: NetworkClient!
    
    // Um Endpoint falso só para testes
    struct MockEndpoint: Endpoint {
        var baseURL: String = "https://api.test.com"
        var path: String = "/users"
        var method: HTTPMethod = .get
    }
    
    // Um modelo falso para decodificar
    struct MockUser: Decodable, Equatable, Sendable {
        let name: String
    }

    override func setUp() {
        super.setUp()
        
        // 1. Criamos uma configuração de sessão que usa o nosso interceptador (MockURLProtocol)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        
        // 2. Injetamos a sessão falsa no nosso Client
        client = NetworkClient(session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = nil
        super.tearDown()
    }

    func testRequest_WhenStatusCodeIs200_ShouldDecodeCorrectly() async throws {
        // Arrange (Preparação)
        let jsonString = """
        { "name": "Satoru Gojo" }
        """
        MockURLProtocol.mockData = jsonString.data(using: .utf8)
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com/users")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["x-custom-header": "test-value"]
        )
        
        // Act (Ação)
        let response = try await client.request(endpoint: MockEndpoint(), responseType: MockUser.self)
        
        // Assert (Verificação)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data.name, "Satoru Gojo")
        XCTAssertEqual(response.valueForHeader("x-custom-header"), "test-value")
    }
}
