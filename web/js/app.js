// Initialize Map (defaulting to a central US location for now)
const map = L.map('map').setView([39.8283, -98.5795], 4);

// Set up OpenStreetMap tiles
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
}).addTo(map);

let currentPos = null;
let radiusCircle = null;
let allEvents = [];
let eventMarkers = [];

// Request user location
map.locate({setView: true, maxZoom: 12});

map.on('locationfound', function(e) {
    currentPos = e.latlng;
    
    // Custom user marker
    const userIcon = L.divIcon({
        className: 'user-marker',
        html: '<div style="background-color: blue; width: 12px; height: 12px; border-radius: 50%; border: 2px solid white;"></div>',
        iconSize: [16, 16]
    });
    
    L.marker(e.latlng, {icon: userIcon}).addTo(map).bindPopup("You are here").openPopup();
    
    updateRadiusCircle();
    renderMarkers();
});

map.on('locationerror', function(e) {
    console.warn("Location access denied or unavailable. Using default map center.");
    renderMarkers();
});

function updateRadiusCircle() {
    if (!currentPos) return;
    
    const radiusMiles = document.getElementById('radius-slider').value;
    const radiusMeters = radiusMiles * 1609.34;
    
    if (radiusCircle) {
        map.removeLayer(radiusCircle);
    }
    
    radiusCircle = L.circle(currentPos, {
        color: 'blue',
        fillColor: '#30f',
        fillOpacity: 0.1,
        radius: radiusMeters
    }).addTo(map);
}

// Update radius display and map when slider changes
document.getElementById('radius-slider').addEventListener('input', function(e) {
    document.getElementById('radius-value').innerText = e.target.value;
    updateRadiusCircle();
    renderMarkers();
});

// Update markers when filters change
document.querySelectorAll('.game-filter').forEach(checkbox => {
    checkbox.addEventListener('change', renderMarkers);
});

// Fetch events data
fetch('public/data/events.json')
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        const lastUpdated = new Date(data.last_updated).toLocaleString();
        document.getElementById('last-verified').innerText = `Last Verified: ${lastUpdated}`;
        allEvents = data.events;
        renderMarkers();
    })
    .catch(error => {
        console.error("Error fetching events:", error);
        document.getElementById('last-verified').innerText = `Last Verified: Error loading data`;
    });

function renderMarkers() {
    // Clear existing markers
    eventMarkers.forEach(marker => map.removeLayer(marker));
    eventMarkers = [];
    
    // Get active filters
    const activeTypes = Array.from(document.querySelectorAll('.game-filter:checked')).map(cb => cb.value);
    const radiusMiles = document.getElementById('radius-slider').value;
    const radiusMeters = radiusMiles * 1609.34;
    
    allEvents.forEach(event => {
        // Filter by type
        if (!activeTypes.includes(event.type)) return;
        
        const eventPos = L.latLng(event.location.lat, event.location.lng);
        
        // Filter by radius (if user location is known)
        if (currentPos) {
            const distance = currentPos.distanceTo(eventPos);
            if (distance > radiusMeters) return;
        }
        
        // Add marker
        const marker = L.marker(eventPos).addTo(map);
        marker.bindPopup(`
            <b>${event.name}</b><br>
            <i>${event.type}</i><br>
            ${event.venue}<br>
            ${event.day} at ${event.time}<br>
            <a href="${event.url}" target="_blank">More Info</a>
        `);
        eventMarkers.push(marker);
    });
}
