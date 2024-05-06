//
//  Thumbnail.swift
//  Thumbnail
//
//  Created by Nethra on 06/05/24.
//

import Foundation
// MARK: - ThumbnailElement
struct ThumbnailElement: Codable {
    let id, title: String
    let language: Language
    let thumbnail: ThumbnailClass
    let mediaType: Int
    let coverageURL: String
    let publishedAt, publishedBy: String
    let backupDetails: BackupDetails?
}

// MARK: - BackupDetails
struct BackupDetails: Codable {
    let pdfLink: String
    let screenshotURL: String
}

enum Language: String, Codable {
    case english = "english"
    case hindi = "hindi"
}

// MARK: - ThumbnailClass
struct ThumbnailClass: Codable {
    let id: String
    let version: Int
    let domain: String
    let basePath: String
    let key: Key
    let qualities: [Int]
    let aspectRatio: Int
}

enum Key: String, Codable {
    case imageJpg = "image.jpg"
}

typealias Thumbnail = [ThumbnailElement]

