//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicArtwork: Codable {
    public let height: Int
    public let width: Int
    public let bgColor: String?
    public let textColor1: String?
    public let textColor2: String?
    public let textColor3: String?
    public let textColor4: String?
    internal(set) public var url: String
}


public struct AppleMusicEditorialNotes: Codable {
    
}

public struct AppleMusicDescriptionAttribute: Codable {
    public let short: String?
    public let standard: String
}

public enum AppleMusicContentRating: String, Codable {
    case clean
    case explicit
}

public enum AppleMusicTrackTypes: String, Codable {
    case musicVideos = "music-videos"
    case songs
}
