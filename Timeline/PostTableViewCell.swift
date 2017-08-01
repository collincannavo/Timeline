//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        postImage.image = post?.photo
        
    }
    
}
