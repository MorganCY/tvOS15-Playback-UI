//
//  ViewController.swift
//  tvOS15PlaybackUI
//
//  Created by Zheng-Yuan Yu on 2022/2/28.
//

import UIKit
import TVUIKit

/*
Modified codes from Apple's sample code: https://developer.apple.com/documentation/avkit/working_with_overlays_and_parental_controls_in_tvos
 */

class MenuViewController: UIViewController {

    @IBOutlet var posterView: TVPosterView?

    var videoPlaybackViewController: VideoPlaybackViewController

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        videoPlaybackViewController = VideoPlaybackViewController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        videoPlaybackViewController = VideoPlaybackViewController()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }

    func presentVideo(_ url: URL, title: String, description: String, rating: String) {
        present(videoPlaybackViewController, animated: true) {
            self.videoPlaybackViewController.loadAndPlay(url: url, title: title, description: description, rating: rating)
        }
    }

    @IBAction func action(posterView: TVPosterView) {
        let title = "自定義的標題"
        let url = URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!
        let description = "這裡可以輸入影片介紹。"
        let rating = "普遍級"

        presentVideo(url, title: title, description: description, rating: rating)
    }
}

