//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

struct AppleMusicSearchResponse: Decodable, Sendable {
    let results: AppleMusicSearchResult
}

public struct AppleMusicSearchResult: Decodable, Sendable {
    //public let activities: [ActivityResponse]
    public let albums: AppleMusicDataResponse<AppleMusicAlbum>?
    public let artists: AppleMusicDataResponse<AppleMusicArtist>?
    //public let curators: [CuratorResponse]
    public let playlists: AppleMusicDataResponse<AppleMusicPlaylist>?
    public let songs: AppleMusicDataResponse<AppleMusicSong>?
    //public let stations: [StationResponse]
}

struct AppleMusicSearchHintsResponse: Decodable, Sendable {
    let results: AppleMusicSearchHints
}

public struct AppleMusicSearchHints: Decodable, Sendable {
    public let terms: [String]
}

public struct AppleMusicDataResponse<T: Codable>: Codable {
    public let data: [T]
    public let next: String?
}

extension AppleMusicDataResponse: Sendable where T: Sendable {}
