import Foundation
import Photos

enum ReviewStatus {
    case unreviewed, keep, delete
}

struct PhotoItem: Identifiable, Equatable {
    let id: String 
    let asset: PHAsset
    var status: ReviewStatus = .unreviewed
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
}

struct MonthGroup: Identifiable {
    let id: UUID = UUID() // 显式初始化
    let title: String
    let date: Date
    var items: [PhotoItem]
    
    var unreviewedCount: Int { items.filter { $0.status == .unreviewed }.count }
    var deleteCount: Int { items.filter { $0.status == .delete }.count }
}
