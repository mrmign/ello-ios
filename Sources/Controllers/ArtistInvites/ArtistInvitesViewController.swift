////
///  ArtistInvitesViewController.swift
//

class ArtistInvitesViewController: StreamableViewController {
    override func trackerName() -> String? { return "ArtistInvites" }
    override func trackerProps() -> [String: Any]? { return nil }
    override func trackerStreamInfo() -> (String, String?)? { return nil }

    private var _mockScreen: StreamableScreenProtocol?
    var screen: StreamableScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return _mockScreen ?? self.view as! ArtistInvitesScreen }
    }
    var generator: ArtistInvitesGenerator!

    typealias Usage = HomeViewController.Usage

    fileprivate let usage: Usage

    init(usage: Usage) {
        self.usage = usage
        super.init(nibName: nil, bundle: nil)

        title = InterfaceString.ArtistInvites.Title
        generator = ArtistInvitesGenerator(
            currentUser: currentUser,
            destination: self)
        streamViewController.streamKind = generator.streamKind
        streamViewController.reloadClosure = { [weak self] in self?.generator?.load(reload: true) }
        streamViewController.initialLoadClosure = { [weak self] in self?.loadArtistInvites() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didSetCurrentUser() {
        generator.currentUser = currentUser
        super.didSetCurrentUser()
    }

    override func loadView() {
        let screen = ArtistInvitesScreen(usage: usage)
        screen.delegate = self

        elloNavigationItem.leftBarButtonItem = UIBarButtonItem(image: InterfaceImage.burger.normalImage, style: .done, target: self, action: #selector(hamburgerButtonTapped))
        elloNavigationItem.titleView = UIView()
        screen.navigationItem = elloNavigationItem

        self.view = screen
        viewContainer = screen.streamContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    fileprivate func updateInsets() {
        updateInsets(navBar: screen.navigationBar)
    }

    override func showNavBars() {
        super.showNavBars()
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint)
        updateInsets()
    }

    override func hideNavBars() {
        super.hideNavBars()
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint)
        updateInsets()
    }
}

extension ArtistInvitesViewController: StreamDestination {

    var isPagingEnabled: Bool {
        get { return streamViewController.isPagingEnabled }
        set { streamViewController.isPagingEnabled = newValue }
    }

    func loadArtistInvites() {
        streamViewController.isPagingEnabled = false
        generator.load()
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping Block) {
        streamViewController.replacePlaceholder(type: type, items: items, completion: completion)
        streamViewController.doneLoading()
    }

    func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad(newItems: items)
    }

    func setPrimary(jsonable: JSONAble) {
    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }

    func primaryJSONAbleNotFound() {
        self.showGenericLoadFailure()
        self.streamViewController.doneLoading()
    }

}

extension ArtistInvitesViewController: ArtistInvitesScreenDelegate {
    func scrollToTop() {
        streamViewController.scrollToTop(animated: true)
    }
}
