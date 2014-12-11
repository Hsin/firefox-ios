/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import UIKit

/**
 * The immutable base interface for bookmarks and folders.
 */
@objc public protocol BookmarkNode {
    var id: String { get }
    var title: String { get }
    var icon: UIImage { get }
}

/**
 * An immutable item representing a bookmark.
 *
 * To modify this, issue changes against the model and wait for
 * change notifications.
 */
public class BookmarkItem: BookmarkNode {
    public let id: String
    public let url: String
    public let title: String

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

/**
 * A folder is an immutable abstraction over a named
 * thing that can return its child nodes by index.
 */
@objc public protocol BookmarkFolder: BookmarkNode {
    var count: Int { get }
    func get(index: Int) -> BookmarkNode?
}

/**
 * A folder that contains an array of children.
 */
public class MemoryBookmarkFolder: BookmarkFolder {
    public let id: String
    public let title: String
    let children: [BookmarkNode]

    public var icon: UIImage {
        return createMockFavicon(UIImage(named: "bookmark_folder_closed.png")!)
    }

    init(id: String, name: String, children: [BookmarkNode]) {
        self.id = id
        self.title = name
        self.children = children
    }

    public var count: Int {
        return children.count
    }

    public func get(index: Int) -> BookmarkNode? {
        return children[index]
    }
}

/**
 * A model is a snapshot of the bookmarks store, suitable for backing a table view.
 *
 * Navigation through the folder hierarchy produces a sequence of models.
 *
 * Changes to the backing store implicitly invalidates a subset of models.
 *
 * 'Refresh' means requesting a new model from the store.
 */
public class BookmarksModel {
    let modelFactory: BookmarksModelFactory
    let root: BookmarkFolder

    // TODO: Move this to the authenticator when its available.
    let favicons: Favicons = BasicFavicons()


    var queue: [BookmarkNode] = []

    init(modelFactory: BookmarksModelFactory, root: BookmarkFolder) {
        self.modelFactory = modelFactory
        self.root = root
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

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    public func selectFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForFolder(guid, success: success, failure: failure)
    }

    /**
     * Produce a new model rooted at the base of the hierarchy. Should never fail.
     */
    public func selectRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForRoot(success, failure: failure)
    }

    /**
     * Produce a new model rooted at the same place as this model. Can fail if
     * the folder has been deleted from the backing store.
     */
    public func reloadData(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForFolder(root, success: success, failure: failure)
    }
}

protocol BookmarksModelFactory {
    func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ())
    func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ())

    func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ())

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    var nullModel: BookmarksModel { get }
}

public class StubBookmarksModelFactory: BookmarksModelFactory {
    func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        // A smart implementation would go back to the backing store
        // to look up folder's GUID. We aren't smart.
        success(BookmarksModel(modelFactory: self, root: folder))
    }

    func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        success(BookmarksModel(modelFactory: self, root: MemoryBookmarkFolder(id: guid, name: "No name", children: [])))
    }

    func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        let m = MemoryBookmarkFolder(id: "mobile", name: "Mobile Bookmarks", children: [])
        let f = MemoryBookmarkFolder(id: "root", name: "Root", children: [m])
        success(BookmarksModel(modelFactory: self, root: f))
    }

    var nullModel: BookmarksModel {
        let f = MemoryBookmarkFolder(id: "root", name: "Root", children: [])
        return BookmarksModel(modelFactory: self, root: f)
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
