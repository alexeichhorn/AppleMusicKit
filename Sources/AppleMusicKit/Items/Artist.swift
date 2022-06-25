//
//  Artist.swift
//  AppleMusicKit
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicArtist: Decodable {
    public let id: String
    public let attributes: Attributes?
    public let relationships: Relationships?
    
    
    public struct Attributes: Decodable {
        public let artwork: AppleMusicArtwork?
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
