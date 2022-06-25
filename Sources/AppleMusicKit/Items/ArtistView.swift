//
//  ArtistView.swift
//  AppleMusicKit
//
//  Created by Alexander Eichhorn on 25.06.22.
//

import Foundation

public protocol AppleMusicArtistView: Decodable {
    static var viewIdentifier: String { get }
}

public struct AppleMusicArtistViewSimilarArtists: AppleMusicArtistView {
    
    public static var viewIdentifier = "similar-artists"
    
    public let next: String?
    public let attributes: Attributes?
    public let data: [AppleMusicArtist]
    
    public struct Attributes: Decodable {
        public let title: String
    }
}
