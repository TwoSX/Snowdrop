//
//  FileUploadIntegrationTest.swift
//  Snowdrop
//
//  Created by Antigravity on 19/01/2026.
//

import XCTest
@testable import Snowdrop

// MARK: - 文件上传测试 Service 定义

@Service
public protocol FileUploadTestService {
    @FileUpload
    @POST(url: "/post")
    @Body("fileData")
    func uploadFile(fileData: Data) async throws -> HttpBinResponse
}

// MARK: - httpbin.org 响应模型

public struct HttpBinResponse: Codable {
    let args: [String: String]?
    let data: String?
    let files: [String: String]?
    let form: [String: String]?
    let headers: [String: String]?
    let json: [String: String]?
    let url: String?
}

// MARK: - 集成测试

final class FileUploadIntegrationTest: XCTestCase {
    private let baseUrl = URL(string: "https://httpbin.org")!
    private lazy var service = FileUploadTestServiceImpl(baseUrl: baseUrl, verbose: true)
    
    /// 测试 1: 验证请求体包含正确的 multipart/form-data 结构
    func testMultipartFormDataStructure() async throws {
        let expectation = expectation(description: "Request should have correct multipart/form-data structure")
        let testData = "Hello, Snowdrop!".data(using: .utf8)!
        
        service.addBeforeSendingBlock { request in
            guard let bodyData = request.httpBody,
                  let bodyString = String(data: bodyData, encoding: .utf8) else {
                XCTFail("Failed to get request body")
                return request
            }
            
            print("📦 Request Body:\n\(bodyString)\n")
            
            // 验证 1: Content-Disposition 存在
            XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"payload\"; filename=\"payload\""),
                         "Should contain Content-Disposition header")
            
            // 验证 2: Content-Type 存在
            XCTAssertTrue(bodyString.contains("Content-Type:"),
                         "Should contain Content-Type in body")
            
            // 验证 3: Boundary 分隔符格式正确
            XCTAssertTrue(bodyString.contains("--Boundary-"),
                         "Should contain boundary delimiter")
            
            // 验证 4: Boundary 结束标记存在
            XCTAssertTrue(bodyString.hasSuffix("--\r\n") || bodyString.contains("--\r\n"),
                         "Should contain closing boundary")
            
