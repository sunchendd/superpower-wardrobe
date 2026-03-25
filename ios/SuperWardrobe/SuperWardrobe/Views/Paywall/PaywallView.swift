import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseService.self) private var purchaseService
    @State private var animateGradient = false

    private let features: [(icon: String, color: Color, title: String, desc: String)] = [
        ("tshirt.fill",          .indigo,  "智能衣橱管理",   "拍照即可添加，AI 自动识别分类"),
        ("sparkles",             .purple,  "每日穿搭推荐",   "结合天气与风格，智能搭配建议"),
        ("chart.pie.fill",       .orange,  "衣橱统计分析",   "穿着频率、花费分布一目了然"),
        ("calendar",             .teal,    "穿搭日记日历",   "记录每天的心情与穿搭故事"),
        ("airplane",             .blue,    "旅行打包助手",   "出行前智能推荐必带衣物"),
        ("iphone",               .green,   "数据完全本地",   "无需注册，隐私数据存在你的手机"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero
                heroSection

                // MARK: - Features
                featuresSection
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                // MARK: - CTA
                ctaSection
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .alert("提示", isPresented: .init(
            get: { purchaseService.errorMessage != nil },
            set: { if !$0 { purchaseService.errorMessage = nil } }
        )) {
            Button("确定") { purchaseService.errorMessage = nil }
        } message: {
            Text(purchaseService.errorMessage ?? "")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.indigo.opacity(animateGradient ? 0.9 : 0.7),
                    Color.purple.opacity(animateGradient ? 0.7 : 0.9),
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea(edges: .top)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }

            VStack(spacing: 16) {
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: "hanger")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.top, 60)

                Text("超级衣橱")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("你的智能穿搭助手")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                // Price badge
                Text("买断制 · 一次付费，永久使用")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("包含全部功能")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 0) {
                ForEach(features, id: \.title) { feature in
                    featureRow(feature)

                    if feature.title != features.last?.title {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func featureRow(_ feature: (icon: String, color: Color, title: String, desc: String)) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(feature.desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            // Price + Purchase button
            VStack(spacing: 8) {
                if let product = purchaseService.products.first {
                    Text(product.displayPrice)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
                } else {
                    Text("¥6")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Text("买断制，无订阅，无套路")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await purchaseService.purchase() }
            } label: {
                Group {
                    if purchaseService.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open.fill")
                            Text("立即解锁")
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(purchaseService.isLoading)
            .shadow(color: .indigo.opacity(0.4), radius: 12, y: 6)

            // Restore
            Button {
                Task { await purchaseService.restore() }
            } label: {
                Text("恢复购买")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(purchaseService.isLoading)

            // Legal footer
            Group {
                Text("付款将在确认购买后从您的 Apple 账户扣除。") +
                Text(" 本应用为买断制，购买后永久使用。") +
                Text("\n[隐私政策](https://example.com/privacy)") +
                Text("  ") +
                Text("[使用条款](https://example.com/terms)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .tint(.secondary)
        }
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseService.shared)
}
