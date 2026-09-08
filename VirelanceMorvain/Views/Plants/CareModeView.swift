import SwiftUI

struct CareModeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var stepIndex = 0
    @State private var timerMinutes = 5
    @State private var remainingSeconds = 0
    @State private var isTimerRunning = false
    @State private var timerEnd: Date?

    private var steps: [String] { plant.careSteps }

    var body: some View {
        ZStack {
            SafeBackground()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                    Spacer()
                    Text("Step \(stepIndex + 1) of \(max(steps.count, 1))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("AppTextSecondary"))
                    Spacer()
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ProgressView(value: Double(stepIndex + 1), total: Double(max(steps.count, 1)))
                    .tint(Color("AppPrimary"))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 20) {
                    Text(plant.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AppAccent"))

                    Text(steps.isEmpty ? "No steps yet." : steps[stepIndex])
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                Spacer()

                stepTimerCard
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    Button {
                        guard stepIndex > 0 else { return }
                        stepIndex -= 1
                        resetStepTimer()
                        HapticService.selection()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(stepIndex == 0)
                    .opacity(stepIndex == 0 ? 0.45 : 1)

                    Button {
                        if stepIndex < steps.count - 1 {
                            stepIndex += 1
                            resetStepTimer()
                            HapticService.medium()
                            SoundService.tap()
                        } else {
                            HapticService.success()
                            SoundService.success()
                            dismiss()
                        }
                    } label: {
                        Text(stepIndex < steps.count - 1 ? "Next" : "Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AppPrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            guard isTimerRunning, let end = timerEnd else { return }
            remainingSeconds = max(0, Int(end.timeIntervalSince(date)))
            if remainingSeconds == 0 {
                isTimerRunning = false
                timerEnd = nil
                HapticService.success()
                SoundService.complete()
            }
        }
    }

    private var stepTimerCard: some View {
        VStack(spacing: 12) {
            Text("Step Timer")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppTextSecondary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            if isTimerRunning || remainingSeconds > 0 {
                Text(formatTime(remainingSeconds))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppAccent"))
                    .monospacedDigit()
            }

            HStack {
                Stepper("\(timerMinutes) min", value: $timerMinutes, in: 1...120)
                    .foregroundColor(Color("AppTextPrimary"))
                Button {
                    if isTimerRunning {
                        isTimerRunning = false
                        if let end = timerEnd {
                            remainingSeconds = max(0, Int(end.timeIntervalSinceNow))
                        }
                        timerEnd = nil
                        HapticService.selection()
                    } else {
                        let startFrom = remainingSeconds > 0 ? remainingSeconds : timerMinutes * 60
                        remainingSeconds = startFrom
                        timerEnd = Date().addingTimeInterval(TimeInterval(startFrom))
                        isTimerRunning = true
                        HapticService.medium()
                        SoundService.tap()
                    }
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color("AppPrimary"))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color("AppSurface").opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func resetStepTimer() {
        isTimerRunning = false
        timerEnd = nil
        remainingSeconds = 0
    }

    private func formatTime(_ total: Int) -> String {
        String(format: "%02d:%02d", total / 60, total % 60)
    }
}
