//
//  PlayerViewController.swift
//  tvOS15PlaybackUI
//
//  Created by Zheng-Yuan Yu on 2022/2/28.
//

import UIKit
import AVKit

/*
Modified codes from Apple's sample code: https://developer.apple.com/documentation/avkit/working_with_overlays_and_parental_controls_in_tvos
 */

class VideoPlaybackViewController: UIViewController, AVPlayerViewControllerDelegate {

    @objc dynamic var playerViewController: AVPlayerViewController?

    var player: AVQueuePlayer?
    @objc dynamic var pendingPlayerItem: AVPlayerItem?
    var playerItemStatusObservation: NSKeyValueObservation?
    var currentItemErrorObservation: NSKeyValueObservation?

    var isPlaybackActive = false

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
        // Do any additional setup after loading the view.
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

    private func metadataItem(_ identifier: AVMetadataIdentifier, stringValue value: String) -> AVMutableMetadataItem {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        metadataItem.identifier = identifier
        return metadataItem
    }

    private func metadataItemForMediaContentRating(_ rating: String) -> AVMetadataItem {
        return metadataItem(.iTunesMetadataContentRating, stringValue: rating)
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

    func loadAndPlay(url: URL, title: String, description: String, rating: String) {
        loadNewPlayerViewController()
        let playerItem = AVPlayerItem(url: url)
        playerItem.externalMetadata = [
            metadataItemForMediaContentRating(rating),
            metadataItem(AVMetadataIdentifier.commonIdentifierTitle, stringValue: title),
            metadataItem(.commonIdentifierDescription, stringValue: description)
        ]
        self.pendingPlayerItem = playerItem
        player?.replaceCurrentItem(with: playerItem)
        if playerViewController != nil && !isPlaybackActive {
            isPlaybackActive = true
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

    // MARK: - AVPlayerViewControllerDelegate

    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        return _dismiss()
    }
}
