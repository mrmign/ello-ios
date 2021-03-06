////
///  StreamableViewController.swift
//

@objc
protocol PostTappedResponder: class {
    func postTapped(_ post: Post)
    func postTapped(_ post: Post, scrollToComment: ElloComment?)
    func postTapped(postId: String)
}

@objc
protocol UserTappedResponder: class {
    func userTapped(_ user: User)
    func userParamTapped(_ param: String, username: String?)
}

@objc
protocol CreatePostResponder: class {
    func createPost(text: String?, fromController: UIViewController)
    func createComment(_ postId: String, text: String?, fromController: UIViewController)
    func editComment(_ comment: ElloComment, fromController: UIViewController)
    func editPost(_ post: Post, fromController: UIViewController)
}

@objc
protocol InviteResponder: class {
    func onInviteFriends()
    func sendInvite(person: LocalPerson, isOnboarding: Bool, completion: @escaping Block)
}

class StreamableViewController: BaseElloViewController {
    @IBOutlet weak var viewContainer: UIView!
    fileprivate var showing = false
    let streamViewController = StreamViewController()

    override func didSetCurrentUser() {
        if isViewLoaded {
            streamViewController.currentUser = currentUser
        }
        super.didSetCurrentUser()
    }

    func setupStreamController() {
        streamViewController.currentUser = currentUser
        streamViewController.streamViewDelegate = self

        streamViewController.willMove(toParentViewController: self)
        let containerForStream = viewForStream()
        containerForStream.addSubview(streamViewController.view)
        streamViewController.view.frame = containerForStream.bounds
        streamViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addChildViewController(streamViewController)
        streamViewController.didMove(toParentViewController: self)
    }

    var scrollLogic: ElloScrollLogic!

    func viewForStream() -> UIView {
        return viewContainer
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.restrictRotation = true
        showing = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showing = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStreamController()
        scrollLogic = ElloScrollLogic(
            onShow: { [weak self] in self?.showNavBars() },
            onHide: { [weak self] in self?.hideNavBars() }
        )
    }

    func trackerStreamInfo() -> (String, String?)? {
        return nil
    }

    override func trackScreenAppeared() {
        super.trackScreenAppeared()

        guard let (streamKind, streamId) = trackerStreamInfo() else { return }
        let posts = streamViewController.dataSource.visibleCellItems.flatMap { streamCellItem in
            return streamCellItem.jsonable as? Post
        }
        PostService().sendPostViews(posts: posts, streamId: streamId, streamKind: streamKind, userId: currentUser?.id)

        let comments = streamViewController.dataSource.visibleCellItems.flatMap { streamCellItem -> ElloComment? in
            guard streamCellItem.type != .createComment else { return nil }
            return streamCellItem.jsonable as? ElloComment
        }
        if let post = posts.first, streamKind == "post", comments.count > 0 {
            PostService().sendPostViews(comments: comments, streamId: post.id, streamKind: "comment", userId: currentUser?.id)
        }
    }

    override func updateNavBars() {
        super.updateNavBars()
        scrollLogic.isShowing = navigationBarsVisible
    }

    func updateInsets(navBar: UIView?, navigationBarsVisible visible: Bool? = nil) {
        updateInsets(maxY: navBar?.frame.maxY ?? 0, navigationBarsVisible: visible)
    }

    func updateInsets(maxY: CGFloat, navigationBarsVisible visible: Bool? = nil) {
        let topInset = max(0, maxY)
        let bottomInset: CGFloat
        if visible ?? bottomBarController?.bottomBarVisible ?? false {
            bottomInset = bottomBarController?.bottomBarHeight ?? 0
        }
        else {
            bottomInset = 0
        }

        streamViewController.contentInset.top = topInset
        streamViewController.contentInset.bottom = bottomInset
    }

    func positionNavBar(_ navBar: UIView, visible: Bool, withConstraint navigationBarTopConstraint: NSLayoutConstraint? = nil, animated: Bool = true) {
        let upAmount: CGFloat
        if visible {
            upAmount = 0
        }
        else {
            upAmount = navBar.frame.size.height + 1
        }

        if let navigationBarTopConstraint = navigationBarTopConstraint {
            navigationBarTopConstraint.constant = -upAmount
        }

        animate(animated: animated) {
            navBar.frame.origin.y = -upAmount
        }

        if showing {
            postNotification(StatusBarNotifications.statusBarVisibility, value: visible)
        }
    }
}

