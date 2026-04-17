import SwiftUI

struct SummaryView: View {
    @Environment(PhotoViewModel.self) var viewModel // 确保这里使用的是 .self 且类型正确
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.green)
            Text("本月照片已阅完").font(.title2.bold())
            
            if let group = viewModel.currentGroup {
                VStack(spacing: 10) {
                    Text("待删除: \(group.deleteCount) 张").foregroundColor(.red)
                    Text("保留: \(group.items.count - group.deleteCount) 张").foregroundColor(.green)
                }
            }
            
            Button("查看回收站并处理") {
                // 这个按钮可以触发跳转或直接在 ReviewView 中通过 toolbar 查看
                dismiss() 
            }
            .buttonStyle(.borderedProminent)
            
            Button("返回主列表") { dismiss() }.foregroundColor(.secondary)
        }
        .padding()
    }
}
