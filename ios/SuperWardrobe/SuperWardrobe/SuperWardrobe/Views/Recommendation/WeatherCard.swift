import SwiftUI

struct WeatherCard: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(weather.weatherEmoji)
                    .font(.system(size: 48))
                Text(weather.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(weather.temperatureFormatted)
                    .font(.system(size: 42, weight: .thin, design: .rounded))

                HStack(spacing: 12) {
                    Label("\(weather.humidity)%", systemImage: "humidity")
                        .font(.caption)
                    Label(String(format: "%.0fm/s", weather.windSpeed), systemImage: "wind")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    WeatherCard(weather: WeatherData(
        temperature: 22,
        condition: "Clear",
        icon: "01d",
        humidity: 65,
        windSpeed: 3.5,
        description: "晴朗"
    ))
    .padding()
}
