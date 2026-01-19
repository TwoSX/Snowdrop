//
//  SnowdropCore+boundary.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public extension Snowdrop.Core {
    /// 生成随机 boundary 字符串，用于 multipart/form-data 请求
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /// 构建带有 boundary 的 multipart/form-data 请求体
    /// - Parameters:
    ///   - file: 要上传的文件数据
    ///   - payloadDescription: 负载描述信息
    ///   - boundary: boundary 分隔符字符串
    /// - Returns: 格式化后的 multipart/form-data 数据
    func dataWithBoundary(_ file: Encodable, payloadDescription: PayloadDescription, boundary: String) -> Data {
        var data = Data()
        let contentDisposition = "Content-Disposition: form-data; name=\"\(payloadDescription.name)\"; filename=\"\(payloadDescription.fileName)\"\r\n"
        
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let closingData = "\r\n--\(boundary)--\r\n".data(using: .utf8),
              let contentDispData = contentDisposition.data(using: .utf8),
              let contentTypeData = "Content-Type: \(payloadDescription.mimeType)\r\n\r\n".data(using: .utf8) else {
            return data
        }
        
        // 优先使用原始 Data 类型，避免不必要的 JSON 编码
        let fileData: Data
        if let rawData = file as? Data {
            fileData = rawData
        } else if let jsonData = try? file.toJsonData() {
            fileData = jsonData
        } else {
            return data
        }
        
        data.append(boundaryData)
        data.append(contentDispData)
        data.append(contentTypeData)
        data.append(fileData)
        data.append(closingData)
        
        return data
    }
}
