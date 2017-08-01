//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchResultsUpdating {

    @IBAction func refreshControl(_ sender: UIRefreshControl) {
        
        fullSyncOperation() {
            self.refreshControl?.endRefreshing()
        }
        
    }
    
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullSyncOperation()

    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return PostController.shared.posts.count

    }

//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Collin", for: indexPath) else { return UITableViewCell() }
//
//        let posts = PostController.shared.posts
//        let post = posts[indexPath.row]
//        
//        
//        
//        return cell
//    }
    
    // MARK: - Navigation
    
    
    func fullSyncOperation(completion: @escaping(() -> Void) = { _ in }) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        PostController.shared.performFullSync {
        
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
            completion()
    }
}
    private func setUpSearchController() {
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsTableViewController")
        
        searchController = UISearchController(searchResultsController: resultsController)
        searchController?.searchResultsUpdater = self as? UISearchResultsUpdating
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = true
        tableView.tableHeaderView = searchController?.searchBar
        
        definesPresentationContext = true
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController,
            let searchTerm = searchController.searchBar.text?.lowercased() {
            
            let posts = PostController.shared.posts
            let filteredPosts = posts.filter { $0.matches(searchTerm: searchTerm) }.map { $0 as SearchableRecord }
            resultsViewController.resultsArray = filteredPosts
            resultsViewController.tableView.reloadData()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PostDetailView" {
            if let destinationVC = segue.destination as? PostDetailTableViewController,
                let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                let posts = PostController.shared.posts
                destinationVC.post = posts[selectedIndexPath.row]
            }
        }
        if segue.identifier == "toPostDetailFromSearch" {
            if let detailViewController = segue.destination as? PostDetailTableViewController,
                let sender = sender as? PostTableViewCell,
                let selectedIndexPath = (searchController?.searchResultsController as? SearchResultsTableViewController)?.tableView.indexPath(for: sender),
                let searchTerm = searchController?.searchBar.text?.lowercased() {
                
                let posts = PostController.shared.posts.filter({ $0.matches(searchTerm: searchTerm) } )
                let post = posts[selectedIndexPath.row]
                
                detailViewController.post = post
            }
        }
    }
    
}


















