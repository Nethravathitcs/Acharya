//
//  ViewController.swift
//  LinckedIn
//
//  Created by Nethra on 06/05/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
        
        // Array to hold image URLs
        var imageUrls: [URL] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Configure collection view
            collectionView.dataSource = self
            collectionView.delegate = self
            
            // Fetch image URLs
            fetchImageUrls()

}
    
    func fetchImageUrls() {
            let urlString = "https://acharyaprashant.org/api/v2/content/misc/media-coverages?limit=100"
            
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let data = data, error == nil else {
                    print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                // Iterate through each dictionary in the array
                                for dict in jsonArray {
                                    // Access individual values using dictionary keys
                                    if let id = dict["id"] as? String,
                                       let title = dict["title"] as? String,
                                       let language = dict["language"] as? String,
                                       let thumbnail = dict["thumbnail"] as? [String: Any],
                                       let domain = thumbnail["domain"] as? String,
                                       let basePath = thumbnail["basePath"] as? String,
                                       let key = thumbnail["key"] as? String {
                                        // Construct image URL using the provided formula
                                        let imageUrlString = "\(domain)/\(basePath)/0/\(key)"
                                        // Now you can use imageUrlString to load the image asynchronously
                                        if let imageUrl = URL(string: imageUrlString) {
                                            self?.imageUrls.append(imageUrl)
                                        }
                                        print("ID: \(id), Title: \(title), Language: \(language), Image URL: \(imageUrlString)")
                                    }
                                    
                                }
                            
                        }
                    DispatchQueue.main.async {
                        self?.collectionView.reloadData()
                    }
                   /* var json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]{
                    if let thumbnails = json?["thumbnails"] as? [[String: Any]] {
                        for thumbnail in thumbnails {
                            if let domain = thumbnail["domain"] as? String,
                               let basePath = thumbnail["basePath"] as? String,
                               let key = thumbnail["key"] as? String {
                                let imageUrlString = "\(domain)/\(basePath)/0/\(key)"
                                if let imageUrl = URL(string: imageUrlString) {
                                    self?.imageUrls.append(imageUrl)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.collectionView.reloadData()
                        }
                    }
                    }*/
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let imageUrl = imageUrls[indexPath.item]
        cell.loadImage(from: imageUrl)
     //   cell.imageView.loadImage(from: imageUrl)
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3
        return CGSize(width: width, height: width)
    }
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

        func loadImage(from url: URL) {
            ImageLoader.shared.loadImage(from: url) { [weak self] image in
                if let image = image {
                    // Perform center-cropping
                    self?.imageView.contentMode = .scaleAspectFill
                    self?.imageView.clipsToBounds = true
                    self?.imageView.image = image
                } else {
                    // Assign a placeholder image if loading fails
                    self?.imageView.image = UIImage(named: "placeholder")
                }
            }
        }
}
class ImageCache {
    static let shared = ImageCache()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("ImageCache")

    private init() {
        createDiskCacheDirectoryIfNeeded()
    }

    private func createDiskCacheDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating disk cache directory: \(error.localizedDescription)")
        }
    }

    func cacheImage(_ image: UIImage, for url: URL) {
        let key = NSString(string: url.absoluteString)
        memoryCache.setObject(image, forKey: key)
        saveImageToDisk(image, forKey: key)
    }

    func image(for url: URL) -> UIImage? {
        let key = NSString(string: url.absoluteString)

        // Check memory cache
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }

        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(forKey: key) {
            // Cache in memory for future access
            memoryCache.setObject(diskCachedImage, forKey: key)
            return diskCachedImage
        }

        return nil
    }

    private func saveImageToDisk(_ image: UIImage, forKey key: NSString) {
        let url = diskCacheDirectory.appendingPathComponent(key.description)
        if let data = image.pngData() {
            do {
                try data.write(to: url)
            } catch {
                print("Error saving image to disk: \(error.localizedDescription)")
            }
        }
    }

    private func loadImageFromDisk(forKey key: NSString) -> UIImage? {
        let url = diskCacheDirectory.appendingPathComponent(key.description)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }
}

class ImageLoader {
    static let shared = ImageLoader()

    private init() {}

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            // Check if image exists in cache
            if let cachedImage = ImageCache.shared.image(for: url) {
                DispatchQueue.main.async {
                    completion(cachedImage)
                }
            } else {
                // Image not in cache, fetch from network
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    // Cache image
                    ImageCache.shared.cacheImage(image, for: url)
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
}

