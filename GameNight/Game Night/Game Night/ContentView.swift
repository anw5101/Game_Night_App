import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var eventScraper: EventScraper

    @State private var selectedTypes: Set<GameType> = [.trivia, .musicBingo, .karaoke, .themedNights]
    @State private var radiusMiles: Double = 10
    @State private var showLogin = false
    @State private var showFavorites = false
    @State private var selectedEvent: Event? = nil
    @State private var showSignOutAlert = false
    @State private var viewMode: ViewMode = .map
    @State private var locationQuery = ""
    @State private var isSearchingLocation = false
    @State private var mapCenter: CLLocation? = nil
    @State private var searchErrorMessage: String? = nil
    @State private var selectedDate = Date()
    @State private var dateFilterMode: DateFilterMode = .allUpcoming
    @State private var dateRangeStart = Date()
    @State private var dateRangeEnd = Date().addingTimeInterval(3600 * 24 * 30) // 1 month by default

    enum ViewMode {
        case map
        case list
    }

    enum DateFilterMode {
        case allUpcoming
        case specificDate
        case dateRange
    }

    private var filteredEvents: [Event] {
        let referenceLocation = mapCenter ?? locationManager.userLocation
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        return eventScraper.events.filter { event in
            guard selectedTypes.contains(event.gameType) &&
                  event.isWithin(radiusMiles: radiusMiles, from: referenceLocation) else {
                return false
            }
            
            switch dateFilterMode {
            case .allUpcoming:
                return event.startDate >= todayStart
            case .specificDate:
                return Calendar.current.isDate(event.startDate, inSameDayAs: selectedDate)
            case .dateRange:
                let start = Calendar.current.startOfDay(for: dateRangeStart)
                let end = Calendar.current.startOfDay(for: dateRangeEnd).addingTimeInterval(3600 * 24 - 1)
                return event.startDate >= start && event.startDate <= end
            }
        }
    }

    private var sortedEvents: [Event] {
        let referenceLocation = mapCenter ?? locationManager.userLocation
        return filteredEvents.sorted { event1, event2 in
            let dist1 = event1.distance(from: referenceLocation) ?? Double.infinity
            let dist2 = event2.distance(from: referenceLocation) ?? Double.infinity
            return dist1 < dist2
        }
    }

    private var lastVerifiedText: String {
        guard let mostRecent = filteredEvents.map({ $0.lastVerified }).max() else {
            return "No verified events yet"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Last verified: \(formatter.localizedString(for: mostRecent, relativeTo: Date()))"
    }

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            return formatter.string(from: selectedDate)
        }
    }

    private var emptyEventsMessage: String {
        switch dateFilterMode {
        case .allUpcoming:
            return "No upcoming events found."
        case .specificDate:
            return "No events found on this date."
        case .dateRange:
            return "No events found in this date range."
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            if viewMode == .map {
                MapView(events: filteredEvents, mapCenter: mapCenter ?? locationManager.userLocation, radiusMiles: radiusMiles, selectedEvent: $selectedEvent)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Proximity List View
                ScrollView {
                    VStack(spacing: 16) {
                        // Top padding to sit below headerBar
                        Color.clear.frame(height: 125)
                        
                        if sortedEvents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No local bar events found nearby.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Try widening your search radius or typing in another city!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.horizontal)
                        } else {
                            ForEach(sortedEvents) { event in
                                Button(action: { selectedEvent = event }) {
                                    HStack(spacing: 14) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(event.gameType.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(event.gameType.color)
                                                    .clipShape(Capsule())
                                                
                                                Spacer()
                                                
                                                if let distance = event.distance(from: mapCenter ?? locationManager.userLocation) {
                                                    Text(String(format: "%.1f mi", distance / 1609.34))
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Text(event.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text(event.venueName)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                            
                                            if let address = event.address {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Bottom padding to sit above radius/searchCard
                        Color.clear.frame(height: 180)
                    }
                    .padding(.horizontal)
                }
                .background(Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.all)
            }

            // Bottom controls (Filter bar and Search card)
            VStack(spacing: 14) {
                Spacer()
                FilterBar(selectedTypes: $selectedTypes)
                searchCard
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            // Top Header Bar (treated as a true sticky opaque header)
            VStack(spacing: 0) {
                Color.clear.frame(height: 50) // Status bar spacer
                headerBar
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                Divider()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.container, edges: .top)
        }
        .task {
            if let location = locationManager.userLocation {
                if mapCenter == nil {
                    mapCenter = location
                }
                await eventScraper.fetchEvents(near: location)
            } else {
                await eventScraper.loadSampleEvents()
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(authManager: authManager)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, favoritesManager: favoritesManager)
        }
        .confirmationDialog("Account", isPresented: $showSignOutAlert, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Signed in as \(authManager.userName ?? "Guest")")
        }
        .onChange(of: authManager.isSignedIn) { isSignedIn in
            if isSignedIn {
                showLogin = false
            }
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let location = newLocation {
                if mapCenter == nil {
                    mapCenter = location
                }
                Task {
                    await eventScraper.fetchEvents(near: location)
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Night")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Discover bar games near you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Picker("View Mode", selection: $viewMode) {
                Image(systemName: "map").tag(ViewMode.map)
                Image(systemName: "list.bullet").tag(ViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 90)
            
            Button(action: { showFavorites.toggle() }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView(favoritesManager: favoritesManager, eventScraper: eventScraper) { event in
                    showFavorites = false
                    selectedEvent = event
                }
            }
            Button(action: {
                if authManager.isSignedIn {
                    showSignOutAlert = true
                } else {
                    showLogin = true
                }
            }) {
                Image(systemName: authManager.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle")
                    .font(.title2)
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
        }
        .foregroundColor(.primary)
    }

    private var searchCard: some View {
        VStack(spacing: 16) {
            // Geocoding Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search address, city, or zip...", text: $locationQuery, onCommit: executeLocationSearch)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !locationQuery.isEmpty {
                    Button(action: {
                        locationQuery = ""
                        searchErrorMessage = nil
                        if let location = locationManager.userLocation {
                            mapCenter = location
                            Task { await eventScraper.fetchEvents(near: location) }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                if isSearchingLocation {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Button("Search") {
                        executeLocationSearch()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .padding(10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 1)

            if let errorMsg = searchErrorMessage {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Radius")
                        .font(.headline)
                    Text("\(Int(radiusMiles)) miles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(lastVerifiedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: $radiusMiles, in: 2...25, step: 1)
                .accentColor(.blue)
                .padding(.horizontal, -8)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Date Filter")
                        .font(.headline)
                    Spacer()
                    Picker("Date Mode", selection: $dateFilterMode) {
                        Text("All").tag(DateFilterMode.allUpcoming)
                        Text("Single").tag(DateFilterMode.specificDate)
                        Text("Range").tag(DateFilterMode.dateRange)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                if dateFilterMode == .specificDate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Date")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(formattedSelectedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .accentColor(.blue)
                    }
                    .padding(.top, 4)
                } else if dateFilterMode == .dateRange {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Start Date")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            DatePicker("", selection: $dateRangeStart, displayedComponents: .date)
                                .labelsHidden()
                                .accentColor(.blue)
                        }
                        HStack {
                            Text("End Date")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            DatePicker("", selection: $dateRangeEnd, in: dateRangeStart..., displayedComponents: .date)
                                .labelsHidden()
                                .accentColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            if filteredEvents.isEmpty {
                Text(emptyEventsMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 8)
    }

    private func executeLocationSearch() {
        guard !locationQuery.isEmpty else { return }
        isSearchingLocation = true
        searchErrorMessage = nil
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationQuery) { placemarks, error in
            isSearchingLocation = false
            if let error = error {
                print("Geocoding failed: \(error.localizedDescription)")
                searchErrorMessage = "Location not found. Try another city or zip code."
                return
            }
            guard let location = placemarks?.first?.location else { return }
            
            // Set search mapCenter focus and trigger events scrape loader
            mapCenter = location
            Task {
                await eventScraper.fetchEvents(near: location)
            }
        }
    }
}

struct EventDetailView: View {
    let event: Event
    @ObservedObject var favoritesManager: FavoritesManager
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(event.gameType.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(event.gameType.color)
                    .clipShape(Capsule())

                Spacer()

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                    Text(event.venueName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                if let address = event.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 22)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Date & Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedDate(event.startDate))
                            .font(.subheadline)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Freshness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Verified \(formattedRelativeDate(event.lastVerified))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer(minLength: 10)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: { favoritesManager.toggleFavorite(eventID: event.id) }) {
                        Image(systemName: favoritesManager.isFavorite(eventID: event.id) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(.pink)
                            .padding(14)
                            .background(Color.pink.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Link(destination: URL(string: "http://maps.apple.com/?daddr=\(event.latitude),\(event.longitude)&q=\(event.venueName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        HStack {
                            Image(systemName: "map")
                            Text("Get Directions")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                HStack(spacing: 12) {
                    if let website = event.url {
                        Link(destination: website) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Venue Website")
                                    .font(.headline)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    
                    if let source = event.sourceUrl {
                        Link(destination: source) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("Event Source")
                                    .font(.headline)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .presentationDetents([.fraction(0.48), .medium])
        .presentationDragIndicator(.visible)
    }



    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var eventScraper: EventScraper
    @Environment(\.presentationMode) private var presentationMode
    var onSelect: (Event) -> Void

    var favoriteEvents: [Event] {
        eventScraper.events.filter { favoritesManager.isFavorite(eventID: $0.id) }
    }

    var body: some View {
        NavigationView {
            List {
                if favoriteEvents.isEmpty {
                    Text("No favorites saved yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(favoriteEvents) { event in
                        Button(action: { onSelect(event) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(event.venueName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onDelete(perform: deleteFavorite)
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
    }

    private func deleteFavorite(at offsets: IndexSet) {
        offsets.map { favoriteEvents[$0] }.forEach { event in
            favoritesManager.toggleFavorite(eventID: event.id)
        }
    }
}

extension GameType {
    var color: Color {
        switch self {
        case .trivia: return .purple
        case .musicBingo: return .orange
        case .karaoke: return .pink
        case .themedNights: return .blue
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            locationManager: LocationManager(),
            favoritesManager: FavoritesManager(),
            authManager: AuthManager(),
            eventScraper: EventScraper()
        )
    }
}