extension StreamableViewController {
    @objc
    func hamburgerButtonTapped() {
        let responder: DrawerResponder? = findResponder()
        responder?.showDrawerViewController()
    }
}

// MARK: PostTappedResponder
extension StreamableViewController: PostTappedResponder {

    func postTapped(_ post: Post) {
        self.postTapped(postId: post.id, scrollToComment: nil)
    }

    func postTapped(_ post: Post, scrollToComment lastComment: ElloComment?) {
        self.postTapped(postId: post.id, scrollToComment: lastComment)
    }

    func postTapped(postId: String) {
        self.postTapped(postId: postId, scrollToComment: nil)
    }

    fileprivate func postTapped(postId: String, scrollToComment lastComment: ElloComment?) {
        let vc = PostDetailViewController(postParam: postId)
        vc.scrollToComment = lastComment
        vc.currentUser = currentUser
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UserTappedResponder
extension StreamableViewController: UserTappedResponder {

    func userTapped(_ user: User) {
        guard user.relationshipPriority != .block else { return }
        userParamTapped(user.id, username: user.username)
    }

    func userParamTapped(_ param: String, username: String?) {
        guard !DeepLinking.alreadyOnUserProfile(navVC: navigationController, userParam: param)
            else { return }

        let vc = ProfileViewController(userParam: param, username: username)
        vc.currentUser = currentUser
        self.navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func alreadyOnUserProfile(_ user: User) -> Bool {
        if let profileVC = self.navigationController?.topViewController as? ProfileViewController
        {
            let param = profileVC.userParam
            if param.hasPrefix("~") {
                let usernamePart = param.substring(from: param.index(after: param.startIndex))
                return user.username == usernamePart
            }
            else {
                return user.id == profileVC.userParam
            }
        }
        return false
    }
}

// MARK: CreatePostResponder
extension StreamableViewController: CreatePostResponder {
    func createPost(text: String?, fromController: UIViewController) {
        let vc = OmnibarViewController(defaultText: text)
        vc.currentUser = self.currentUser
        vc.onPostSuccess { _ in
            _ = self.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func createComment(_ postId: String, text: String?, fromController: UIViewController) {
        let vc = OmnibarViewController(parentPostId: postId, defaultText: text)
        vc.currentUser = self.currentUser
        vc.onCommentSuccess { _ in
            _ = self.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func editComment(_ comment: ElloComment, fromController: UIViewController) {
        if OmnibarViewController.canEditRegions(comment.content) {
            let vc = OmnibarViewController(editComment: comment)
            vc.currentUser = self.currentUser
            vc.onCommentSuccess { _ in
                _ = self.navigationController?.popViewController(animated: true)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let message = InterfaceString.Post.CannotEditComment
            let alertController = AlertViewController(message: message)
            let action = AlertAction(title: InterfaceString.ThatIsOK, style: .dark, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func editPost(_ post: Post, fromController: UIViewController) {
        if OmnibarViewController.canEditRegions(post.content) {
            let vc = OmnibarViewController(editPost: post)
            vc.currentUser = self.currentUser
            vc.onPostSuccess { _ in
                _ = self.navigationController?.popViewController(animated: true)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let message = InterfaceString.Post.CannotEditPost
            let alertController = AlertViewController(message: message)
            let action = AlertAction(title: InterfaceString.ThatIsOK, style: .dark, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: StreamViewDelegate
extension StreamableViewController: StreamViewDelegate {
    func streamViewCustomLoadFailed() -> Bool {
        return false
    }

    func streamViewStreamCellItems(jsonables: [JSONAble], defaultGenerator generator: StreamCellItemGenerator) -> [StreamCellItem]? {
        return nil
    }

    func streamWillPullToRefresh() {
    }

    func streamViewDidScroll(scrollView: UIScrollView) {
        scrollLogic.scrollViewDidScroll(scrollView)
    }

    func streamViewWillBeginDragging(scrollView: UIScrollView) {
        scrollLogic.scrollViewWillBeginDragging(scrollView)
    }

    func streamViewDidEndDragging(scrollView: UIScrollView, willDecelerate: Bool) {
        scrollLogic.scrollViewDidEndDragging(scrollView, willDecelerate: willDecelerate)
    }
}

extension StreamableViewController {

    func showGenericLoadFailure() {
        let message = InterfaceString.GenericError
        let alertController = AlertViewController(error: message) { _ in
            _ = self.navigationController?.popViewController(animated: true)
        }
        self.present(alertController, animated: true, completion: nil)
    }

}
