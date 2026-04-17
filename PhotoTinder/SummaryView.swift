import SwiftUI

struct SummaryView: View {
    @Environment(PhotoViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: true)
            
            Text("本月照片已阅完").font(.title2.bold())
            
            if let group = viewModel.currentGroup {
                VStack(spacing: 12) {
                    Text("待删除: \(group.deleteCount) 张").foregroundColor(.red).font(.headline)
                    Text("保留: \(group.items.count - group.deleteCount) 张").foregroundColor(.green)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
            }
            
            Button("查看回收站并删除") {
                // 触发 ReviewView 里的 sheet 展示
                dismiss() 
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("返回主列表") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
