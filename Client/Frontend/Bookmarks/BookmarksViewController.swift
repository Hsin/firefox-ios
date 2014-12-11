// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private let BOOKMARK_CELL_IDENTIFIER = "BOOKMARK_CELL"
private let BOOKMARK_HEADER_IDENTIFIER = "BOOKMARK_HEADER"

class BookmarksViewController: UITableViewController {
    var account: Account!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionFooterHeight = 0
        //tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BOOKMARK_CELL_IDENTIFIER)
        let nib = UINib(nibName: "TabsViewControllerHeader", bundle: nil);
        tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: BOOKMARK_HEADER_IDENTIFIER)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
    }
    

    func reloadData() {
        let onSuccess: () -> () = {
            dispatch_async(dispatch_get_main_queue()) {
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }

        let onFailure: (Any) -> () = {error in
        }

        account.bookmarks.reloadData(onSuccess, onFailure)
    }
    
    func refresh() {
        reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account.bookmarks.root.count
    }
    
    private let FAVICON_SIZE = 32;
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(BOOKMARK_CELL_IDENTIFIER, forIndexPath: indexPath) as UITableViewCell;

        let bookmark: BookmarkNode? = account.bookmarks.root.get(indexPath.row)
        
        cell.imageView?.image = bookmark?.icon
        cell.textLabel?.text = bookmark?.title
        cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        cell.textLabel?.textColor = UIColor.darkGrayColor()
        cell.indentationWidth = 20
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 42
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(BOOKMARK_HEADER_IDENTIFIER) as? UIView;
        
        if let label = view?.viewWithTag(1) as? UILabel {
            label.text = "Recent Bookmarks"
        }
        
        return view
    }
    
    //    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    //        let objects = UINib(nibName: "TabsViewControllerHeader", bundle: nil).instantiateWithOwner(nil, options: nil)
    //        if let view = objects[0] as? UIView {
    //            if let label = view.viewWithTag(1) as? UILabel {
    //                // TODO: More button
    //            }
    //        }
    //        return view
    //    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let bookmark = account.bookmarks.root.get(indexPath.row)

        switch (bookmark) {
        case let item as BookmarkItem:
            // Click it.
            UIApplication.sharedApplication().openURL(NSURL(string: item.url)!)
            break;

        case let folder as BookmarkFolder:
            // Descend into the folder.
            break;

        default:
            // Weird.
            break;        // Just here until there's another executable statement (compiler requires one).
        }
    }
}
