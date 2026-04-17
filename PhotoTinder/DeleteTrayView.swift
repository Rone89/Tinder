import SwiftUI
import Photos

struct DeleteTrayView: View {
    @Environment(PhotoViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let group = viewModel.currentGroup {
                    let items = group.items.filter { $0.status == .delete }
                    
                    if items.isEmpty {
                        VStack(spacing: 20) {
                            Spacer().frame(height: 100)
                            Image(systemName: "trash").font(.system(size: 50)).foregroundColor(.gray)
                            Text("待删除列表为空").foregroundColor(.secondary)
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(items) { item in
                                ThumbnailView(asset: item.asset)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.white, .red)
                                            .padding(4)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            viewModel.cancelDelete(for: item.id)
                                        }
                                    }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("待删除预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct ThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.2))
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .onAppear {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            
            // 核心修复：显式处理 2 个闭包参数 (img, info)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: PHImageContentMode.aspectFill,
                options: options
            ) { (img: UIImage?, info: [AnyHashable : Any]?) in
                DispatchQueue.main.async {
                    self.image = img
                }
            }
        }
    }
}
