//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {

    var post: Post?
    var comment: Comment?
    
    
    @IBAction func followButtonTapped(_ sender: Any) {
        
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (success, isSubscribed, error) in
            self.updateViews()
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        guard let photo = post?.photo,
            let comment = post?.comments.first
            else { return }
        
        let text = comment.text
        let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Add Comment", message: "Enter your comment below", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Stuff here"
        }
        
        let addCommentAction = UIAlertAction(title: "Comment", style: .default) { (addComment) in
            guard let commentText = alertController.textFields?.first?.text,
                let post = self.post else { return }
            
            PostController.shared.addComment(toPost: post, commentText: commentText)
        }
        alertController.addAction(addCommentAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
        tableView.reloadData()
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var followPostButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(postCommentsChanged(_:)), name: PostController.PostsCommentsChangedNotification, object: nil)
    }
    
    private func updateViews() {
        guard let post = post, isViewLoaded else { return }
        
        imageView.image = post.photo
        PostController.shared.checkSubscriptionToPostComments(forPost: post) { (subscription) in
            
            DispatchQueue.main.async {
                self.followPostButton.title = subscription ? "Unfollow Post" : "Follow Post"
                
            }
        }
        tableView.reloadData()
        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return PostController.shared.posts.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)

        guard let post = post else { return cell }
            let comment = post.comments[indexPath.row]
        
        cell.textLabel?.text = comment.text

        return cell
    }
    
    func postCommentsChanged(_ notification: Notification) {
        guard let notificationPost = notification.object as? Post,
            let post = post, notificationPost === post else { return }
        updateViews()
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
