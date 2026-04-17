import SwiftUI
import Photos

struct DeleteTrayView: View {
    @Environment(PhotoViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedIDs: Set<String> = []
    @State private var isEditMode = false
    @State private var detailItem: PhotoItem? = nil
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            VStack {
                if let group = viewModel.currentGroup {
                    let deleteItems = group.items.filter { $0.status == .delete }
                    
                    if deleteItems.isEmpty {
                        ContentUnavailableView("回收站为空", systemImage: "trash")
                    } else {
                        if isEditMode {
                            HStack {
                                Button(selectedIDs.count == deleteItems.count ? "取消全选" : "全选") {
                                    if selectedIDs.count == deleteItems.count { selectedIDs = [] }
                                    else { selectedIDs = Set(deleteItems.map { $0.id }) }
                                }
                                Spacer()
                                Text("已选 \(selectedIDs.count) 张").font(.caption).foregroundColor(.secondary)
                            }.padding(.horizontal)
                        }

                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(deleteItems) { item in
                                    ZStack(alignment: .topTrailing) {
                                        ThumbnailView(asset: item.asset)
                                            .onTapGesture {
                                                if isEditMode {
                                                    if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) }
                                                    else { selectedIDs.insert(item.id) }
                                                } else { detailItem = item }
                                            }
                                        if isEditMode {
                                            Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedIDs.contains(item.id) ? .blue : .white)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { 
                    Button(isEditMode ? "取消" : "选择") { 
                        isEditMode.toggle()
                        selectedIDs = []
                    } 
                }
                ToolbarItem(placement: .topBarTrailing) { Button("关闭") { dismiss() } }
                
                if isEditMode {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("恢复") { 
                            viewModel.restoreItems(selectedIDs)
                            isEditMode = false
                        }.disabled(selectedIDs.isEmpty)
                        Spacer()
                        Button("彻底删除", role: .destructive) {
                            Task { 
                                await viewModel.deleteSelectedItems(selectedIDs)
                                isEditMode = false
                            }
                        }.disabled(selectedIDs.isEmpty)
                    }
                }
            }
            .fullScreenCover(item: $detailItem) { item in
                BigPhotoView(item: item)
            }
        }
    }
}

struct BigPhotoView: View {
    let item: PhotoItem
    @Environment(\.dismiss) var dismiss
    @State private var bigImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let bigImage = bigImage {
                Image(uiImage: bigImage).resizable().scaledToFit()
            } else { ProgressView().tint(.white) }
            
            VStack {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.largeTitle).foregroundColor(.white.opacity(0.7)) }
                    Spacer()
                }
                Spacer()
            }.padding()
        }
        .onAppear {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            // 修正闭包参数：(UIImage?, [AnyHashable: Any]?)
            PHImageManager.default().requestImage(for: item.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (img: UIImage?, _: [AnyHashable: Any]?) in
                self.bigImage = img
            }
        }
    }
}
