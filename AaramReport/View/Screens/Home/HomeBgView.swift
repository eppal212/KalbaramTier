import UIKit
import RxSwift
import AVFoundation

@IBDesignable
class HomeBgView: UIView {

    private let ovelayDim = UIView()
    @IBInspectable var overlayOpacity: CGFloat = 0 { // 동영상 위에 오버레이 되는 Dim 투명도
        didSet {
            ovelayDim.backgroundColor = UIColor(white: 0, alpha: overlayOpacity)
        }
    }
    @IBInspectable var videoName: String = "" // 재생할 비디오 이름
    @IBInspectable var videoExtension: String = "mp4"

    private let playerLayer = AVPlayerLayer() // 동영상을 재생할 레이어
    private var playerLooper: AVPlayerLooper? // 동영상 반복

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initLayout()
        initBinding()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initLayout()
        initBinding()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = self.bounds
    }

    // UI 초기화
    private func initLayout() {
        // 동영상 세팅
        guard let videoFile = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else { return }
        let playerItem = AVPlayerItem(url: videoFile)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(playerLayer)
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        queuePlayer.play()
        queuePlayer.isMuted = true

        // Dim 세팅
        self.addSubview(ovelayDim)
        ovelayDim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ovelayDim.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            ovelayDim.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
            ovelayDim.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            ovelayDim.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0)])
    }

    // 백/포그라운드 전환시 동영상 처리
    private func initBinding() {
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.playerLayer.player?.pause()
            })
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.playerLayer.player?.play()
            })
            .disposed(by: disposeBag)
    }
}
