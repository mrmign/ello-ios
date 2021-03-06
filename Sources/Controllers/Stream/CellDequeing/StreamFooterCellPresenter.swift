////
///  StreamFooterCellPresenter.swift
//

enum InteractionVisibility {
    case enabled
    case selectedAndEnabled
    case selectedAndDisabled
    case disabled
    case hidden

    var isVisible: Bool { return self != .hidden }
    var isEnabled: Bool { return self == .enabled || self == .selectedAndEnabled }
    var isSelected: Bool { return self == .selectedAndDisabled || self == .selectedAndEnabled }
}


struct StreamFooterCellPresenter {

    static func configure(
        _ cell: UICollectionViewCell,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        indexPath: IndexPath,
        currentUser: User?)
    {
        guard
            let cell = cell as? StreamFooterCell,
            let post = streamCellItem.jsonable as? Post
        else { return }

        let isGridView = streamCellItem.isGridView(streamKind: streamKind)
        configureDisplayCounts(cell, post: post, isGridView: isGridView)
        configureToolBarItems(cell, post: post, currentUser: currentUser, isGridView: isGridView)
        configureCommentControl(cell, post: post, streamCellItem: streamCellItem, streamKind: streamKind, currentUser: currentUser)
    }

    fileprivate static func configureDisplayCounts(
        _ cell: StreamFooterCell,
        post: Post,
        isGridView: Bool)
    {
        let rounding = isGridView ? 0 : 1
        if cell.frame.width < 155 {
            cell.views = ""
            cell.reposts = ""
            cell.loves = ""
        }
        else {
            cell.views = post.viewsCount?.numberToHuman(rounding: rounding)
            cell.reposts = post.repostsCount?.numberToHuman(rounding: rounding)
            cell.loves = post.lovesCount?.numberToHuman(rounding: rounding)
        }
        cell.comments = post.commentsCount?.numberToHuman(rounding: rounding)
    }

    fileprivate static func configureToolBarItems(
        _ cell: StreamFooterCell,
        post: Post,
        currentUser: User?,
        isGridView: Bool)
    {
        let ownPost = (currentUser?.id == post.authorId || (post.repostAuthor?.id != nil && currentUser?.id == post.repostAuthor?.id))

        let repostingEnabled = post.author?.hasRepostingEnabled ?? true
        var repostVisibility: InteractionVisibility = .enabled
        if post.isReposted { repostVisibility = .disabled }
        else if !repostingEnabled { repostVisibility = .hidden }
        else if ownPost { repostVisibility = .disabled }

        let commentingEnabled = post.author?.hasCommentingEnabled ?? true
        let commentVisibility: InteractionVisibility = commentingEnabled ? .enabled : .hidden

        let sharingEnabled = post.author?.hasSharingEnabled ?? true
        let shareVisibility: InteractionVisibility = sharingEnabled ? .enabled : .hidden

        let lovingEnabled = post.author?.hasLovesEnabled ?? true
        var loveVisibility: InteractionVisibility = .enabled
        if post.isLoved { loveVisibility = .selectedAndEnabled }
        if !lovingEnabled { loveVisibility = .hidden }

        cell.updateToolbarItems(
            isGridView: isGridView,
            repostVisibility: repostVisibility,
            commentVisibility: commentVisibility,
            shareVisibility: shareVisibility,
            loveVisibility: loveVisibility
        )
    }

    fileprivate static func configureCommentControl(
        _ cell: StreamFooterCell,
        post: Post,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        currentUser: User?)
    {
        if streamKind.isDetail(post: post) && currentUser == nil {
            let count = post.commentsCount ?? 0
            let open = count > 0
            cell.commentsOpened = open
            cell.commentsControl.isSelected = open
        }
        else if streamKind.isDetail(post: post) {
            cell.commentsOpened = true
            cell.commentsControl.isSelected = true
        }
        else {
            let isLoading = streamCellItem.state == .loading
            let isExpanded = streamCellItem.state == .expanded

            if isLoading {
                // this should be set via a custom accessor or method,
                // me thinks.
                // `StreamFooterCell.state = streamCellItem.state` ??
                cell.commentsControl.animate()
                cell.commentsControl.isSelected = true
            }
            else {
                cell.commentsControl.finishAnimation()

                if isExpanded {
                    cell.commentsControl.isSelected = true
                    cell.commentsOpened = true
                }
                else {
                    cell.commentsControl.isSelected = false
                    cell.commentsOpened = false
                    streamCellItem.state = .collapsed
                }
            }
        }
    }
}
