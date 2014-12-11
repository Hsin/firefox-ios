/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import UIKit

@objc public protocol BookmarkNode {
    var id: String { get }
    var title: String { get }
    var icon: UIImage { get }
}

public class BookmarkItem: BookmarkNode {
    public let id: String
    public var url: String
    public var title: String

    public var icon: UIImage {
        return createMockFavicon(UIImage(named: "leaf.png")!)

        // TODO: We need an async image loader api here.
        // Also it's wrong to do async work with table rows!
        /*
        favicons.getForUrl(NSURL(string: item.url)!, options: nil, callback: { (icon: Favicon) -> Void in
            if let img = icon.img {
                cell.imageView?.image = createMockFavicon(img);
            }
        });
        */
    }

    init(id: String, title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}

@objc public protocol BookmarkFolder: BookmarkNode {
    var count: Int { get }
    func get(index: Int) -> BookmarkNode?
}

public class MemoryBookmarkFolder: BookmarkFolder {
    public let id: String
    public var title: String
    public var icon: UIImage {
        return createMockFavicon(UIImage(named: "bookmark_folder_closed.png")!)
    }

    public var children: [BookmarkNode] = []

    init(id: String, name: String) {
        self.id = id
        self.title = name
    }

    public var count: Int {
        return children.count
    }

    public func get(index: Int) -> BookmarkNode? {
        return children[index]
    }
}

public class BookmarksModel {
    // TODO: Move this to the authenticator when its available.
    var favicons: Favicons = BasicFavicons()

    var root: MemoryBookmarkFolder
    var queue: [BookmarkNode] = []

    init() {
        // TODO: make this database-backed.
        self.root = MemoryBookmarkFolder(id: "root", name: "Root")
        self.root.children.append(MemoryBookmarkFolder(id: "mobile", name: "Mobile Bookmarks"))
    }

    public func shareItem(item: ShareItem) {
        let title = item.title == nil ? "Untitled" : item.title!

        func exists(e: BookmarkNode) -> Bool {
            if let bookmark = e as? BookmarkItem {
                return bookmark.url == item.url;
            }
            return false;
        }

        // Don't create duplicates.
        if (!contains(queue, exists)) {
            queue.append(BookmarkItem(id: Bytes.generateGUID(), title: title, url: item.url))
        }
    }

    // TODO: async.
    public func reloadData() {

    }
}

/*
private let BOOKMARK_CELL_IDENTIFIER = "BOOKMARK_CELL"
private let BOOKMARK_HEADER_IDENTIFIER = "BOOKMARK_HEADER"
private class StubBookmarksUITableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var bookmarks: BookmarksModel

    init(bookmarks: BookmarksModel) {
        self.bookmarks = bookmarks
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section != 0) {
            return 0
        }

        return self.bookmarks.root.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(BOOKMARK_CELL_IDENTIFIER, forIndexPath: indexPath) as UITableViewCell

        cell.textLabel?.textColor = UIColor.darkGrayColor()
        cell.indentationWidth = 20
        cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)

        if let bookmark = self.bookmarks.root.get(indexPath.row) {
            cell.textLabel?.text = bookmark.title
            cell.imageView?.image = bookmark.icon

            /*
            // TODO: We need an async image loader api here
            favicons.getForUrl(NSURL(string: bookmark.url)!, options: nil, callback: { (icon: Favicon) -> Void in
            if let img = icon.img {
            cell.imageView?.image = createMockFavicon(img)
            }
            })
            */
        } else {
            cell.textLabel?.text = NSLocalizedString("No bookmark", comment: "Used when a bookmark is unexpectedly not found.")
            cell.imageView?.image = nil
        }

        return cell
    }
}
*/
