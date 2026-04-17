import SwiftUI
import Photos

struct ReviewView: View {
    @Environment(PhotoViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingTray = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let group = viewModel.currentGroup {
                    // 顶部进度条
                    ProgressView(value: Double(viewModel.currentCardIndex), total: Double(group.items.count))
                        .padding()
                        .tint(.blue)
                    
                    if viewModel.currentCardIndex < group.items.count {
                        ZStack {
                            // 下一张预加载
                            if viewModel.currentCardIndex + 1 < group.items.count {
                                let nextItem = group.items[viewModel.currentCardIndex + 1]
                                PhotoCardView(item: nextItem, onSwipe: { _ in })
                                    .id(nextItem.id)
                                    .scaleEffect(0.95)
                                    .offset(y: 10)
                                    .opacity(0.7)
                                    .zIndex(0)
                            }
                            
                            // 当前卡片
                            let currentItem = group.items[viewModel.currentCardIndex]
                            PhotoCardView(item: currentItem, onSwipe: { direction in
                                viewModel.handleSwipe(direction: direction)
                            })
                            .id(currentItem.id)
                            .zIndex(1)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        }
                        .padding()
                        
                        // 底部手势引导
                        HStack(spacing: 50) {
                            VStack { Image(systemName: "arrow.left").foregroundColor(.green); Text("保留") }
                            VStack { Image(systemName: "arrow.up").foregroundColor(.red); Text("删除") }
                            VStack { Image(systemName: "arrow.right").foregroundColor(.orange); Text("撤销") }
                        }
                        .font(.caption)
                        .padding(.vertical, 20)
                        
                    } else {
                        SummaryView()
                    }
                }
            }
            .navigationTitle(viewModel.currentGroup?.title ?? "清理中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingTray = true } label: {
                        Image(systemName: "trash")
                            .symbolEffect(.bounce, value: viewModel.currentGroup?.deleteCount)
                    }
                    .disabled(viewModel.currentGroup?.deleteCount == 0)
                }
            }
            .sheet(isPresented: $showingTray) {
                DeleteTrayView()
                    .environment(viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - PhotoCardView (修复了截图中的编译错误)
struct PhotoCardView: View {
    let item: PhotoItem
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var image: UIImage? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    ProgressView()
                }
                
                overlayContent
            }
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 25)))
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { value in
                        let width = value.translation.width
                        let height = value.translation.height
                        
                        // 使用 iOS 17 弹簧动画
                        if width < -120 {
                            withAnimation(.bouncy) { offset = CGSize(width: -600, height: height) }
                            onSwipe(.left)
                        } else if height < -120 && abs(width) < 100 {
                            withAnimation(.bouncy) { offset = CGSize(width: width, height: -1000) }
                            onSwipe(.up)
                        } else if width > 120 {
                            onSwipe(.right)
                            withAnimation(.spring()) { offset = .zero }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { offset = .zero }
                        }
                    }
            )
            .onAppear {
                loadImage(size: geo.size)
            }
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        if offset.width < -50 {
            Text("KEEP").font(.system(size: 45, weight: .heavy)).foregroundColor(.green).opacity(0.5)
        } else if offset.height < -50 {
            Text("DELETE").font(.system(size: 45, weight: .heavy)).foregroundColor(.red).opacity(0.5)
        }
    }
    
    // 核心修复：显式指定类型，防止编译器无法推断
    private func loadImage(size: CGSize) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        let targetSize = CGSize(width: size.width * 2, height: size.height * 2)
        
        manager.requestImage(for: item.asset, 
                             targetSize: targetSize, 
                             contentMode: PHImageContentMode.aspectFill, 
                             options: options) { (result: UIImage?, _: [AnyHashable : Any]?) in
            if let result = result {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
        }
    }
}
