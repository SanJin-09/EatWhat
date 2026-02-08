import Testing
@testable import CoreDomain

@Test
func moduleNameNotEmpty() {
    #expect(!CoreDomainModule.name.isEmpty)
}

@Test
func autoMealTypeResolverReturnsExpectedWindowValues() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let resolver = AutoMealTypeResolver(calendar: calendar)

    #expect(resolver.resolve(date: makeDate("2026-02-08 07:45", calendar: calendar)) == .breakfast)
    #expect(resolver.resolve(date: makeDate("2026-02-08 12:15", calendar: calendar)) == .lunch)
    #expect(resolver.resolve(date: makeDate("2026-02-08 18:40", calendar: calendar)) == .dinner)
}

@Test
func autoMealTypeResolverReturnsNearestAnchorOutsideMainWindows() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let resolver = AutoMealTypeResolver(calendar: calendar)

    #expect(resolver.resolve(date: makeDate("2026-02-08 10:05", calendar: calendar)) == .lunch)
    #expect(resolver.resolve(date: makeDate("2026-02-08 15:20", calendar: calendar)) == .lunch)
    #expect(resolver.resolve(date: makeDate("2026-02-08 23:55", calendar: calendar)) == .dinner)
    #expect(resolver.resolve(date: makeDate("2026-02-08 02:20", calendar: calendar)) == .dinner)
}

private func makeDate(_ value: String, calendar: Calendar) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: value)!
}
