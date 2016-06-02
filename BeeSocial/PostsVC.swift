//
//  PostsVC.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/19/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import FirebaseDatabase

class PostsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    private var ref:FIRDatabaseReference!
    private var refHandle:FIRDatabaseHandle?
    
    private var postData = [PostItem]()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        ref = FIRDatabase.database().reference()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        refHandle = ref.child(MessageFields.posts).observeEventType(.Value, withBlock: { (snapshot) in
            self.postData = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for item in snapshots {
                    if let postDict = item.value as? Dictionary<String, AnyObject> {
                        let id = item.key
                        let post = PostItem(postId: id, data: postDict)
                        self.postData.append(post)
                    }
                }
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        if let handle = refHandle {
            ref.removeObserverWithHandle(handle)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return postData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            cell.configureCell(withPost: postData[indexPath.row])
            return cell
        } else {
            return PostCell()
        }
    }
}