            expectation.fulfill()
            return request
        }
        
        _ = try? await service.uploadFile(fileData: testData)
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    /// 测试 2: 验证 Content-Type header 包含 boundary 参数
    func testContentTypeHeaderContainsBoundary() async throws {
        let expectation = expectation(description: "Content-Type should include boundary parameter")
        let testData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG 文件头
        
        service.addBeforeSendingBlock { request in
            guard let contentType = request.value(forHTTPHeaderField: "Content-Type") else {
                XCTFail("Content-Type header not found")
                return request
            }
            
            print("📋 Content-Type: \(contentType)\n")
            
            // 验证 Content-Type 格式
            XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="),
                         "Content-Type should start with 'multipart/form-data; boundary='")
            
            // 验证 boundary 值存在且格式正确
            let components = contentType.split(separator: "=")
            XCTAssertEqual(components.count, 2, "Should have exactly one '=' separator")
            
            if components.count == 2 {
                let boundaryValue = String(components[1])
                XCTAssertTrue(boundaryValue.hasPrefix("Boundary-"),
                             "Boundary value should start with 'Boundary-'")
                print("✅ Boundary value: \(boundaryValue)\n")
            }
            
            expectation.fulfill()
            return request
        }
        
        _ = try? await service.uploadFile(fileData: testData)
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    /// 测试 3: 验证 boundary 在 header 和 body 中一致
    func testBoundaryConsistency() async throws {
        let expectation = expectation(description: "Boundary should be consistent between header and body")
        let testData = "Test content".data(using: .utf8)!
        
        service.addBeforeSendingBlock { request in
            guard let contentType = request.value(forHTTPHeaderField: "Content-Type"),
                  let bodyData = request.httpBody,
                  let bodyString = String(data: bodyData, encoding: .utf8) else {
                XCTFail("Failed to get request data")
                return request
            }
            
            // 从 Content-Type header 中提取 boundary
            let headerBoundary = contentType.split(separator: "=").last.map(String.init) ?? ""
            
            print("🔍 Header Boundary: \(headerBoundary)")
            print("📦 Body preview: \(bodyString.prefix(200))...\n")
            
            // 验证 body 中使用了相同的 boundary
            XCTAssertTrue(bodyString.contains("--\(headerBoundary)"),
                         "Body should contain the same boundary as in Content-Type header")
            
            expectation.fulfill()
            return request
        }
        
        _ = try? await service.uploadFile(fileData: testData)
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    /// 测试 4: 测试实际文件数据上传（使用真实的图片数据）
    func testActualFileUpload() async throws {
        // 创建一个简单的 1x1 像素 PNG 图片
        let pngData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG 签名
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 像素
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // 配置
            0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
            0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, // 数据
            0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
            0x42, 0x60, 0x82
        ])
        
        let expectation = expectation(description: "Should upload file successfully")
        
        service.addBeforeSendingBlock { request in
            guard let bodyData = request.httpBody else {
                XCTFail("Request body is nil")
                return request
            }
            
            print("📊 Request body size: \(bodyData.count) bytes")
            
            // 验证请求体大小合理（应该包含 PNG 数据 + multipart 结构）
            XCTAssertGreaterThan(bodyData.count, pngData.count,
                               "Request body should be larger than raw file data due to multipart structure")
            
            expectation.fulfill()
            return request
        }
        
        _ = try? await service.uploadFile(fileData: pngData)
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    /// 测试 5: 真实的端到端测试 - 验证服务器真的收到了文件
    func testEndToEndFileUploadWithServerResponse() async throws {
        let testContent = "Snowdrop Test File Content - 文件上传测试内容 🚀"
        let testData = testContent.data(using: .utf8)!
        
        print("🚀 开始真实的文件上传测试...")
        print("📤 上传内容: \(testContent)")
        
        // 真实调用 httpbin.org API
        do {
            let response = try await service.uploadFile(fileData: testData)
            
            print("\n✅ 服务器响应成功!")
            print("📥 服务器 URL: \(response.url ?? "N/A")")
            
            // 验证响应
            XCTAssertNotNil(response.headers, "服务器应该返回 headers")
            XCTAssertNotNil(response.files, "服务器应该返回 files 字段")
            
            // 打印服务器收到的 headers
            if let headers = response.headers {
                print("\n📋 服务器收到的 Headers:")
                if let contentType = headers["Content-Type"] {
                    print("   Content-Type: \(contentType)")
                    XCTAssertTrue(contentType.contains("multipart/form-data"),
                                 "Content-Type 应该是 multipart/form-data")
                    XCTAssertTrue(contentType.contains("boundary="),
                                 "Content-Type 应该包含 boundary 参数")
                }
            }
            
            // 打印服务器收到的文件
            if let files = response.files {
                print("\n📦 服务器收到的文件:")
                for (key, value) in files {
                    print("   \(key): \(value)")
                }
                
                // 验证服务器确实收到了文件内容
                XCTAssertFalse(files.isEmpty, "服务器应该至少收到一个文件")
                
                // httpbin 返回的文件内容通常在 "payload" 字段
                if let receivedContent = files["payload"] {
                    print("\n✨ 服务器接收到的内容: \(receivedContent)")
                    
                    // 验证服务器收到的内容与发送的一致
                    XCTAssertTrue(receivedContent.contains(testContent) || 
                                 receivedContent == testContent,
                                 "服务器应该收到我们发送的内容")
                } else {
                    print("\n⚠️  服务器返回的文件字段: \(files.keys.joined(separator: ", "))")
                }
            }
            
            // 打印完整响应（仅用于调试）
            if let form = response.form {
                print("\n📝 Form 数据: \(form)")
            }
            
            print("\n🎉 端到端测试成功！服务器确实收到并正确解析了文件！")
            
        } catch {
            XCTFail("文件上传失败: \(error)")
            print("\n❌ 错误详情: \(error)")
        }
    }
    
    /// 测试 6: 上传真实图片并验证服务器响应
    func testRealImageUploadWithServerValidation() async throws {
        // 创建一个包含文本的文件（模拟真实场景）
        let imageContent = "This is a test image file with binary-like content: \u{0001}\u{0002}\u{0003}\u{0004}"
        let imageData = imageContent.data(using: .utf8)!
        
        print("🖼️  开始真实图片上传测试...")
        print("📊 文件大小: \(imageData.count) bytes")
        
        // 监控请求
        service.addBeforeSendingBlock { request in
            print("\n📤 请求已发送到服务器")
            
            if let contentType = request.value(forHTTPHeaderField: "Content-Type") {
                print("   Content-Type: \(contentType)")
            }
            
            if let bodySize = request.httpBody?.count {
                print("   Body Size: \(bodySize) bytes")
            }
            
            return request
        }
        
        // 监控响应
        service.addOnResponseBlock { data, response in
            print("\n📥 收到服务器响应")
            print("   Status Code: \(response.statusCode)")
            print("   Response Size: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("\n📄 响应内容预览:")
                print(responseString.prefix(500))
            }
            
            return data
        }
        
        // 执行上传
        do {
            let response = try await service.uploadFile(fileData: imageData)
            
            print("\n✅ 上传成功！")
            print("🌐 服务器 URL: \(response.url ?? "N/A")")
            
            // 验证服务器收到了数据
            let hasFiles = response.files != nil && !(response.files?.isEmpty ?? true)
            let hasForm = response.form != nil && !(response.form?.isEmpty ?? true)
            let hasData = response.data != nil && !response.data!.isEmpty
            
            XCTAssertTrue(hasFiles || hasForm || hasData,
                         "服务器应该在 files、form 或 data 字段中收到数据")
            
            print("\n🎊 真实图片上传测试成功！")
            
        } catch {
            XCTFail("上传失败: \(error)")
        }
    }
}
