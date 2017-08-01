//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController {

    var post: Post?
    
// MARK: - Properties 
    
    var image: UIImage?
    
    @IBOutlet weak var captionTextField: UITextField!
    
// MARK: - Button Functions
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
    @IBAction func addPostButtonTapped(_ sender: Any) {
        if let image = image,
            let caption = captionTextField.text {
            
            PostController.shared.createPostWith(image: image, caption: caption) { (_) in
                self.dismiss(animated: true, completion: nil) }
        }
            
        else {
            let alertController = UIAlertController(title: "Oops! Something's wrong", message: "Please check your entry and try again", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedPhotoSegue" {
            let destinationVC = segue.destination as? PhotoSelectViewController
            destinationVC?.delegate = self
        }
    }
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
    func photoSelectViewControllerSelected(image: UIImage) {
        self.image = image
    }
}



