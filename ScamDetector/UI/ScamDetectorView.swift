//
//  ScamDetectorView.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import SwiftUI
import UIKit

struct ScamDetectorView: View {
    @State private var viewModel = ScamDetectorViewModel()
    @FocusState private var isMessageInputFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isMessageInputFocused = false
                }

            ScrollView {
                VStack(spacing: 28) {
                    headerView

                    VStack(spacing: 16) {
                        exampleMessagesView

                        messageInputView

                        Button {
                            isMessageInputFocused = false

                            Task {
                                await viewModel.analyze()
                            }
                        } label: {
                            Text(viewModel.analysisState.isAnalyzing ? "Analyzing..." : "Analyze")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .foregroundStyle(viewModel.canAnalyze ? .black : .white)
                        .disabled(!viewModel.canAnalyze)
                        
                    }

                    analysisStatusView
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled.trianglebadge.exclamationmark")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.yellow, .primary)

            Text("Scam Check")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }

    private var exampleMessagesView: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 118), spacing: 10)
            ],
            spacing: 10
        ) {
            ForEach(viewModel.exampleMessages) { example in
                Button {
                    viewModel.selectExample(example)
                    isMessageInputFocused = false
                } label: {
                    Text(example.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .background {
                            Capsule()
                                .fill(Color(.secondarySystemBackground))
                        }
                        .overlay {
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var messageInputView: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                }

            TextEditor(text: $viewModel.messageText)
                .font(.body)
                .focused($isMessageInputFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 46)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            isMessageInputFocused = false
                        }
                    }
                }

            if viewModel.messageText.isEmpty {
                Text("Paste a suspicious message or URL")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }

            Button("Paste") {
                pasteClipboardText()
                isMessageInputFocused = false
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .padding(12)
        }
        .frame(height: 180)
    }

    @ViewBuilder
    private var analysisStatusView: some View {
        switch viewModel.analysisState {
        case .idle:
            EmptyView()
        case .analyzing:
            ProgressView()
        case .success(let result):
            resultCard(for: result)
        case .failed(let message):
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    private func resultCard(for result: ScamAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                confidenceGauge(for: result)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.riskLevel.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(riskColor(for: result.riskLevel))

                    Text("Risk assessment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(result.explanation)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !result.detectedSignals.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Detected signals")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 118), spacing: 10)
                        ],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(result.detectedSignals, id: \.self) { signal in
                            Text(signal)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .padding(.horizontal, 10)
                                .background {
                                    Capsule()
                                        .fill(riskColor(for: result.riskLevel).opacity(0.12))
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(riskColor(for: result.riskLevel).opacity(0.35), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        }
    }

    private func confidenceGauge(for result: ScamAnalysisResult) -> some View {
        ZStack {
            Circle()
                .stroke(riskColor(for: result.riskLevel).opacity(0.18), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(result.confidenceScore) / 100)
                .stroke(
                    riskColor(for: result.riskLevel),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(result.confidenceScore)%")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .frame(width: 72, height: 72)
    }

    private func riskColor(for riskLevel: ScamRiskLevel) -> Color {
        switch riskLevel {
        case .safe:
            .green
        case .suspicious:
            .orange
        case .dangerous:
            .red
        }
    }

    private func pasteClipboardText() {
        guard let clipboardText = UIPasteboard.general.string else {
            return
        }

        viewModel.messageText = clipboardText
    }
}
