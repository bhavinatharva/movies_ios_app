//
//  IPTVLocalDatabase.swift
//  MoviesApp
//
//  Created by Antigravity on 18/05/26.
//

import Foundation
import CoreData

class IPTVLocalDatabase {
    static let shared = IPTVLocalDatabase()
    
    private let container: NSPersistentContainer
    
    private init() {
        let model = NSManagedObjectModel()
        
        // 1. ChannelEntity (IPTV Live channels)
        let channelEntity = NSEntityDescription()
        channelEntity.name = "ChannelEntity"
        channelEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let chName = NSAttributeDescription()
        chName.name = "name"
        chName.attributeType = .stringAttributeType
        chName.isOptional = false
        
        let chStreamUrl = NSAttributeDescription()
        chStreamUrl.name = "streamUrl"
        chStreamUrl.attributeType = .stringAttributeType
        chStreamUrl.isOptional = false
        
        let chLogoUrl = NSAttributeDescription()
        chLogoUrl.name = "logoUrl"
        chLogoUrl.attributeType = .stringAttributeType
        chLogoUrl.isOptional = true
        
        let chCategory = NSAttributeDescription()
        chCategory.name = "category"
        chCategory.attributeType = .stringAttributeType
        chCategory.isOptional = true
        
        let chEpgId = NSAttributeDescription()
        chEpgId.name = "epgId"
        chEpgId.attributeType = .stringAttributeType
        chEpgId.isOptional = true
        
        channelEntity.properties = [chName, chStreamUrl, chLogoUrl, chCategory, chEpgId]
        
        // 2. MediaEntity (UnifiedMediaItem for Movies/Series VOD)
        let mediaEntity = NSEntityDescription()
        mediaEntity.name = "MediaEntity"
        mediaEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let medId = NSAttributeDescription()
        medId.name = "id"
        medId.attributeType = .stringAttributeType
        medId.isOptional = false
        
        let medTitle = NSAttributeDescription()
        medTitle.name = "title"
        medTitle.attributeType = .stringAttributeType
        medTitle.isOptional = false
        
        let medOverview = NSAttributeDescription()
        medOverview.name = "overview"
        medOverview.attributeType = .stringAttributeType
        medOverview.isOptional = true
        
        let medPoster = NSAttributeDescription()
        medPoster.name = "posterPath"
        medPoster.attributeType = .stringAttributeType
        medPoster.isOptional = true
        
        let medBackdrop = NSAttributeDescription()
        medBackdrop.name = "backdropPath"
        medBackdrop.attributeType = .stringAttributeType
        medBackdrop.isOptional = true
        
        let medType = NSAttributeDescription()
        medType.name = "mediaType"
        medType.attributeType = .stringAttributeType
        medType.isOptional = false
        
        let medSource = NSAttributeDescription()
        medSource.name = "source"
        medSource.attributeType = .stringAttributeType
        medSource.isOptional = false
        
        let medReleaseDate = NSAttributeDescription()
        medReleaseDate.name = "releaseDate"
        medReleaseDate.attributeType = .stringAttributeType
        medReleaseDate.isOptional = true
        
        let medVote = NSAttributeDescription()
        medVote.name = "voteAverage"
        medVote.attributeType = .doubleAttributeType
        medVote.isOptional = true
        
        let medRuntime = NSAttributeDescription()
        medRuntime.name = "runtime"
        medRuntime.attributeType = .integer64AttributeType
        medRuntime.isOptional = true
        
        let medGenres = NSAttributeDescription()
        medGenres.name = "genres"
        medGenres.attributeType = .stringAttributeType
        medGenres.isOptional = true
        
        let medStreamUrl = NSAttributeDescription()
        medStreamUrl.name = "streamUrl"
        medStreamUrl.attributeType = .stringAttributeType
        medStreamUrl.isOptional = true
        
        let medEpgId = NSAttributeDescription()
        medEpgId.name = "epgId"
        medEpgId.attributeType = .stringAttributeType
        medEpgId.isOptional = true
        
        let medAdult = NSAttributeDescription()
        medAdult.name = "adult"
        medAdult.attributeType = .booleanAttributeType
        medAdult.isOptional = true
        
        mediaEntity.properties = [medId, medTitle, medOverview, medPoster, medBackdrop, medType, medSource, medReleaseDate, medVote, medRuntime, medGenres, medStreamUrl, medEpgId, medAdult]
        
        // 3. FavoritesEntity
        let favoritesEntity = NSEntityDescription()
        favoritesEntity.name = "FavoritesEntity"
        favoritesEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let favId = NSAttributeDescription()
        favId.name = "contentId"
        favId.attributeType = .stringAttributeType
        favId.isOptional = false
        
        let favType = NSAttributeDescription()
        favType.name = "type"
        favType.attributeType = .stringAttributeType
        favType.isOptional = false
        
        favoritesEntity.properties = [favId, favType]
        
        // 4. ProgressEntity (Continue Watching tracks)
        let progressEntity = NSEntityDescription()
        progressEntity.name = "ProgressEntity"
        progressEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let progId = NSAttributeDescription()
        progId.name = "contentId"
        progId.attributeType = .stringAttributeType
        progId.isOptional = false
        
        let progType = NSAttributeDescription()
        progType.name = "type"
        progType.attributeType = .stringAttributeType
        progType.isOptional = false
        
        let progPos = NSAttributeDescription()
        progPos.name = "lastPosition"
        progPos.attributeType = .doubleAttributeType
        progPos.isOptional = false
        
        let progDur = NSAttributeDescription()
        progDur.name = "duration"
        progDur.attributeType = .doubleAttributeType
        progDur.isOptional = false
        
        let progDate = NSAttributeDescription()
        progDate.name = "lastWatchedDate"
        progDate.attributeType = .dateAttributeType
        progDate.isOptional = false
        
        progressEntity.properties = [progId, progType, progPos, progDur, progDate]
        
        // 5. HistoryEntity (Recently watched rows)
        let historyEntity = NSEntityDescription()
        historyEntity.name = "HistoryEntity"
        historyEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let histId = NSAttributeDescription()
        histId.name = "contentId"
        histId.attributeType = .stringAttributeType
        histId.isOptional = false
        
        let histTimestamp = NSAttributeDescription()
        histTimestamp.name = "timestamp"
        histTimestamp.attributeType = .dateAttributeType
        histTimestamp.isOptional = false
        
        historyEntity.properties = [histId, histTimestamp]
        
        model.entities = [channelEntity, mediaEntity, favoritesEntity, progressEntity, historyEntity]
        
        container = NSPersistentContainer(name: "IPTVLocalData", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                print("⚠️ CoreData Failed initialization: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        let context = newBackgroundContext()
        context.performAndWait {
            let chReq = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelEntity")
            let medReq = NSFetchRequest<NSFetchRequestResult>(entityName: "MediaEntity")
            
            let chDel = NSBatchDeleteRequest(fetchRequest: chReq)
            let medDel = NSBatchDeleteRequest(fetchRequest: medReq)
            
            chDel.resultType = .resultTypeObjectIDs
            medDel.resultType = .resultTypeObjectIDs
            
            if let result1 = try? context.execute(chDel) as? NSBatchDeleteResult,
               let objectIDs1 = result1.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs1], into: [self.viewContext])
            }
            
            if let result2 = try? context.execute(medDel) as? NSBatchDeleteResult,
               let objectIDs2 = result2.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs2], into: [self.viewContext])
            }
            
            try? context.save()
        }
    }
    
    // MARK: - Channel CRUD
    
    func saveChannels(_ channels: [IPTVChannel], completion: @escaping () -> Void) {
        let context = newBackgroundContext()
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelEntity")
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(deleteReq) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [self.viewContext])
            }
            
            for (index, ch) in channels.enumerated() {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "ChannelEntity", into: context)
                obj.setValue(ch.name, forKey: "name")
                obj.setValue(ch.streamUrl.absoluteString, forKey: "streamUrl")
                obj.setValue(ch.logoUrl?.absoluteString, forKey: "logoUrl")
                obj.setValue(ch.category, forKey: "category")
                obj.setValue(ch.epgId, forKey: "epgId")
                
                if (index + 1) % 500 == 0 {
                    try? context.save()
                    context.reset()
                }
            }
            
            try? context.save()
            context.reset()
            completion()
        }
    }
    
    func fetchChannels() -> [IPTVChannel] {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChannelEntity")
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { obj in
                IPTVChannel(
                    name: obj.value(forKey: "name") as? String ?? "",
                    streamUrl: URL(string: obj.value(forKey: "streamUrl") as? String ?? "") ?? URL(string: "http://localhost")!,
                    logoUrl: (obj.value(forKey: "logoUrl") as? String).flatMap { URL(string: $0) },
                    category: obj.value(forKey: "category") as? String,
                    epgId: obj.value(forKey: "epgId") as? String
                )
            }
        } catch {
            return []
        }
    }
    
    // MARK: - VOD Media CRUD
    
    func saveMediaItems(_ items: [UnifiedMediaItem], completion: @escaping () -> Void) {
        let context = newBackgroundContext()
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MediaEntity")
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteReq.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(deleteReq) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [self.viewContext])
            }
            
            for (index, item) in items.enumerated() {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "MediaEntity", into: context)
                obj.setValue(item.id, forKey: "id")
                obj.setValue(item.title, forKey: "title")
                obj.setValue(item.overview, forKey: "overview")
                obj.setValue(item.posterPath, forKey: "posterPath")
                obj.setValue(item.backdropPath, forKey: "backdropPath")
                obj.setValue(item.mediaType.rawValue, forKey: "mediaType")
                obj.setValue(item.source.rawValue, forKey: "source")
                obj.setValue(item.releaseDate, forKey: "releaseDate")
                obj.setValue(item.voteAverage, forKey: "voteAverage")
                if let runtime = item.runtime {
                    obj.setValue(Int64(runtime), forKey: "runtime")
                }
                if let genres = item.genres, let genreData = try? JSONEncoder().encode(genres) {
                    obj.setValue(String(data: genreData, encoding: .utf8), forKey: "genres")
                }
                obj.setValue(item.streamUrl?.absoluteString, forKey: "streamUrl")
                obj.setValue(item.epgId, forKey: "epgId")
                obj.setValue(item.adult ?? false, forKey: "adult")
                
                if (index + 1) % 500 == 0 {
                    try? context.save()
                    context.reset()
                }
            }
            
            try? context.save()
            context.reset()
            completion()
        }
    }
    
    func fetchMediaItems(type: MediaType) -> [UnifiedMediaItem] {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MediaEntity")
        fetchRequest.predicate = NSPredicate(format: "mediaType == %@", type.rawValue)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { obj in
                let genresStr = obj.value(forKey: "genres") as? String
                let genres = genresStr?.data(using: .utf8).flatMap { try? JSONDecoder().decode([String].self, from: $0) }
                
                return UnifiedMediaItem(
                    id: obj.value(forKey: "id") as? String ?? "",
                    title: obj.value(forKey: "title") as? String ?? "",
                    overview: obj.value(forKey: "overview") as? String,
                    posterPath: obj.value(forKey: "posterPath") as? String,
                    backdropPath: obj.value(forKey: "backdropPath") as? String,
                    mediaType: MediaType(rawValue: obj.value(forKey: "mediaType") as? String ?? "") ?? .movie,
                    source: MediaSource(rawValue: obj.value(forKey: "source") as? String ?? "") ?? .iptv,
                    releaseDate: obj.value(forKey: "releaseDate") as? String,
                    voteAverage: obj.value(forKey: "voteAverage") as? Double,
                    runtime: (obj.value(forKey: "runtime") as? Int64).map { Int($0) },
                    genres: genres,
                    streamUrl: (obj.value(forKey: "streamUrl") as? String).flatMap { URL(string: $0) },
                    epgId: obj.value(forKey: "epgId") as? String,
                    adult: obj.value(forKey: "adult") as? Bool
                )
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Favorites persistence
    
    func fetchFavorites() -> Set<String> {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoritesEntity")
        do {
            let results = try context.fetch(fetchRequest)
            return Set(results.compactMap { $0.value(forKey: "contentId") as? String })
        } catch {
            return []
        }
    }
    
    func saveFavorite(id: String, type: String, isFav: Bool) {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoritesEntity")
        fetchRequest.predicate = NSPredicate(format: "contentId == %@", id)
        
        do {
            let existing = try context.fetch(fetchRequest)
            if isFav {
                if existing.isEmpty {
                    let obj = NSEntityDescription.insertNewObject(forEntityName: "FavoritesEntity", into: context)
                    obj.setValue(id, forKey: "contentId")
                    obj.setValue(type, forKey: "type")
                    try? context.save()
                }
            } else {
                for obj in existing {
                    context.delete(obj)
                }
                try? context.save()
            }
        } catch {}
    }
    
    // MARK: - Progress persistence
    
    func saveProgress(id: String, type: String, position: Double, duration: Double) {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ProgressEntity")
        fetchRequest.predicate = NSPredicate(format: "contentId == %@", id)
        
        do {
            let existing = try context.fetch(fetchRequest)
            let obj = existing.first ?? NSEntityDescription.insertNewObject(forEntityName: "ProgressEntity", into: context)
            obj.setValue(id, forKey: "contentId")
            obj.setValue(type, forKey: "type")
            obj.setValue(position, forKey: "lastPosition")
            obj.setValue(duration, forKey: "duration")
            obj.setValue(Date(), forKey: "lastWatchedDate")
            try? context.save()
        } catch {}
    }
    
    func fetchProgress() -> [String: Double] {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ProgressEntity")
        do {
            let results = try context.fetch(fetchRequest)
            var dict: [String: Double] = [:]
            for obj in results {
                if let id = obj.value(forKey: "contentId") as? String,
                   let pos = obj.value(forKey: "lastPosition") as? Double {
                    dict[id] = pos
                }
            }
            return dict
        } catch {
            return [:]
        }
    }
    
    // MARK: - History (Recently watched) CRUD
    
    func saveHistoryItem(id: String) {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HistoryEntity")
        fetchRequest.predicate = NSPredicate(format: "contentId == %@", id)
        
        do {
            let existing = try context.fetch(fetchRequest)
            let obj = existing.first ?? NSEntityDescription.insertNewObject(forEntityName: "HistoryEntity", into: context)
            obj.setValue(id, forKey: "contentId")
            obj.setValue(Date(), forKey: "timestamp")
            try? context.save()
            
            pruneHistory(limit: 50)
        } catch {}
    }
    
    private func pruneHistory(limit: Int) {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HistoryEntity")
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > limit {
                for i in limit..<results.count {
                    context.delete(results[i])
                }
                try? context.save()
            }
        } catch {}
    }
    
    func fetchHistoryIds() -> [String] {
        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HistoryEntity")
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { $0.value(forKey: "contentId") as? String }
        } catch {
            return []
        }
    }
    
    func clearHistory() {
        let context = newBackgroundContext()
        context.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryEntity")
            let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteReq.resultType = .resultTypeObjectIDs
            
            if let result = try? context.execute(deleteReq) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [self.viewContext])
            }
            
            try? context.save()
        }
    }
}
