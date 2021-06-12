//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicAlbum: Decodable {
    public let id: String
    public let attributes: Attributes?
    public let relationships: Relationships?
    
    
    public struct Attributes: Decodable {
        public let artistName: String
        public let artwork: AppleMusicArtwork?
        public let contentRating: AppleMusicContentRating?
        public let copyright: String?
        public let editorialNotes: AppleMusicEditorialNotes?
        public let genreNames: [String]
        public let isComplete: Bool
        public let isSingle: Bool
        public let name: String
        public let recordLabel: String?
        public let releaseDate: String
        public let trackCount: Int
        public let upc: String?
    }
    
    public struct Relationships: Decodable {
        public let artists: AppleMusicDataResponse<AppleMusicArtist>?
        public let genres: AppleMusicDataResponse<AppleMusicGenre>?
        public let tracks: AppleMusicDataResponse<AppleMusicSong>? // can also be of type music video
    }
}
