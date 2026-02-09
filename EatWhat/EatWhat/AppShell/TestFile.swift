import SwiftUI

struct ApolloCard: View {
    // 图片 URL
    let imageURL = URL(string: "https://images.unsplash.com/photo-1541873676-a18131494184?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80")
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // --- 1. 背景层 (处理模糊与图片) ---
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // 1.1 底层：清晰的原图
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    
                    // 1.2 中层：雾状模糊层 (关键修改)
                    // 复制一份图片，进行高斯模糊，并使用遮罩只显示底部
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .blur(radius: 20) // 高斯模糊半径，数值越大雾感越强
                                .mask(
                                    // 遮罩：上部透明(看不见模糊)，下部黑色(显示模糊)
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: 0.4), // 0-40% 保持清晰
                                            .init(color: .black, location: 0.9)  // 底部完全模糊
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                    
                    // 1.3 顶层：暗色渐变遮罩 (关键修改)
                    // 为了让白色文字可读，必须压暗底部
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .black.opacity(0.1),
                            .black.opacity(0.6), // 底部加深，提高对比度
                            .black.opacity(0.9)
                        ]),
                        startPoint: .center, // 从中间开始渐变
                        endPoint: .bottom
                    )
                }
            }
            // 强制限制 GeometryReader 尺寸，否则它会撑满全屏
            .frame(width: 380, height: 240)
            
            // --- 2. 内容层 (文字与按钮) ---
            VStack {
                // Header: NASA Logo & Date
                HStack(alignment: .top) {
                    Text("NASA")
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(-2) // 紧凑字间距
                    
                    Spacer()
                    
                    Text("July 20, 1969")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7)) // 稍微透一点白，比纯灰更好看
                        .padding(.top, 4)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer: Title & Button
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Apollo 11")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("One small step for man, one giant\nleap for mankind.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(2)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        print("Tapped")
                    }) {
                        Text("Learn more")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Material.ultraThin) // 使用真正的磨砂材质
                                    .environment(\.colorScheme, .dark) // 强制暗色模式材质
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
            .frame(width: 380, height: 240)
        }
        .background(Color.black)
        .cornerRadius(32) // 更大的圆角
        .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15) // 弥散阴影
    }
}

struct ApolloCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(white: 0.92).edgesIgnoringSafeArea(.all)
            ApolloCard()
        }
    }
}
