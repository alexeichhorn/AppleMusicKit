//
//  Station.swift
//  
//
//  Created by Alexander Eichhorn on 08.06.20.
//

import Foundation

public struct AppleMusicStation: Decodable {
    public let attributes: Attributes?
    
    public struct Attributes: Decodable {
        public let artwork: AppleMusicArtwork
        public let durationInMillis: Double?
        public let isLive: Bool
        public let name: String
    }
}
