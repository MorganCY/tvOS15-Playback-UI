//
//  PlayerViewController.swift
//  tvOS15PlaybackUI
//
//  Created by Zheng-Yuan Yu on 2022/2/28.
//

/*
Modified codes from Apple's sample code: https://developer.apple.com/documentation/avkit/working_with_overlays_and_parental_controls_in_tvos
 */

import UIKit
import AVKit

@available (tvOS 15, *)
class VideoPlaybackViewController: UIViewController, AVPlayerViewControllerDelegate {

    @objc dynamic var playerViewController: AVPlayerViewController?
    let chaptersTabViewController = ChaptersTabViewController(nibName: "ChaptersTab", bundle: nil)

    var player: AVQueuePlayer?
    @objc dynamic var pendingPlayerItem: AVPlayerItem?
    var playerItemStatusObservation: NSKeyValueObservation?
    var currentItemErrorObservation: NSKeyValueObservation?

    var isPlaybackActive = false
    var isFavorited = false

    let heartImage = UIImage(systemName: "heart")
    let heartFillImage = UIImage(systemName: "heart.fill")
    let loopImage = UIImage(systemName: "infinity")
    let gearImage = UIImage(systemName: "gearshape")

    // MARK: - Content Tab
    func loadAndPlay(url: URL, title: String, description: String, rating: String) {
        loadNewPlayerViewController()
        setupContentTabInfoButton()
        setupChaptersTab()
        setupTransportBarControls()
        addTimeObserverForSkipAciton()

        let playerItem = AVPlayerItem(url: url)
        // 定義 Info Tab 內容
        playerItem.externalMetadata = [
            metadataItemForMediaContentRating(rating),
            createMetadataItem(AVMetadataIdentifier.commonIdentifierTitle, value: title),
            createMetadataItem(.commonIdentifierDescription, value: description),
            createMetadataItem(.commonIdentifierArtwork, value: UIImage(named: "logo")?.pngData() as Any),
            createMetadataItem(.commonIdentifierArtist, value: "artist"),
            createMetadataItem(.quickTimeMetadataGenre, value: "輸入Genre")
        ]
        self.pendingPlayerItem = playerItem
        player?.replaceCurrentItem(with: playerItem)
        if playerViewController != nil && !isPlaybackActive {
            isPlaybackActive = true
        }
    }

    // 在 Info Tab 新增客製化按鈕
    func setupContentTabInfoButton() {
        let glasses = UIImage(systemName: "eyeglasses")
        let button1 = UIAction(title: "客製化按鈕", image: glasses) { action in
            print("按按鈕")
        }
        let button2 = UIAction(title: "客製化按鈕", image: glasses) { action in
            print("按按鈕")
        }
        playerViewController?.infoViewActions.append(button1)
        playerViewController?.infoViewActions.append(button2) // 這個按鈕不會出現在UI上
    }

    // 新增客製化 Content Tab - Chapters
    func setupChaptersTab() {
        chaptersTabViewController.title = "Chapters"
        playerViewController?.customInfoViewControllers = [
            chaptersTabViewController
        ]
    }

    // MARK: - Transport Bar
    // 新增客製化 Transport Bar Controls
    func setupTransportBarControls() {
        let stateImage = isFavorited ? heartFillImage : heartImage
        let favoriteAction = UIAction(title: "Favorites", image: stateImage) { [weak self] action in
            guard let self = self else { return }
            self.isFavorited.toggle()
            action.image = self.isFavorited ? self.heartFillImage : self.heartImage
        }

        let loopAction = UIAction(title: "Loop", image: loopImage, state: .off) { action in
            action.state = (action.state == .off) ? .on : .off
        }

        let speedActions = ["0.5x": Float(0.5), "1x": Float(1.0), "2x": Float(2.0)].map { title, value in
            UIAction(title: title, state: player?.rate == value ? .on : .off) { [weak self] action in
                guard let player = self?.player,
                      let value = value else { return }
                player.rate = value
                action.state = .on
            }
        }
        let submenu = UIMenu(title: "Speed", options: [.displayInline, .singleSelection], children: speedActions)
        let menu = UIMenu(title: "Preferences", image: gearImage, children: [loopAction, submenu])

        playerViewController?.transportBarCustomMenuItems = [favoriteAction, menu]
    }

