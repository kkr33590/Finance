import Foundation

struct DriveFile: Decodable {
    let id: String
    let name: String
}

enum DriveError: LocalizedError {
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .http(let code, let body):
            var message = "Google Drive error \(code)"
            if code == 403 {
                message += " — " + tr("Is the Google Drive API enabled in your Cloud project?",
                                      "Cloud project-ൽ Google Drive API Enable ചെയ്തിട്ടുണ്ടോ?")
            }
            let detail = body.prefix(160)
            return detail.isEmpty ? message : message + "\n" + detail
        }
    }
}

/// Drive-ലെ രഹസ്യ "appDataFolder" ഫോൾഡറുമായി സംസാരിക്കുന്ന REST helper
enum DriveAPI {
    private static let filesURL = "https://www.googleapis.com/drive/v3/files"
    private static let uploadURL = "https://www.googleapis.com/upload/drive/v3/files"

    private struct ListResponse: Decodable {
        let files: [DriveFile]
        let nextPageToken: String?
    }

    static func list(token: String) async throws -> [DriveFile] {
        var all: [DriveFile] = []
        var pageToken: String? = nil
        repeat {
            var comps = URLComponents(string: filesURL)!
            var items = [
                URLQueryItem(name: "spaces", value: "appDataFolder"),
                URLQueryItem(name: "fields", value: "nextPageToken,files(id,name)"),
                URLQueryItem(name: "pageSize", value: "1000")
            ]
            if let page = pageToken {
                items.append(URLQueryItem(name: "pageToken", value: page))
            }
            comps.queryItems = items
            let data = try await send(URLRequest(url: comps.url!), token: token)
            let response = try JSONDecoder().decode(ListResponse.self, from: data)
            all += response.files
            pageToken = response.nextPageToken
        } while pageToken != nil
        return all
    }

    static func download(token: String, id: String) async throws -> Data {
        let url = URL(string: "\(filesURL)/\(id)?alt=media")!
        return try await send(URLRequest(url: url), token: token)
    }

    /// existingID ഉണ്ടെങ്കിൽ അപ്ഡേറ്റ് ചെയ്യും, ഇല്ലെങ്കിൽ പുതിയ ഫയൽ ഉണ്ടാക്കും
    static func upload(token: String, name: String, data: Data,
                       mime: String, existingID: String?) async throws {
        let boundary = "fin-" + UUID().uuidString

        var meta: [String: Any] = ["name": name]
        if existingID == nil { meta["parents"] = ["appDataFolder"] }
        let metaData = try JSONSerialization.data(withJSONObject: meta)

        var body = Data()
        body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metaData)
        body.append("\r\n--\(boundary)\r\nContent-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--".data(using: .utf8)!)

        let urlString: String
        if let id = existingID {
            urlString = "\(uploadURL)/\(id)?uploadType=multipart"
        } else {
            urlString = "\(uploadURL)?uploadType=multipart"
        }
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = existingID == nil ? "POST" : "PATCH"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        _ = try await send(request, token: token)
    }

    private static func send(_ request: URLRequest, token: String) async throws -> Data {
        var req = request
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DriveError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}