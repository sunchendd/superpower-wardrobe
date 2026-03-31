import Foundation

@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var diaryEntries: [OutfitDiary] = []
    var travelPlans: [TravelPlan] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service = LocalDataService.shared

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        profile = service.fetchUserProfile()
    }

    func loadDiary(month: Date) async {
        diaryEntries = service.fetchOutfitDiary(month: month)
    }

    func saveDiaryEntry(_ entry: OutfitDiary) async {
        service.saveOutfitDiary(entry)
        if let index = diaryEntries.firstIndex(where: { $0.id == entry.id }) {
            diaryEntries[index] = entry
        } else {
            diaryEntries.insert(entry, at: 0)
        }
    }

    func loadTravelPlans() async {
        travelPlans = service.fetchTravelPlans()
    }

    func createTravelPlan(_ plan: TravelPlan) async {
        service.createTravelPlan(plan)
        travelPlans.insert(plan, at: 0)
    }

    func updateProfile(_ updatedProfile: UserProfile) async {
        service.updateUserProfile(updatedProfile)
        profile = updatedProfile
    }
}