    // MARK: - Contextual Action
    // Skip按鈕出現的時間區段
    let skipRange = CMTimeRange(start: CMTime(seconds: 10, preferredTimescale: 1), end: CMTime(seconds: 20, preferredTimescale: 1))

    // 定義 Skip action
    private lazy var skipAction = UIAction(title: "跳過") { [weak self] _ in
        guard let player = self?.player else { return }
        let currentTime = player.currentTime().seconds
        let fastForwardedTime = CMTime(seconds: currentTime + 10, preferredTimescale: 1)
        player.seek(to: fastForwardedTime)
    }

    func addTimeObserverForSkipAciton() {
        let interval = CMTime(value: 1, timescale: 1)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let actions = self.skipRange.containsTime(time) ? [self.skipAction] : []
            self.playerViewController?.contextualActions = actions
        }
    }

    // MARK: - Configuration
    func commonInit() {

        playerItemStatusObservation = observe(\.pendingPlayerItem?.status) { (object, change) in
            DispatchQueue.main.async { // Avoid modifying an observed property from directly within an observer.
                let pendingItemStatus = object.pendingPlayerItem?.status
                if pendingItemStatus == AVPlayerItem.Status.readyToPlay {
                    object.pendingPlayerItem = nil
                    object.playerViewController?.player = object.player
                    object.player?.rate = 1.0
                }
            }
        }

        currentItemErrorObservation = observe(\.playerViewController?.player?.currentItem?.error) { (object, change) in
            DispatchQueue.main.async {
                if object.playerViewController?.player?.currentItem?.error != nil {
                    _ = object._dismiss()
                }
            }
        }
    }
    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if let playerViewController = playerViewController {
            view.addSubview(playerViewController.view)
            playerViewController.view.frame = view.bounds
        }
    }

    override func viewWillLayoutSubviews() {
        if let playerViewController = playerViewController {
            playerViewController.view.frame = view.bounds
        }
        super.viewWillLayoutSubviews()
    }

    private func loadNewPlayerViewController() {
        let newPlayerViewController = AVPlayerViewController()
        newPlayerViewController.delegate = self
        if let oldPlayerViewController = self.playerViewController {
            oldPlayerViewController.removeFromParent()
            oldPlayerViewController.viewIfLoaded?.removeFromSuperview()
        }
        self.playerViewController = newPlayerViewController
        player = AVQueuePlayer()
        addChild(newPlayerViewController)
        if isViewLoaded {
            view.addSubview(newPlayerViewController.view)
        }
    }

    private func _dismiss(stopping: Bool = true) -> Bool {
        if let playerViewController = self.playerViewController {
            isPlaybackActive = false
            if let presenting = presentingViewController {
                presenting.dismiss(animated: true, completion: {
                    // done
                    if stopping {
                        playerViewController.player?.rate = 0.0 // stop playback immediately (don't wait for dealloc)
                    }
                    playerViewController.removeFromParent()
                    playerViewController.view.removeFromSuperview()
                    self.playerViewController = nil
                })
                return true
            }
        }
        if let presenting = presentingViewController {
            if presenting.presentedViewController == self {
                presenting.dismiss(animated: true)
            }
        }
        return false
    }

    private func createMetadataItem(_ identifier: AVMetadataIdentifier,
                                    value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }

    private func metadataItemForMediaContentRating(_ rating: String) -> AVMetadataItem {
        return createMetadataItem(.iTunesMetadataContentRating, value: rating)
    }

    // MARK: - AVPlayerViewControllerDelegate

    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        return _dismiss()
    }
}
