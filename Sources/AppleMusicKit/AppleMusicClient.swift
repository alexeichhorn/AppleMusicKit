//
//  AppleMusicClient.swift
//  
//
//  Created by Alexander Eichhorn on 02.05.20.
//

import Foundation

public class AppleMusicClient {
    
    public typealias TokenHandler = (@escaping (Result<(String, Int), Error>) -> Void) -> Void
    
    let tokenHandler: TokenHandler
    
    @Expirable(duration: 3600)
    var token: String?
    
    public var storefront = Storefront.ch
    
    private let baseURL = URL(string: "https://api.music.apple.com/v1")!
    
    public init(tokenHandler: @escaping TokenHandler) {
        self.tokenHandler = tokenHandler
    }
    
    enum RequestError: Error {
        case notFound
        case unknown
    }
    
    public typealias Completion<T> = (Result<T, Error>) -> Void
    
    private func authenticationHeader(for token: String) -> [String: String] {
        ["Authorization": "Bearer \(token)"]
    }
    
    private func authenticationHeader(_ completion: @escaping Completion<[String: String]>) {
        
        if let token = token {
            completion(.success(authenticationHeader(for: token)))
            return
        }
        
        tokenHandler { result in
            completion(result.map { token, expiresIn in
                self._token.set(token, duration: TimeInterval(expiresIn))
                return self.authenticationHeader(for: token)
            })
        }
    }
    
    private func url(forPath path: String, query: [URLQueryItem], includingStorefront: Bool = true) -> URL {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.path += path
        urlComponents.queryItems = query.filter({ $0.value != nil })
        
        return urlComponents.url!
    }
    
    private func get(path: String, query: [URLQueryItem], completion: @escaping Completion<Data>) {
        
        authenticationHeader { result in
            switch result {
            case .success(let header):
                let url = self.url(forPath: path, query: query)
                var request = URLRequest(url: url)
                request.allHTTPHeaderFields = header
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let data = data {
                        completion(.success(data))
                        return
                    }
                    
                    completion(.failure(RequestError.unknown))
                }.resume()
            
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getDecodable<T: Decodable>(_ type: T.Type, path: String, query: [URLQueryItem], completion: @escaping Completion<T>) {
        
        get(path: path, query: query) { result in
            completion(result.flatMap {
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: $0)
                    return .success(decoded)
                } catch let error {
                    return .failure(error)
                }
            })
        }
    }

    
    // MARK: - Search
    
    public func search(_ query: String, limit: Int = 10, offset: Int = 0, types: [SearchType] = [.songs], completion: @escaping Completion<AppleMusicSearchResult>) {
        
        let encodedTypes = types.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicSearchResponse.self, path: "/catalog/\(storefront.rawValue)/search", query: [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "types", value: encodedTypes)
        ], completion: { response in
            completion(response.map { $0.results })
        })
    }
    
    
    // MARK: - Song
    
    public func getSong(withID id: String, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicSong>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicSong>.self, path: "/catalog/\(storefront.rawValue)/songs/\(id)", query: [
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.flatMap {
                guard let song = $0.data.first else { return .failure(RequestError.notFound) }
                return .success(song)
            })
        }
    }
    
    /// load missing relationship data
    public func getSongDetails(for song: AppleMusicSong, types: [RelationshipType], completion: @escaping Completion<AppleMusicSong>) {
        getSong(withID: song.id, includeTypes: types, completion: completion)
    }
    
    /// - parameter ids: maximum 300 ids accepted
    public func getSongs(withIDs ids: [String], includeTypes: [RelationshipType] = [], completion: @escaping Completion<[AppleMusicSong]>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicSong>.self, path: "/catalog/\(storefront.rawValue)/songs", query: [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.map { $0.data })
        }
    }
    
    /// - parameter ids: maximum 300 songs accepted
    public func getMultipleSongDetails(for songs: [AppleMusicSong], types: [RelationshipType], completion: @escaping Completion<[AppleMusicSong]>) {
        getSongs(withIDs: songs.map { $0.id }, includeTypes: types, completion: completion)
    }
    
    
    // MARK: - Album
    
    public func getAlbum(withID id: String, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicAlbum>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicAlbum>.self, path: "/catalog/\(storefront.rawValue)/albums/\(id)", query: [
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.flatMap {
                if let album = $0.data.first {
                    return .success(album)
                }
                return .failure(RequestError.notFound)
            })
        }
    }
    
    /// load missing relationship data
    public func getAlbumDetails(for album: AppleMusicAlbum, types: [RelationshipType], completion: @escaping Completion<AppleMusicAlbum>) {
        getAlbum(withID: album.id, includeTypes: types, completion: completion)
    }
    
    
    // MARK: - Artist
    
    public func getArtists(forIDs ids: [String], includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicArtist>>) {
        
        let encodedIncludes = includes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicArtist>.self, path: "/catalog/\(storefront.rawValue)/artists", query: [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "include", value: encodedIncludes)
        ], completion: completion)
    }
    
    public func getArtistRelationship<T: Decodable>(_ relationship: RelationshipType, forID id: String, includes: [RelationshipType] = [], limit: Int = 10, offset: Int = 0, completion: @escaping Completion<AppleMusicDataResponse<T>>) {
        
        let encodedIncludes = includes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<T>.self, path: "/catalog/\(storefront.rawValue)/artists/\(id)/\(relationship.rawValue)", query: [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "include", value: encodedIncludes)
        ], completion: completion)
    }
    
    /*public func getArtistRelationship(_ relationship: RelationshipType, for artist: AppleMusicArtist, limit: Int = 10, completion: @escaping Completion<[AppleMusicArtist]>) {
        getArtistRelationship(relationship, forID: artist.id, limit: limit, completion: completion)
    }*/
    
    public func getSongs(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        getArtistRelationship(.songs, forID: artist.id, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    public func getAlbums(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicAlbum>>) {
        getArtistRelationship(.albums, forID: artist.id, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    
    // MARK: - Request Object
    
    public enum SearchType: String {
        case songs
        case albums
        case artists
        case playlists
    }
    
    public enum RelationshipType: String {
        case songs
        case albums
        case artists
        case station
        
        var type: Decodable.Type {
            switch self {
            case .songs: return AppleMusicSong.self
            case .albums: return AppleMusicAlbum.self
            case .artists: return AppleMusicArtist.self
            case .station: fatalError()
            }
        }
    }
}

extension AppleMusicClient {
    
    public enum Storefront: String {
        case ch
        case de
        case us
    }
    
}
