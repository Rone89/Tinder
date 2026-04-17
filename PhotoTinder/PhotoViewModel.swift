import SwiftUI
import Photos

@MainActor
@Observable
class PhotoViewModel {
    var isAuthorized = false
    var isLoading = false
    var monthGroups: [MonthGroup] = []
    var currentGroupIndex: Int? = nil
    var currentCardIndex: Int = 0
    
    var currentGroup: MonthGroup? {
        guard let index = currentGroupIndex, monthGroups.indices.contains(index) else { return nil }
        return monthGroups[index]
    }
    
    func checkPermissionAndFetch() async {
        isLoading = true
        isAuthorized = await PhotoLibraryService.shared.requestAuthorization()
        if isAuthorized {
            monthGroups = await PhotoLibraryService.shared.fetchAndGroupPhotos()
        }
        isLoading = false
    }
    
    func startReviewing(index: Int) {
        currentGroupIndex = index
        currentCardIndex = monthGroups[index].items.firstIndex(where: { $0.status == .unreviewed }) ?? 0
    }
    
    func handleSwipe(direction: SwipeDirection) {
        guard let gIdx = currentGroupIndex else { return }
        switch direction {
        case .left: monthGroups[gIdx].items[currentCardIndex].status = .keep
        case .up: monthGroups[gIdx].items[currentCardIndex].status = .delete
        case .right: 
            if currentCardIndex > 0 {
                currentCardIndex -= 1
                monthGroups[gIdx].items[currentCardIndex].status = .unreviewed
                return
            }
        case .down: break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentCardIndex += 1
        }
    }
    
    // 移出回收站 (批量恢复)
    func restoreItems(_ ids: Set<String>) {
        guard let gIdx = currentGroupIndex else { return }
        for id in ids {
            if let iIdx = monthGroups[gIdx].items.firstIndex(where: { $0.id == id }) {
                monthGroups[gIdx].items[iIdx].status = .keep
            }
        }
    }

    // 彻底删除选中的照片
    func deleteSelectedItems(_ ids: Set<String>) async {
        guard let gIdx = currentGroupIndex else { return }
        let assetsToDelete = monthGroups[gIdx].items
            .filter { ids.contains($0.id) }
            .map { $0.asset }
        
        do {
            try await PhotoLibraryService.shared.deleteAssets(assetsToDelete)
            monthGroups[gIdx].items.removeAll { ids.contains($0.id) }
        } catch {
            print("删除失败")
        }
    }
    
    func cancelDelete(for id: String) {
        guard let gIdx = currentGroupIndex else { return }
        if let iIdx = monthGroups[gIdx].items.firstIndex(where: { $0.id == id }) {
            monthGroups[gIdx].items[iIdx].status = .keep
        }
    }
}

enum SwipeDirection { case left, right, up, down }
