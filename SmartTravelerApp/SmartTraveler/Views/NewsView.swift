import SwiftUI

struct NewsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService
    @StateObject private var newsService = NewsService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ST.Spacing.l) {
                    if locationService.currentCity.isEmpty {
                        emptyState
                    } else if newsService.isLoading && newsService.articles.isEmpty {
                        loadingState
                    } else if newsService.articles.isEmpty {
                        noNewsState
                    } else {
                        newsList
                    }
                }
                .padding(.horizontal, ST.Spacing.m)
                .padding(.top, ST.Spacing.s)
            }
            .screenBackground()
            .navigationTitle("Local News")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !locationService.currentCity.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(locationService.currentCity)
                                .font(ST.Font.label())
                        }
                        .foregroundColor(ST.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(ST.Colors.accentTint)
                        .cornerRadius(ST.Radius.pill)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refreshNews() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
            .onChange(of: locationService.currentCity) { _, newCity in
                if !newCity.isEmpty {
                    refreshNews()
                }
            }
            .onAppear {
                if newsService.articles.isEmpty && !locationService.currentCity.isEmpty {
                    refreshNews()
                }
            }
        }
    }

    // MARK: - Components

    private var emptyState: some View {
        VStack(spacing: ST.Spacing.m) {
            Spacer().frame(height: 60)
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundColor(ST.Colors.accent)
                .frame(width: 80, height: 80)
                .background(ST.Colors.accentTint)
                .cornerRadius(40)

            Text("Waiting for location")
                .font(ST.Font.heading())
                .foregroundColor(ST.Colors.textPrimary)

            Text("Local news will appear once your location is detected")
                .font(ST.Font.body())
                .foregroundColor(ST.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: ST.Spacing.m) {
            Spacer().frame(height: 60)
            ProgressView()
                .tint(ST.Colors.accent)
                .scaleEffect(1.2)
            Text("Fetching local news...")
                .font(ST.Font.body())
                .foregroundColor(ST.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var noNewsState: some View {
        VStack(spacing: ST.Spacing.m) {
            Spacer().frame(height: 60)
            Image(systemName: "newspaper")
                .font(.system(size: 40))
                .foregroundColor(ST.Colors.textTertiary)

            Text("No news found")
                .font(ST.Font.heading())
                .foregroundColor(ST.Colors.textPrimary)

            Text("No recent news for \(locationService.currentCity)")
                .font(ST.Font.body())
                .foregroundColor(ST.Colors.textSecondary)

            GhostButton("Retry", icon: "arrow.clockwise") {
                refreshNews()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var newsList: some View {
        LazyVStack(spacing: ST.Spacing.s) {
            ForEach(newsService.articles) { article in
                newsCard(article)
            }
        }
    }

    private func newsCard(_ article: NewsItem) -> some View {
        Button(action: {
            if let url = URL(string: article.link) {
                UIApplication.shared.open(url)
            }
        }) {
            CardView {
                VStack(alignment: .leading, spacing: ST.Spacing.s) {
                    // Source and date
                    HStack {
                        if !article.source.isEmpty {
                            Text(article.source)
                                .font(ST.Font.label())
                                .foregroundColor(ST.Colors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ST.Colors.accentTint)
                                .cornerRadius(ST.Radius.pill)
                        }

                        Spacer()

                        if let date = article.pubDate {
                            Text(relativeDate(date))
                                .font(ST.Font.label())
                                .foregroundColor(ST.Colors.textTertiary)
                        }
                    }

                    // Title
                    Text(article.title)
                        .font(ST.Font.heading(15))
                        .foregroundColor(ST.Colors.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Description
                    if !article.description.isEmpty {
                        Text(article.description)
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    // External link indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Read more")
                            .font(ST.Font.label())
                    }
                    .foregroundColor(ST.Colors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func refreshNews() {
        newsService.fetchNews(
            for: locationService.currentCity,
            countryCode: locationService.currentCountryCode
        )
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
