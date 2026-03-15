//
//  WinRecord.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//

import Foundation

struct WinRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let timeMs: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, timeMs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        if let intValue = try? container.decode(Int.self, forKey: .timeMs) {
            timeMs = intValue
        } else {
            timeMs = Int(try container.decode(String.self, forKey: .timeMs)) ?? 0
        }
    }
}

struct WinCreateRequest: Codable {
    let name: String
    let timeMs: Int
}
