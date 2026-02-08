import Foundation

public struct AutoMealTypeResolver: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func resolve(date: Date) -> MealType {
        if isInWindow(date: date, startHour: 5, startMinute: 0, endHour: 9, endMinute: 30) {
            return .breakfast
        }

        if isInWindow(date: date, startHour: 10, startMinute: 30, endHour: 14, endMinute: 0) {
            return .lunch
        }

        if isInWindow(date: date, startHour: 16, startMinute: 30, endHour: 21, endMinute: 0) {
            return .dinner
        }

        return nearestAnchorMeal(for: date)
    }

    private func isInWindow(
        date: Date,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Bool {
        guard
            let start = dateBySetting(dayOffset: 0, hour: startHour, minute: startMinute, on: date),
            let end = dateBySetting(dayOffset: 0, hour: endHour, minute: endMinute, on: date)
        else {
            return false
        }

        return date >= start && date <= end
    }

    private func nearestAnchorMeal(for date: Date) -> MealType {
        var candidates: [(mealType: MealType, anchor: Date)] = []
        for dayOffset in -1...1 {
            if let breakfastAnchor = dateBySetting(dayOffset: dayOffset, hour: 7, minute: 30, on: date) {
                candidates.append((.breakfast, breakfastAnchor))
            }
            if let lunchAnchor = dateBySetting(dayOffset: dayOffset, hour: 12, minute: 0, on: date) {
                candidates.append((.lunch, lunchAnchor))
            }
            if let dinnerAnchor = dateBySetting(dayOffset: dayOffset, hour: 18, minute: 30, on: date) {
                candidates.append((.dinner, dinnerAnchor))
            }
        }

        return candidates.min { lhs, rhs in
            abs(lhs.anchor.timeIntervalSince(date)) < abs(rhs.anchor.timeIntervalSince(date))
        }?.mealType ?? .lunch
    }

    private func dateBySetting(dayOffset: Int, hour: Int, minute: Int, on base: Date) -> Date? {
        guard
            let baseDay = calendar.date(byAdding: .day, value: dayOffset, to: base),
            let dayStart = calendar.dateInterval(of: .day, for: baseDay)?.start
        else {
            return nil
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart)
    }
}
