//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicArtist: Decodable {
    public let id: String
    public let attributes: Attributes?
    public let relationships: Relationships?
    
    
    public struct Attributes: Decodable {
        public let editorialNotes: AppleMusicEditorialNotes?
        public let genreNames: [String]
        public let name: String
    }
    
    public struct Relationships: Decodable {
        public let albums: AppleMusicDataResponse<AppleMusicAlbum>?
        public let genres: AppleMusicDataResponse<AppleMusicGenre>?
        public let station: AppleMusicDataResponse<AppleMusicStation>?
    }
}

extension AppleMusicArtist {
    
    /// returns nil if station realationship isn't loaded
    public var artwork: AppleMusicArtwork? {
        guard var stationArtwork = relationships?.station?.data.first?.attributes?.artwork else { return nil }
        let parts = stationArtwork.url.components(separatedBy: "{w}x{h}")
        guard parts.count == 2 else { return nil }
        stationArtwork.url = parts[0] + "{w}x{h}." + (parts[1].components(separatedBy: ".").last ?? "")
        return stationArtwork
    }
    
}
