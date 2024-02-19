import Foundation
import RxSwift

class DataDragon {
    static let `default`: DataDragon = {
        return DataDragon()
    }()

    private var version: String = ""
    private var spellMetadata: SpellMetadata?
    private var runeMetadata: [RuneMetadata]?

    private let disposeBag = DisposeBag()

    // MARK: - Metadata
    // 최신 버전 획득
    func getLatestVersion(onError: @escaping () -> Void) {
        if version.isEmpty {
            ApiClient.default.getVersion().subscribe(onNext: { [weak self] versions in
                guard let version = versions.first else { return }
                self?.version = version
                self?.getMetadata()
            }, onError: { _ in
                onError()
            }).disposed(by: disposeBag)
        }
    }

    // DDragon 메타데이터 세팅
    private func getMetadata() {
        // 소환사 주문
        ApiClient.default.getSpellMetadata(version: version).subscribe(onNext: { [weak self] data in
            self?.spellMetadata = data
        }).disposed(by: disposeBag)

        // 룬
        ApiClient.default.getRuneMetadata(version: version).subscribe(onNext: { [weak self] data in
            self?.runeMetadata = data
        }).disposed(by: disposeBag)
    }

    // MARK: - Data from ID
    // 프로필 아이콘 url 반환
    func getProfileImageUrl(id: Int?) -> URL? {
        let path = Const.dataDragon + "cdn/\(version)/img/profileicon/\(id ?? 0).png"
            return URL(string: path)
    }

    // 소환사 주문 이미지 url 반환
    func getSpellImageUrl(id: Int?) -> URL? {
        var path = Const.dataDragon + "cdn/\(version)/img/spell/"
        for (_, data) in spellMetadata?.data?.asDictionary ?? [:] where data?.key == String(id ?? 0) {
            path += data?.image?.full ?? ""
        }
        return URL(string: path)
    }

    // 룬 이미지 url 반환
    func getRuneImageUrl(perks: PerksDto?) -> [URL?] {
        var primaryId: Int?
        var secondaryId: Int?
        for perk in perks?.styles ?? [] {
            if perk.description == "primaryStyle" {
                primaryId = perk.selections?.first?.perk
            } else {
                secondaryId = perk.style
            }
        }

        let path = Const.dataDragon + "cdn/img/"
        var primaryUrl: URL?
        var secondaryUrl: URL?
        for rune in runeMetadata ?? []{
            // 보조룬 분류
            if rune.id == secondaryId {
                secondaryUrl = URL(string: path + (rune.icon ?? ""))
            }

            // 메인룬 특정
            for mainRune in rune.slots?.first?.runes ?? [] where mainRune.id == primaryId {
                primaryUrl = URL(string: path + (mainRune.icon ?? ""))
            }
        }

        return [primaryUrl, secondaryUrl]
    }

    // 아이템 이미지 url 반환
    func getItemImageUrl(id: Int?) -> URL? {
        let path = Const.dataDragon + "cdn/\(version)/img/item/\(id ?? 0).png"
            return URL(string: path)
    }
}
