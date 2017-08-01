//
//  PostController.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//


import CloudKit
import UIKit


extension PostController {
    static var PostsChangedNotification = Notification.Name("PostsChangedNotification")
    
    static var PostsCommentsChangedNotification = Notification.Name("PostCommentsChangedNotification")
    
}

class PostController {
    
    static let shared = PostController()
    
    init() {
        
        self.cloudKitManager = CloudKitManager()
        
        performFullSync()
        
        subscribeToNewPosts { (success, error) in
            if error != nil {
                print("there was an error subscribing")
            }
            
            if success {
                print("Successfully subscribed")
            }
        }
        
    }
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                let nc = NotificationCenter.default
                nc.post(name: PostController.PostsChangedNotification, object: self)
            }
        }
    }
    
    var isSyncing: Bool = false
    
    let cloudKitManager: CloudKitManager
    
    func createPostWith(image: UIImage, caption: String, completion: ((Post) -> Void)?) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let post = Post(photoData: data)
        posts.append(post)
        let captionComment = addComment(toPost: post, commentText: caption)
        
        cloudKitManager.saveRecord(CKRecord(post)) { (record, error) in
            guard let record = record else {
                if let error = error {
                    NSLog("Error saving new post to CloudKit: \(error)")
                    return
                }
                completion?(post)
                return
            }
            post.cloudKitRecordID = record.recordID
            
            // Save comment record
            self.cloudKitManager.saveRecord(CKRecord(captionComment)) { (record, error) in
                if let error = error {
                    NSLog("Error saving new comment to CloudKit: \(error)")
                    return
                }
                captionComment.cloudKitRecordID = record?.recordID
                completion?(post)
            }
            
        }
    }
    
    private func recordsOf(type: String) -> [CloudKitSyncable] {
        switch type {
        case "Post":
            return posts.flatMap{ ($0 as CloudKitSyncable) }
        case "Comment":
            return posts.flatMap { ($0 as CloudKitSyncable) }
        default:
            return []
            
        }
    }
    
    func addComment(toPost post: Post, commentText: String, completion: @escaping ((Comment) -> Void) = {_ in }) -> Comment {
        
        let comment = Comment(post: post, text: commentText)
        post.comments.append(comment)
        
        cloudKitManager.saveRecord(CKRecord(comment)) { (record, error) in
            if let error = error {
                NSLog("Error saving comment to CloudKit: \(error)")
                return
            }
            comment.cloudKitRecordID = record?.recordID
            completion(comment)
        }
        
        DispatchQueue.main.async {
            let nc = NotificationCenter.default
            nc.post(name: PostController.PostsCommentsChangedNotification, object: post)
            
        }
        
        return comment
        
    }
    
    func syncedRecords(type: String) -> [CloudKitSyncable] {
        return recordsOf(type: type).filter { ($0.isSynced) }
    }
    
    func unsyncedRecords(type: String) -> [CloudKitSyncable] {
        return recordsOf(type:type).filter { (!$0.isSynced) }
    }
    
    func fetchNewRecords(type: String, completion: @escaping (() -> Void) = {_  in }) {
        
        var referencesToExclude = [CKReference]()
        var predicate = NSPredicate(format: "NOT(recordID in %@)", argumentArray: [referencesToExclude])
        referencesToExclude = self.syncedRecords(type: type).flatMap { $0.cloudKitReference }
        
        
        if referencesToExclude.isEmpty {
            predicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
            
            switch type {
            case Post.typeKey:
                if let post = Post(record: record) {
                    self.posts.append(post)
                }
            case Comment.typeKey:
                guard let postReference = record[Comment.postKey] as? CKReference,
                    let postIndex = self.posts.index(where: { $0.cloudKitRecordID == postReference.recordID }),
                    let comment = Comment(record: record) else { return }
                let post = self.posts[postIndex]
                post.comments.append(comment)
                comment.post = post
            default:
                return
            }
            
        }) { (records, error) in
            if let error = error {
                NSLog("Error fetching CloudKit records of type \(type): \(error)")
            }
            
            completion()
        }
    }
    
    func pushChangestoCloudKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        let unsavedPosts = unsyncedRecords(type: Post.typeKey) as? [Post] ?? []
        let unsavedComments = unsyncedRecords(type: Comment.typeKey) as? [Comment] ?? []
        var unsavedObjectsByRecord = [CKRecord: CloudKitSyncable]()
        for post in unsavedPosts {
            let record = CKRecord(post)
            unsavedObjectsByRecord[record] = post
        }
        for comment in unsavedComments {
            let record = CKRecord(comment)
            unsavedObjectsByRecord[record] = comment
        }
        
        let unsavedRecords = Array(unsavedObjectsByRecord.keys)
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            
            guard let record = record else { return }
            unsavedObjectsByRecord[record]?.cloudKitRecordID = record.recordID
            
        }) { (records, error) in
            
            let success = records != nil
            completion(success, error)
        }
    }
    
    func performFullSync(completion: @escaping (() -> Void) = { _ in }) {
        
        guard !isSyncing else {
            completion()
            return
        }
        
        isSyncing = true
        
        pushChangestoCloudKit { (success) in
            
            self.fetchNewRecords(type: Post.typeKey) {
                
                self.fetchNewRecords(type: Comment.typeKey) {
                    
                    self.isSyncing = false
                    
                    completion()
                }
            }
            
        }
    }
    
    func subscribeToNewPosts(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = {_,_ in }) {
        
        let predicate = NSPredicate(value: true)
        
        cloudKitManager.subscribe(Post.typeKey, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .firesOnRecordCreation) { (subscription, error) in
            
            if let error = error {
             print(error.localizedDescription)
            }
            
            let success = subscription != nil
            
            completion(success, error)
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post, alertBody: String?, completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = {_, _ in }) {
        
        guard let recordID = post.cloudKitRecordID else { fatalError("There was an error adding a subscription") }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        cloudKitManager.subscribe(Comment.typeKey, predicate: predicate, subscriptionID: recordID.recordName, contentAvailable: true, desiredKeys: [Comment.textKey, Comment.postKey], options: .firesOnRecordCreation) { (subscription, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            let success = subscription != nil
            
            completion(success, error)
        }
        
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _, _ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else { return }
        
        cloudKitManager.unsubscribe(subscriptionID) { (successful, error) in
            if let error = error {
                print("There was an error unsubscribing")
            }
            
            let success = successful != nil
            
            completion(success, error)
        }
    }
    
    func checkSubscriptionToPostComments(forPost post: Post, completion: @escaping ((_ subscribed: Bool) -> Void) = {_ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else {
            completion(false)
            return }
        
      cloudKitManager.fetchSubscription(subscriptionID) { (success, error) in
        if let error = error {
            print("There was an error checking the subscription")
        }
        
        let subscribed = success != nil
        
        completion(subscribed)
        }
        
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: @escaping ((_ success: Bool, _ isSubscribed: Bool, _ error: Error?) -> Void) = { _ , _, _ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else { completion(false, false, nil); return }
        
        cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
            
            if let error = error {
             print("There was an error toggling the subscription")
            }
            
            if subscription != nil {
                    self.removeSubscriptionTo(commentsForPost: post, completion: { (success, error) in
                        completion(true, false, error)
                })
            } else {
                self.addSubscriptionTo(commentsForPost: post, alertBody: "Someone commented on a subscription you follow!", completion: { (success, error) in
                    completion(true, true, error)
                })
        }
        
    }
}

}

