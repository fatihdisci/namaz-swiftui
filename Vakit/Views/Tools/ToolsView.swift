import SwiftUI

struct ToolsView: View {
    @State private var showProGate = false
    @State private var proGateContext: ProGateContext = .general

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(lang.t("tools.title"))
                            .font(.vakitScreenTitle)
                            .foregroundStyle(Color.vakitText)

                        VStack(spacing: 12) {
                            proTool(
                                icon: "airplane",
                                titleKey: "safar.title",
                                subtitleKey: "safar.description",
                                context: .safar
                            ) {
                                SafarView()
                            }

                            proTool(
                                icon: "checklist",
                                titleKey: "kaza.title",
                                subtitleKey: "kaza.subtitle",
                                context: .kaza
                            ) {
                                KazaView()
                            }

                            NavigationLink {
                                QiblaView()
                            } label: {
                                toolRow(
                                    icon: "safari.fill",
                                    titleKey: "qibla.title",
                                    subtitleKey: "qibla.subtitle",
                                    isLocked: false
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showProGate) {
            ProGateView(context: proGateContext)
                .environment(lang)
                .environment(purchaseService)
        }
    }

    private func proTool<Destination: View>(
        icon: String,
        titleKey: String,
        subtitleKey: String,
        context: ProGateContext,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        Group {
            if purchaseService.hasProAccess {
                NavigationLink {
                    destination()
                } label: {
                    toolRow(icon: icon, titleKey: titleKey, subtitleKey: subtitleKey, isLocked: false)
                }
            } else {
                Button {
                    proGateContext = context
                    showProGate = true
                } label: {
                    toolRow(icon: icon, titleKey: titleKey, subtitleKey: subtitleKey, isLocked: true)
                }
            }
        }
    }

    private func toolRow(
        icon: String,
        titleKey: String,
        subtitleKey: String,
        isLocked: Bool
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(lang.t(titleKey))
                    .font(.vakitBodyRounded)
                    .foregroundStyle(Color.vakitText)
                Text(lang.t(subtitleKey))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.vakitAccent)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.vakitTextDim)
        }
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ToolsView()
        .environment(LanguageService.shared)
        .environment(PurchaseService.shared)
}
