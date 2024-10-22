//
//  Station.swift
//  
//
//  Created by Alexander Eichhorn on 08.06.20.
//

import Foundation

public struct AppleMusicStation: Codable, Sendable {
    public let attributes: Attributes?
    
    public struct Attributes: Codable, Sendable {
        public let artwork: AppleMusicArtwork
        public let durationInMillis: Double?
        public let isLive: Bool
        public let name: String
    }
}
