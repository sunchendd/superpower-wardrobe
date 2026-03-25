import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Header
                headerSection

                // MARK: - Form
                formSection
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                // MARK: - Actions
                actionSection
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // MARK: - Toggle Mode
                toggleModeButton
                    .padding(.top, 16)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // MARK: - Guest Mode
                guestSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer(minLength: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .alert("提示", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "hanger")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.top, 60)

            Text("超级衣橱")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("管理你的衣橱，发现完美搭配")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Label("邮箱", systemImage: "envelope")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("your@email.com", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Label("密码", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("至少 6 位字符", text: $viewModel.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(viewModel.isSignUpMode ? .next : .done)
                    .onSubmit {
                        if viewModel.isSignUpMode {
                            focusedField = .confirmPassword
                        } else {
                            focusedField = nil
                            Task { await viewModel.signIn() }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Confirm Password (sign up only)
            if viewModel.isSignUpMode {
                VStack(alignment: .leading, spacing: 6) {
                    Label("确认密码", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("再次输入密码", text: $viewModel.confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            Task { await viewModel.signUp() }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.isSignUpMode)
    }

    private var actionSection: some View {
        Button {
            focusedField = nil
            Task {
                if viewModel.isSignUpMode {
                    await viewModel.signUp()
                } else {
                    await viewModel.signIn()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isSignUpMode ? "创建账号" : "登录")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .disabled(viewModel.isLoading)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var toggleModeButton: some View {
        Button {
            viewModel.toggleMode()
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.isSignUpMode ? "已有账号？" : "还没有账号？")
                    .foregroundStyle(.secondary)
                Text(viewModel.isSignUpMode ? "立即登录" : "免费注册")
                    .foregroundStyle(.indigo)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
        .disabled(viewModel.isLoading)
    }

    private var guestSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)
                Text("或")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)
            }

            Button {
                viewModel.continueAsGuest()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                    Text("以游客身份体验")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("游客模式数据仅保存在本设备，注册账号可同步云端")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel())
}
