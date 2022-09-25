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
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    private func getDecodable<T: Decodable>(_ type: T.Type, path: String, query: [URLQueryItem]) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            getDecodable(type, path: path, query: query) { result in
                continuation.resume(with: result)
            }
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
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func search(_ query: String, limit: Int = 10, offset: Int = 0, types: [SearchType] = [.songs]) async throws -> AppleMusicSearchResult {
        try await withCheckedThrowingContinuation { continuation in
            search(query, limit: limit, offset: offset, types: types) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// - returns: array of strings meant as search suggestions for given query
    public func searchHints(_ query: String, limit: Int = 10, types: [SearchType]? = nil, completion: @escaping Completion<AppleMusicSearchHints>) {
        
        var query = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        if let types = types {
            let encodedTypes = types.map { $0.rawValue }.joined(separator: ",")
            query.append(URLQueryItem(name: "types", value: encodedTypes))
        }
        
        getDecodable(AppleMusicSearchHintsResponse.self, path: "/catalog/\(storefront.rawValue)/search/hints", query: query) { response in
            completion(response.map { $0.results })
        }
    }
    
    /// - returns: array of strings meant as search suggestions for given query
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func searchHints(_ query: String, limit: Int = 10, types: [SearchType]? = nil) async throws -> AppleMusicSearchHints {
        try await withCheckedThrowingContinuation { continuation in
            searchHints(query, limit: limit, types: types) { result in
                continuation.resume(with: result)
            }
        }
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
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getSong(withID id: String, includeTypes: [RelationshipType] = []) async throws -> AppleMusicSong {
        try await withCheckedThrowingContinuation { continuation in
            getSong(withID: id, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func getSong(withISRC isrc: String, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicSong>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicSong>.self, path: "/catalog/\(storefront.rawValue)/songs", query: [
            URLQueryItem(name: "include", value: encodedIncludeTypes),
            URLQueryItem(name: "filter[isrc]", value: isrc)
        ]) { result in
            completion(result.flatMap {
                guard let song = $0.data.first else { return .failure(RequestError.notFound) }
                return .success(song)
            })
        }
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getSong(withISRC isrc: String, includeTypes: [RelationshipType] = []) async throws -> AppleMusicSong {
        try await withCheckedThrowingContinuation { continuation in
            getSong(withISRC: isrc, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// load missing relationship data
    public func getSongDetails(for song: AppleMusicSong, types: [RelationshipType], completion: @escaping Completion<AppleMusicSong>) {
        getSong(withID: song.id, includeTypes: types, completion: completion)
    }
    
    /// load missing relationship data
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getSongDetails(for song: AppleMusicSong, types: [RelationshipType]) async throws -> AppleMusicSong {
        return try await getSong(withID: song.id, includeTypes: types)
    }
    
    /// - parameter ids: maximum 300 ids accepted
    public func getSongs(withIDs ids: [String], includeTypes: [RelationshipType] = [], completion: @escaping Completion<[AppleMusicSong]>) {
        assert(ids.count <= 300, "Only 300 ids accepted")
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicSong>.self, path: "/catalog/\(storefront.rawValue)/songs", query: [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.map { $0.data })
        }
    }
    
    /// - parameter ids: maximum 300 ids accepted
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getSongs(withIDs ids: [String], includeTypes: [RelationshipType] = []) async throws -> [AppleMusicSong] {
        return try await withCheckedThrowingContinuation { continuation in
            getSongs(withIDs: ids, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    
    /// - parameter ids: maximum 300 songs accepted
    public func getMultipleSongDetails(for songs: [AppleMusicSong], types: [RelationshipType], completion: @escaping Completion<[AppleMusicSong]>) {
        assert(songs.count <= 50, "Only 50 songs accepted")
        getSongs(withIDs: songs.map { $0.id }, includeTypes: types, completion: completion)
    }
    
    /// - parameter ids: maximum 300 songs accepted
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getMultipleSongDetails(for songs: [AppleMusicSong], types: [RelationshipType]) async throws -> [AppleMusicSong] {
        return try await getSongs(withIDs: songs.map { $0.id }, includeTypes: types)
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
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbum(withID id: String, includeTypes: [RelationshipType] = []) async throws -> AppleMusicAlbum {
        return try await withCheckedThrowingContinuation { continuation in
            getAlbum(withID: id, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// load missing relationship data
    public func getAlbumDetails(for album: AppleMusicAlbum, types: [RelationshipType], completion: @escaping Completion<AppleMusicAlbum>) {
        getAlbum(withID: album.id, includeTypes: types, completion: completion)
    }
    
    /// load missing relationship data
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbumDetails(for album: AppleMusicAlbum, types: [RelationshipType]) async throws -> AppleMusicAlbum {
        return try await getAlbum(withID: album.id, includeTypes: types)
    }
    
    /// - parameter ids: maximum 100 ids accepted
    public func getAlbums(withIDs ids: [String], includeTypes: [RelationshipType] = [], completion: @escaping Completion<[AppleMusicAlbum]>) {
        assert(ids.count <= 100, "Only 100 ids accepted")
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicAlbum>.self, path: "/catalog/\(storefront.rawValue)/albums", query: [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.map { $0.data })
        }
    }
    
    /// - parameter ids: maximum 100 ids accepted
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbums(withIDs ids: [String], includeTypes: [RelationshipType] = []) async throws -> [AppleMusicAlbum] {
        return try await withCheckedThrowingContinuation { continuation in
            getAlbums(withIDs: ids, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbum(withUPC upc: String, includeTypes: [RelationshipType] = []) async throws -> AppleMusicAlbum {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        let result = try await getDecodable(AppleMusicDataResponse<AppleMusicAlbum>.self, path: "/catalog/\(storefront.rawValue)/albums", query: [
            URLQueryItem(name: "include", value: encodedIncludeTypes),
            URLQueryItem(name: "filter[upc]", value: upc)
        ])
        
        guard let album = result.data.first else {
            throw RequestError.notFound
        }
        return album
    }
    
    public func getAlbumTracks(forID id: String, limit: Int = 50, offset: Int = 0, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicSong>.self, path: "/catalog/\(storefront.rawValue)/albums/\(id)/tracks", query: [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "include", value: "\(encodedIncludeTypes)")
        ], completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbumTracks(forID id: String, limit: Int = 50, offset: Int = 0, includeTypes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicSong> {
        return try await withCheckedThrowingContinuation { continuation in
            getAlbumTracks(forID: id, limit: limit, offset: offset, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func getAlbumTracks(for album: AppleMusicAlbum, limit: Int = 50, offset: Int = 0, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        getAlbumTracks(forID: album.id, limit: limit, offset: offset, includeTypes: includeTypes, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbumTracks(for album: AppleMusicAlbum, limit: Int = 50, offset: Int = 0, includeTypes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicSong> {
        try await getAlbumTracks(forID: album.id, limit: limit, offset: offset, includeTypes: includeTypes)
    }
    
    
    // MARK: - Artist
    
    /// - parameter ids: maximum 25 ids accepted
    public func getArtists(forIDs ids: [String], includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicArtist>>) {
        assert(ids.count <= 25, "Only 25 ids accepted")
        
        let encodedIncludes = includes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicArtist>.self, path: "/catalog/\(storefront.rawValue)/artists", query: [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "include", value: encodedIncludes)
        ], completion: completion)
    }
    
    /// - parameter ids: maximum 25 ids accepted
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getArtists(forIDs ids: [String], includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicArtist> {
        return try await withCheckedThrowingContinuation { continuation in
            getArtists(forIDs: ids, includes: includes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func getArtistRelationship<T: Decodable>(_ relationship: RelationshipType, forID id: String, includes: [RelationshipType] = [], limit: Int = 10, offset: Int = 0, completion: @escaping Completion<AppleMusicDataResponse<T>>) {
        
        let encodedIncludes = includes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<T>.self, path: "/catalog/\(storefront.rawValue)/artists/\(id)/\(relationship.rawValue)", query: [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "include", value: encodedIncludes)
        ], completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getArtistRelationship<T: Decodable>(_ relationship: RelationshipType, forID id: String, includes: [RelationshipType] = [], limit: Int = 10, offset: Int = 0) async throws -> AppleMusicDataResponse<T> {
        return try await withCheckedThrowingContinuation { continuation in
            getArtistRelationship(relationship, forID: id, includes: includes, limit: limit, offset: offset) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /*public func getArtistRelationship(_ relationship: RelationshipType, for artist: AppleMusicArtist, limit: Int = 10, completion: @escaping Completion<[AppleMusicArtist]>) {
        getArtistRelationship(relationship, forID: artist.id, limit: limit, completion: completion)
    }*/
    
    public func getSongs(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        getArtistRelationship(.songs, forID: artist.id, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getSongs(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicSong> {
        try await getArtistRelationship(.songs, forID: artist.id, includes: includes, limit: limit, offset: offset)
    }
    
    public func getAlbums(forArtistID identifier: String, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicAlbum>>) {
        getArtistRelationship(.albums, forID: identifier, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbums(forArtistID identifier: String, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicAlbum> {
        try await getArtistRelationship(.albums, forID: identifier, includes: includes, limit: limit, offset: offset)
    }
    
    public func getAlbums(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicAlbum>>) {
        getArtistRelationship(.albums, forID: artist.id, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getAlbums(for artist: AppleMusicArtist, limit: Int = 10, offset: Int = 0, includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicAlbum> {
        try await getArtistRelationship(.albums, forID: artist.id, includes: includes, limit: limit, offset: offset)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getArtistView<ArtistView: AppleMusicArtistView>(_ viewType: ArtistView.Type, forID id: String, limit: Int = 10) async throws -> ArtistView {
        try await getDecodable(ArtistView.self, path: "/catalog/\(storefront.rawValue)/artists/\(id)/view/\(viewType.viewIdentifier)", query: [
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getArtistView<ArtistView: AppleMusicArtistView>(_ viewType: ArtistView.Type, for artist: AppleMusicArtist, limit: Int = 10) async throws -> ArtistView {
        try await getArtistView(viewType, forID: artist.id, limit: limit)
    }
    
    
    // MARK: - Playlist
    
    
    public func getPlaylist(withID id: String, includeTypes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicPlaylist>) {
        
        let encodedIncludeTypes = includeTypes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<AppleMusicPlaylist>.self, path: "/catalog/\(storefront.rawValue)/playlists/\(id)", query: [
            URLQueryItem(name: "include", value: encodedIncludeTypes)
        ]) { result in
            completion(result.flatMap {
                if let playlist = $0.data.first {
                    return .success(playlist)
                }
                return .failure(RequestError.notFound)
            })
        }
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getPlaylist(withID id: String, includeTypes: [RelationshipType] = []) async throws -> AppleMusicPlaylist {
        return try await withCheckedThrowingContinuation { continuation in
            getPlaylist(withID: id, includeTypes: includeTypes) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func getPlaylistRelationship<T: Decodable>(_ relationship: RelationshipType, forID id: String, includes: [RelationshipType] = [], limit: Int = 10, offset: Int = 0, completion: @escaping Completion<AppleMusicDataResponse<T>>) {
        
        let encodedIncludes = includes.map { $0.rawValue }.joined(separator: ",")
        
        getDecodable(AppleMusicDataResponse<T>.self, path: "/catalog/\(storefront.rawValue)/playlists/\(id)/\(relationship.rawValue)", query: [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "include", value: encodedIncludes)
        ], completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getPlaylistRelationship<T: Decodable>(_ relationship: RelationshipType, forID id: String, includes: [RelationshipType] = [], limit: Int = 10, offset: Int = 0) async throws -> AppleMusicDataResponse<T> {
        return try await withCheckedThrowingContinuation { continuation in
            getPlaylistRelationship(relationship, forID: id, includes: includes, limit: limit, offset: offset) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func getPlaylistTracks(forID id: String, limit: Int = 100, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        getPlaylistRelationship(.tracks, forID: id, includes: includes, limit: limit, offset: offset, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getPlaylistTracks(forID id: String, limit: Int = 100, offset: Int = 0, includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicSong> {
        try await getPlaylistRelationship(.tracks, forID: id, includes: includes, limit: limit, offset: offset)
    }
    
    public func getPlaylistTracks(for playlist: AppleMusicPlaylist, limit: Int = 100, offset: Int = 0, includes: [RelationshipType] = [], completion: @escaping Completion<AppleMusicDataResponse<AppleMusicSong>>) {
        getPlaylistTracks(forID: playlist.id, limit: limit, offset: offset, includes: includes, completion: completion)
    }
    
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, macOS 10.15, *)
    public func getPlaylistTracks(for playlist: AppleMusicPlaylist, limit: Int = 100, offset: Int = 0, includes: [RelationshipType] = []) async throws -> AppleMusicDataResponse<AppleMusicSong> {
        try await getPlaylistTracks(forID: playlist.id, limit: limit, offset: offset, includes: includes)
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
        case tracks
        
        var type: Decodable.Type {
            switch self {
            case .songs: return AppleMusicSong.self
            case .albums: return AppleMusicAlbum.self
            case .artists: return AppleMusicArtist.self
            case .tracks: return AppleMusicSong.self
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
