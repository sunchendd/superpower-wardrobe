import Foundation

@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var diaryEntries: [OutfitDiary] = []
    var travelPlans: [TravelPlan] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    func loadProfile() async {
        guard let userId = await service.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            profile = try await service.fetchUserProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDiary(month: Date) async {
        guard let userId = await service.currentUserId else { return }
        do {
            diaryEntries = try await service.fetchOutfitDiary(userId: userId, month: month)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDiaryEntry(_ entry: OutfitDiary) async {
        do {
            try await service.saveOutfitDiary(entry)
            if let index = diaryEntries.firstIndex(where: { $0.id == entry.id }) {
                diaryEntries[index] = entry
            } else {
                diaryEntries.insert(entry, at: 0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTravelPlans() async {
        guard let userId = await service.currentUserId else { return }
        do {
            travelPlans = try await service.fetchTravelPlans(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTravelPlan(_ plan: TravelPlan) async {
        do {
            try await service.createTravelPlan(plan)
            travelPlans.insert(plan, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(_ updatedProfile: UserProfile) async {
        do {
            try await service.updateUserProfile(updatedProfile)
            profile = updatedProfile
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
