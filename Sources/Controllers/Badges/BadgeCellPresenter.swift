////
///  BadgeCellPresenter.swift
//

struct BadgeCellPresenter {

    static func configure(
        _ cell: UICollectionViewCell,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        indexPath: IndexPath,
        currentUser: User?)
    {
        guard
            let cell = cell as? BadgeCell,
            let badge = streamCellItem.jsonable as? Badge
        else { return }

        if badge.isFeatured,
            let categories = badge.categories
        {
            let title = ElloAttributedString.featuredIn(categories: categories, attrs: [
                ParagraphAlignmentAttributeName: NSTextAlignment.left.rawValue,
                NSFontAttributeName: UIFont.defaultFont(),
                NSForegroundColorAttributeName: UIColor.black,
                ])
            cell.attributedTitle = title
        }
        else {
            let title = badge.name
            cell.title = title
        }

        cell.image = badge.interfaceImage?.normalImage
        cell.url = badge.url
    }

}
