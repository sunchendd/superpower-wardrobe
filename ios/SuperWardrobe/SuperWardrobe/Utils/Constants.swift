import Foundation

enum Constants {
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    static let fashionCLIPBaseURL = "http://localhost:8000"
    static let openWeatherAPIKey = "YOUR_OPENWEATHER_KEY"

    enum Storage {
        static let clothingBucket = "clothing-images"
        static let avatarBucket = "avatars"
        static let diaryBucket = "diary-photos"
    }

    enum Defaults {
        static let pageSize = 20
        static let imageCompressionQuality: CGFloat = 0.8
        static let maxImageDimension: CGFloat = 1024
    }
}
