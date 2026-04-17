import Foundation
import Photos

enum ReviewStatus {
    case unreviewed, keep, delete
}

// 确保这里有 Identifiable
struct PhotoItem: Identifiable, Equatable {
    let id: String // 这里作为 ID
    let asset: PHAsset
    var status: ReviewStatus = .unreviewed
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
}

struct MonthGroup: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    var items: [PhotoItem]
    
    var unreviewedCount: Int { items.filter { $0.status == .unreviewed }.count }
    var deleteCount: Int { items.filter { $0.status == .delete }.count }
}
