//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicSong: Decodable {
    public let id: String
    public let attributes: Attributes?
    public let relationships: Relationships?
    
    
    public struct Attributes: Decodable {
        public let albumName: String
        public let artistName: String
        public let artwork: AppleMusicArtwork
        public let composerName: String?
        public let contentRating: AppleMusicContentRating?
        public let discNumber: Int
        public let durationInMillis: Double?
        public let editorialNotes: AppleMusicEditorialNotes?
        public let genreNames: [String]
        public let isrc: String
        public let name: String
        public let releaseDate: String?
        public let trackNumber: Int
        
        // classical music only
        public let movementCount: Int?
        public let movementName: String?
        public let movementNumber: Int?
        public let workName: String?
    }
    
    public struct Relationships: Decodable {
        public let albums: AppleMusicDataResponse<AppleMusicAlbum>?
        public let artists: AppleMusicDataResponse<AppleMusicArtist>
        public let genres: AppleMusicDataResponse<AppleMusicGenre>?
    }
}
