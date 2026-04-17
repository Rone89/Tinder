import SwiftUI
import Photos

struct DeleteTrayView: View {
    @Environment(PhotoViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedIDs = Set<String>() // 存储多选的 ID
    @State private var isEditMode = false          // 是否开启编辑模式
    @State private var detailItem: PhotoItem? = nil // 用于展示大图的变量
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            VStack {
                if let group = viewModel.currentGroup {
                    let deleteItems = group.items.filter { $0.status == .delete }
                    
                    if deleteItems.isEmpty {
                        ContentUnavailableView("回收站为空", systemImage: "trash")
                    } else {
                        // 顶部操作栏
                        if isEditMode {
                            HStack {
                                Button(selectedIDs.count == deleteItems.count ? "取消全选" : "全选") {
                                    if selectedIDs.count == deleteItems.count {
                                        selectedIDs.removeAll()
                                    } else {
                                        selectedIDs = Set(deleteItems.map { $0.id })
                                    }
                                }
                                Spacer()
                                Text("已选 \(selectedIDs.count) 张").font(.subheadline).foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }

                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(deleteItems) { item in
                                    ZStack(alignment: .topTrailing) {
                                        ThumbnailView(asset: item.asset)
                                            .onTapGesture {
                                                if isEditMode {
                                                    if selectedIDs.contains(item.id) {
                                                        selectedIDs.remove(item.id)
                                                    } else {
                                                        selectedIDs.insert(item.id)
                                                    }
                                                } else {
                                                    detailItem = item // 非编辑模式点击看大图
                                                }
                                            }
                                        
                                        // 选择框
                                        if isEditMode {
                                            Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedIDs.contains(item.id) ? .blue : .white)
                                                .background(Circle().fill(.black.opacity(0.2)))
                                                .padding(5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("回收站")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditMode ? "完成" : "多选") {
                        isEditMode.toggle()
                        selectedIDs.removeAll()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
                
                // 底部操作条 (仅在编辑模式显示)
                if isEditMode {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("移出回收站") {
                            viewModel.restoreItems(selectedIDs)
                            selectedIDs.removeAll()
                        }
                        .disabled(selectedIDs.isEmpty)
                        
                        Spacer()
                        
                        Button("彻底删除", role: .destructive) {
                            Task {
                                await viewModel.deleteSelectedItems(selectedIDs)
                                selectedIDs.removeAll()
                            }
                        }
                        .disabled(selectedIDs.isEmpty)
                    }
                }
            }
            // 弹出大图预览
            .fullScreenCover(item: $detailItem) { item in
                BigPhotoView(item: item)
            }
        }
    }
}

// MARK: - 大图查看组件
struct BigPhotoView: View {
    let item: PhotoItem
    @Environment(\.dismiss) var dismiss
    @State private var bigImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let bigImage = bigImage {
                Image(uiImage: bigImage)
                    .resizable()
                    .scaledToFit()
                    .interactiveDismissDisabled(false)
            } else {
                ProgressView().tint(.white)
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(for: item.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { img, _ in
                self.bigImage = img
            }
        }
    }
}
