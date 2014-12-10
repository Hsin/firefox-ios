/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import UIKit

private let BOOKMARK_CELL_IDENTIFIER = "BOOKMARK_CELL"
private let BOOKMARK_HEADER_IDENTIFIER = "BOOKMARK_HEADER"

// Lots of work needed on this.
public class BookmarkItem {
    var title: String
    var url: String

    var icon: UIImage {
        return createMockFavicon(UIImage(named: "leaf.png")!);
    }

    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

/**
 * Currently suitable for showing all bookmarks in a flat list.
 */
public protocol Bookmarks {
    var count: Int { get };
    func get(index: Int) -> BookmarkItem?;

    // These are often combined.
    func tableDataSource() -> protocol<UITableViewDataSource, UITableViewDelegate>;
}

private class StubBookmarksUITableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var bookmarks: Bookmarks;

    init(bookmarks: Bookmarks) {
        self.bookmarks = bookmarks;
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section != 0) {
            return 0;
        }

        return self.bookmarks.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(BOOKMARK_CELL_IDENTIFIER, forIndexPath: indexPath) as UITableViewCell;

        cell.textLabel?.textColor = UIColor.darkGrayColor();
        cell.indentationWidth = 20;
        cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13);

        if let bookmark = self.bookmarks.get(indexPath.row) {
            cell.textLabel?.text = bookmark.title;
            cell.imageView?.image = bookmark.icon;

            /*
            // TODO: We need an async image loader api here
            favicons.getForUrl(NSURL(string: bookmark.url)!, options: nil, callback: { (icon: Favicon) -> Void in
            if let img = icon.img {
            cell.imageView?.image = createMockFavicon(img);
            }
            });
            */
        } else {
            cell.textLabel?.text = NSLocalizedString("No bookmark", comment: "Used when a bookmark is unexpectedly not found.");
            cell.imageView?.image = nil
        }

        return cell;
    }
}

/**
 * A stub containing no bookmarks.
 */
public class StubBookmarks: Bookmarks {
    public var count: Int {
        return 0;
    }

    public func get(index: Int) -> BookmarkItem? {
        return nil;
    }

    public func tableDataSource() -> protocol<UITableViewDataSource, UITableViewDelegate> {
        return StubBookmarksUITableViewHandler(bookmarks: self);
    }
}

/**
 * A stub that handles an immutable array of bookmarks on creation.
 */
public class ArrayBookmarks: Bookmarks {
    let bookmarks: [BookmarkItem];

    init(items: [BookmarkItem]) {
        self.bookmarks = items;
    }

    public var count: Int {
        return self.bookmarks.count;
    }

    public func get(index: Int) -> BookmarkItem? {
        return self.bookmarks[index];
    }

    public func tableDataSource() -> protocol<UITableViewDataSource, UITableViewDelegate> {
        return StubBookmarksUITableViewHandler(bookmarks: self);
    }
}