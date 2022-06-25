//
//  ArtistViews.swift
//  AppleMusicKit
//
//  Created by Alexander Eichhorn on 25.06.22.
//

import Foundation

public protocol AppleMusicArtistView: Decodable {
    static var viewIdentifier: String { get }
    
    var next: String? { get }
}

/// A relationship view from this artist to other artists similar to this artist.
public struct AppleMusicArtistViewSimilarArtists: AppleMusicArtistView {
    
    public static let viewIdentifier = "similar-artists"
    
    public let next: String?
    public let attributes: Attributes?
    public let data: [AppleMusicArtist]
    
    public struct Attributes: Decodable {
        public let title: String
    }
}


/// A relationship view from this artist to a selection of albums from other artists on which this artist also appears.
public struct AppleMusicArtistViewAppearsOnAlbums: AppleMusicArtistView {
    
    static public let viewIdentifier = "appears-on-albums"
    
    public let next: String?
    public let data: [AppleMusicAlbum]
}


/// A relationship view from this artist to a collection of albums selected as featured for the artist.
public struct AppleMusicArtistViewFeaturedAlbums: AppleMusicArtistView {
    
    static public let viewIdentifier = "featured-albums"
    
    public let next: String?
    public let data: [AppleMusicAlbum]
}


/// A relationship view from this artist to relevant playlists associated with the artist.
public struct AppleMusicArtistViewFeaturedPlaylists: AppleMusicArtistView {
    
    static public let viewIdentifier = "featured-playlists"
    
    public let next: String?
    public let data: [AppleMusicPlaylist]
}


/// A relationship view from this artist to full-release albums associated with the artist.
public struct AppleMusicArtistViewFullAlbumsView {
    
    static public let viewIdentifier = "full-albums"
    
    public let next: String?
    public let data: [AppleMusicAlbum]
}


/// A relationship view from this artist to the latest release for the artist determined to still be recent by the Apple Music Catalog.
public struct AppleMusicArtistViewLatestRelease: AppleMusicArtistView {
    
    static public let viewIdentifier = "latest-release"
    
    public let next: String?
    public let data: [AppleMusicAlbum]
}


/// A relationship view from this artist to albums associated with the artist categorized as singles.
public struct AppleMusicArtistViewSingles: AppleMusicArtistView {
    
    static public let viewIdentifier = "singles"
    
    public let next: String?
    public let data: [AppleMusicAlbum]
}


/// A relationship view from this artist to songs associated with the artist based on popularity in the current storefront.
public struct AppleMusicArtistViewTopSongs: AppleMusicArtistView {
    
    static public let viewIdentifier = "top-songs"
    
    public let next: String?
    public let data: [AppleMusicSong]
}
