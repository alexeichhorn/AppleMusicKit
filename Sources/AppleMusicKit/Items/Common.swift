//
//  File.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public struct AppleMusicArtwork: Decodable {
    public let height: Int
    public let width: Int
    public let bgColor: String?
    public let textColor1: String?
    public let textColor2: String?
    public let textColor3: String?
    public let textColor4: String?
    internal(set) public var url: String
}


public struct AppleMusicEditorialNotes: Decodable {
    
}

public enum AppleMusicContentRating: String, Decodable {
    case clean
    case explicit
}
