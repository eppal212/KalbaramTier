import Foundation
import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class MatchListViewController: UIViewController {
    // 상단 탭 바
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerNick: UILabel!
    @IBOutlet weak var headerTag: UILabel!

    // 프로필 부분
    @IBOutlet weak var profileSplash: StretchTableViewHeader! // 상단 챔피언 스플래시 아트
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileNick: UILabel!
    @IBOutlet weak var profileTag: UILabel!
    @IBOutlet weak var profileLevel: UILabel!

    // 테이블뷰
    @IBOutlet weak var tableView: UITableView!

    private let viewModel = MatchListViewModel()
    private var loadingView = LoadingView()

    private let tableViewObserverKey = "contentSize"
    private var isShowHeaderBg = false

    private let disposeBag = DisposeBag()

    // MARK: - Override & Init
    // 이동 전 호출되는 기본값 세팅 함수
    func setAccountData(accountData: AccountDto, server: RiotServer?) {
        viewModel.account = accountData
        viewModel.server = server
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showLoading(isShow: true)

        initLayout()
        initBinding()

        viewModel.getSummoner() // 데이터 조회 API 호출
    }

    private func initLayout() {
        // 그라데이션
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        gradient.colors = [UIColor.black.withAlphaComponent(1).cgColor, UIColor.black.withAlphaComponent(0).cgColor]
        gradientView.layer.addSublayer(gradient)

        profileImage.layer.cornerRadius = 16

        headerNick.text = viewModel.account?.gameName
        profileNick.text = viewModel.account?.gameName
        headerTag.text = "#\(viewModel.account?.tagLine ?? "")"
        profileTag.text = "#\(viewModel.account?.tagLine ?? "")"

        // TableView
        tableView.rowHeight = 100
        tableView.showsVerticalScrollIndicator = false
    }

    private func initBinding() {
        // 상단 프로필 파트
        viewModel.summonerRelay.subscribe(onNext: { [weak self] summoner in
            self?.profileImage.sd_setImage(with: DataDragon.default.getProfileImageUrl(id: summoner.profileIconId))
            self?.profileLevel.text = "Lv.\(summoner.summonerLevel ?? 0) I \(summoner.name ?? "0")"
        }).disposed(by: disposeBag)

        viewModel.splashSkinList.subscribe(onNext: { [weak self] skinList in
            self?.profileSplash.imageView.sd_setImage(with: DataDragon.default.getSplashArt(skinList: skinList))
        }).disposed(by: disposeBag)

        // TableView
        viewModel.matchListRelay
            .filter { [weak self] data in
                data.count == self?.viewModel.matchListCount
            }
            .map { $0.sorted(by: { $0.info?.gameStartTimestamp ?? 0 > $1.info?.gameStartTimestamp ?? 0 }) }
            .bind(to: tableView.rx.items(cellIdentifier: "MatchListCell")) { [weak self] index, item, cell in
                guard let cell = cell as? MatchListCell else { return }
                cell.setData(puuid: self?.viewModel.account?.puuid ?? "", data: item)
            }.disposed(by: disposeBag)

        // Scroll 처리
        tableView.rx.contentOffset.subscribe{ [weak self] offset in
            guard let self = self else { return }
            profileSplash.scrollViewDidScroll(offset: offset, inset: tableView.contentInset) // 스플래시아트 스크롤 처리

            // 헤더 처리
            let scrollEnough = offset.y > (profileSplash.frame.height / 2)
            if isShowHeaderBg != scrollEnough {
                isShowHeaderBg = scrollEnough
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.headerView.backgroundColor = scrollEnough ? .black : .clear
                    self?.headerNick.isHidden = !scrollEnough
                    self?.headerTag.isHidden = !scrollEnough
                }
            }
        }.disposed(by: disposeBag)

        viewModel.matchListRelay
            .filter{ [weak self] data in
                data.count >= self?.viewModel.matchListCount ?? 0
            }
            .subscribe { [weak self] _ in
                self?.showLoading(isShow: false)
            }.disposed(by: disposeBag)
    }

    // MARK: - Function
    private func showLoading(isShow: Bool) {
        if isShow {
            self.view.addSubview(loadingView)
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                loadingView.topAnchor.constraint(equalTo: self.view.topAnchor),
                loadingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                loadingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                loadingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        } else {
            loadingView.remove()
        }
    }

    // MARK: - IBAction
    @IBAction func onClickBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
