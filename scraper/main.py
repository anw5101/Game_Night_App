import json
import os
from datetime import datetime, timezone

# Sample data for testing the frontend without actually running full scrapes on every run.
SAMPLE_EVENTS = {
    "last_updated": datetime.now(timezone.utc).isoformat(),
    "events": [
        {
            "id": "1",
            "name": "Geeks Who Drink Trivia",
            "type": "Trivia",
            "venue": "The Local Pub",
            "location": {"lat": 39.8283, "lng": -98.5795},
            "day": "Tuesday",
            "time": "19:00",
            "url": "https://www.geekswhodrink.com"
        },
        {
            "id": "2",
            "name": "Music Bingo Night",
            "type": "Music Bingo",
            "venue": "Downtown Brewery",
            "location": {"lat": 39.8500, "lng": -98.5000},
            "day": "Wednesday",
            "time": "20:00",
            "url": "https://singo.com"
        },
        {
            "id": "3",
            "name": "Friday Karaoke",
            "type": "Karaoke",
            "venue": "Karaoke Box",
            "location": {"lat": 39.8000, "lng": -98.6000},
            "day": "Friday",
            "time": "21:00",
            "url": "https://facebook.com/events/123"
        }
    ]
}

def main():
    print("Running scraper...")
    # TODO: Implement actual Playwright/BeautifulSoup scraping logic for:
    # 1. Geeks Who Drink
    # 2. Singo
    # 3. Facebook public events
    
    # For now, generate the dummy JSON to build out the frontend
    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web", "public", "data")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "events.json")
    
    with open(output_file, "w") as f:
        json.dump(SAMPLE_EVENTS, f, indent=4)
        
    print(f"Successfully wrote {len(SAMPLE_EVENTS['events'])} events to {output_file}")

if __name__ == "__main__":
    main()
