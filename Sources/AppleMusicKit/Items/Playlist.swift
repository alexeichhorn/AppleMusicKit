//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 23.08.21.
//

import Foundation

public struct AppleMusicPlaylist: Codable {
    public let id: String
    public let attributes: Attributes?
    public let relationships: Relationships?
    
    
    public struct Attributes: Codable {
        public let artwork: AppleMusicArtwork?
        public let curatorName: String
        public let description: AppleMusicDescriptionAttribute?
        public let isChart: Bool
        public let lastModifiedDate: String?
        public let name: String
        public let playlistType: PlaylistType
        public let trackTypes: [AppleMusicTrackTypes]?
    }
    
    public struct Relationships: Codable {
        public let tracks: AppleMusicDataResponse<AppleMusicSong>? // can also be of type music video
    }
    
    public enum PlaylistType: String, Codable {
        
        /// A playlist created by an Apple Music curator.
        case editorial
        
        /// A playlist created by a non-Apple curator or brand.
        case external
        
        /// A personalized playlist for an Apple Music user.
        case personalMix = "personal-mix"
        
        /// A personalized Apple Music Replay playlist for an Apple Music user.
        case replay
        
        /// A playlist created and shared by an Apple Music user.
        case userShared = "user-shared"
    }
}
