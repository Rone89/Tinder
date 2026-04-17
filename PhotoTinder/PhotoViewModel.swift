// 全选或取消全选
    func toggleSelectAllInTray(isSelected: Bool) {
        guard let gIdx = currentGroupIndex else { return }
        for i in monthGroups[gIdx].items.indices {
            if monthGroups[gIdx].items[i].status == .delete {
                // 这里我们可以给 PhotoItem 增加一个 isSelected 属性，
                // 或者简单地把状态改回 .keep (即移出回收站)
            }
        }
    }

    // 批量移出回收站 (恢复)
    func restoreItems(_ ids: Set<String>) {
        guard let gIdx = currentGroupIndex else { return }
        for id in ids {
            if let iIdx = monthGroups[gIdx].items.firstIndex(where: { $0.id == id }) {
                monthGroups[gIdx].items[iIdx].status = .keep
            }
        }
    }

    // 彻底删除选中的照片 (调用系统删除)
    func deleteSelectedItems(_ ids: Set<String>) async {
        guard let gIdx = currentGroupIndex else { return }
        let assetsToDelete = monthGroups[gIdx].items
            .filter { ids.contains($0.id) }
            .map { $0.asset }
        
        do {
            try await PhotoLibraryService.shared.deleteAssets(assetsToDelete)
            // 删除成功后，从本地列表移除
            monthGroups[gIdx].items.removeAll { ids.contains($0.id) }
        } catch {
            print("删除失败: \(error)")
        }
    }
