import json
import os
import time
import requests
import urllib.parse
from datetime import datetime, timezone
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def geocode_address(address):
    try:
        time.sleep(1) # Rate limit Nominatim
        url = "https://nominatim.openstreetmap.org/search"
        headers = {"User-Agent": "QuestFinder/1.0"}
        params = {"q": address, "format": "json", "limit": 1}
        response = requests.get(url, headers=headers, params=params)
        data = response.json()
        if data:
            return {"lat": float(data[0]["lat"]), "lng": float(data[0]["lon"])}
    except Exception as e:
        print(f"Geocoding failed for {address}: {e}")
    return None

def scrape_gwd(page):
    print("Scraping Geeks Who Drink...")
    events = []
    page.goto("https://www.geekswhodrink.com/venues/", wait_until="networkidle")
    page.wait_for_timeout(3000)
    soup = BeautifulSoup(page.content(), "html.parser")
    
    blocks = soup.find_all("a", class_="quizBlock")
    for block in blocks:
        try:
            lat = block.get("data-lat")
            lon = block.get("data-lon")
            if not lat or not lon: continue
            
            title = block.get("data-title", "GWD Trivia")
            day = block.get("data-day", "Unknown")
            time_tag = block.find("span", class_="time-moment")
            time_str = time_tag.text if time_tag else "7:00 PM"
            url = block.get("href", "https://www.geekswhodrink.com")
            
            events.append({
                "id": f"gwd-{block.get('id', len(events))}",
                "name": title,
                "type": "Trivia",
                "venue": title.split(" at ")[-1] if " at " in title else title,
                "location": {"lat": float(lat), "lng": float(lon)},
                "day": day,
                "time": time_str,
                "url": url
            })
        except Exception:
            continue
    print(f"Found {len(events)} GWD events.")
    return events

def scrape_singo(page):
    print("Scraping Singo...")
    events = []
    page.goto("https://challengeentertainment.com/find-a-game/", wait_until="networkidle")
    page.wait_for_timeout(3000)
    soup = BeautifulSoup(page.content(), "html.parser")
    
    cards = soup.find_all("div", class_="ntl-card")
    for card in cards[:10]: # Limiting for geocoding
        try:
            title_elem = card.find("div", class_="ntl-card-title")
            title = title_elem.text if title_elem else "Singo"
            venue_elem = card.find("span", class_="ntl-card-venue")
            venue = venue_elem.text if venue_elem else "Unknown"
            address_elem = card.find("div", class_="ntl-card-address")
            address = address_elem.text if address_elem else ""
            schedule_elem = card.find("div", class_="ntl-card-schedule")
            schedule = schedule_elem.text if schedule_elem else "Unknown"
            url = card.get("data-permalink", "https://challengeentertainment.com/")
            
            game_type = "Music Bingo" if "singo" in title.lower() else "Trivia"
            if address:
                loc = geocode_address(address)
                if loc:
                    events.append({
                        "id": f"singo-{len(events)}",
                        "name": f"{title} at {venue}",
                        "type": game_type,
                        "venue": venue,
                        "location": loc,
                        "day": schedule.split(",")[0] if "," in schedule else schedule,
                        "time": schedule.split(",")[-1].strip() if "," in schedule else schedule,
                        "url": url
                    })
        except Exception:
            continue
    print(f"Found {len(events)} Singo events.")
    return events

# --- Facebook Strategy 1: Dummy Account ---
def fb_strategy_dummy_account(page):
    events = []
    fb_user = os.environ.get("FB_USER")
    fb_pass = os.environ.get("FB_PASS")
    if not fb_user or not fb_pass:
        print("Skipping FB Dummy Account strategy (credentials not provided in ENV).")
        return events
        
    print("Executing FB Dummy Account strategy...")
    try:
        page.goto("https://www.facebook.com/")
        page.fill("input[name='email']", fb_user)
        page.fill("input[name='pass']", fb_pass)
        page.click("button[name='login']")
        page.wait_for_timeout(5000)
        
        page.goto("https://www.facebook.com/events/search/?q=trivia")
        page.wait_for_timeout(4000)
        soup = BeautifulSoup(page.content(), "html.parser")
        links = soup.find_all("a", href=True)
        for a in links:
            if "/events/" in a["href"] and "search" not in a["href"]:
                event_id = a["href"].split("/events/")[1].split("/")[0]
                if event_id.isdigit():
                    events.append({
                        "id": f"fb-auth-{event_id}",
                        "name": f"Facebook Trivia ({event_id})",
                        "type": "Trivia",
                        "venue": "Check FB",
                        "location": {"lat": 39.8283, "lng": -98.5795}, # Placeholder
                        "day": "Varies",
                        "time": "Varies",
                        "url": f"https://www.facebook.com/events/{event_id}"
                    })
    except Exception as e:
        print(f"Dummy account scraping failed: {e}")
        
    print(f"Found {len(events)} events via Dummy Account.")
    return events

# --- Facebook Strategy 2: Google Search ---
def fb_strategy_google_search(page):
    print("Executing FB Google Search strategy...")
    events = []
    try:
        page.goto("https://www.google.com/search?q=site:facebook.com/events+trivia+bar")
        page.wait_for_timeout(3000)
        soup = BeautifulSoup(page.content(), "html.parser")
        for a in soup.find_all("a", href=True):
            href = a["href"]
            # Google links sometimes have /url?q=...
            if "/url?q=" in href:
                href = urllib.parse.unquote(href.split("/url?q=")[1].split("&")[0])
            if "facebook.com/events/" in href:
                event_id_parts = href.split("/events/")
                if len(event_id_parts) > 1:
                    event_id = event_id_parts[1].split("/")[0]
                    if event_id.isdigit():
                        events.append({
                            "id": f"fb-google-{event_id}",
                            "name": "FB Event from Google",
                            "type": "Trivia",
                            "venue": "Check Link",
                            "location": {"lat": 39.9, "lng": -98.5}, # Placeholder
                            "day": "Varies",
                            "time": "Varies",
                            "url": href
                        })
    except Exception as e:
        print(f"Google search scraping failed: {e}")
        
    print(f"Found {len(events)} events via Google Search.")
    return events

# --- Facebook Strategy 3: Third Party API (SerpApi) ---
def fb_strategy_serpapi():
    events = []
    api_key = os.environ.get("SERPAPI_KEY")
    if not api_key:
        print("Skipping SerpApi strategy (SERPAPI_KEY not provided in ENV).")
        return events
        
    print("Executing FB SerpApi strategy...")
    try:
        params = {
            "engine": "google_events",
            "q": "trivia night",
            "api_key": api_key
        }
        res = requests.get("https://serpapi.com/search", params=params)
        data = res.json()
        for event in data.get("events_results", []):
            if "facebook.com/events" in event.get("link", ""):
                address = ", ".join(event.get("address", []))
                loc = geocode_address(address) if address else {"lat": 39.8, "lng": -98.5}
                events.append({
                    "id": f"fb-serp-{len(events)}",
                    "name": event.get("title", "FB Event via API"),
                    "type": "Trivia",
                    "venue": event.get("venue", {}).get("name", "Unknown"),
                    "location": loc or {"lat": 39.8, "lng": -98.5},
                    "day": event.get("date", {}).get("when", "Unknown"),
                    "time": "Unknown",
                    "url": event.get("link")
                })
    except Exception as e:
        print(f"SerpApi failed: {e}")
        
    print(f"Found {len(events)} events via SerpApi.")
    return events

def scrape_facebook_strategies(page):
    events = []
    # 1. API Strategy (Most Reliable)
    events.extend(fb_strategy_serpapi())
    # 2. Dummy Account Strategy (Playwright Authenticated)
    events.extend(fb_strategy_dummy_account(page))
    # 3. Google Search Strategy (Playwright Unauthenticated Fallback)
    events.extend(fb_strategy_google_search(page))
    
    # Deduplicate by URL
    unique_events = {e["url"]: e for e in events}.values()
    return list(unique_events)

def main():
    print("Starting Web Scraper...")
    all_events = []
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        )
        page = context.new_page()
        
        all_events.extend(scrape_gwd(page))
        all_events.extend(scrape_singo(page))
        all_events.extend(scrape_facebook_strategies(page))
        
        browser.close()
    
    output_data = {
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "events": all_events
    }
    
    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web", "public", "data")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "events.json")
    
    with open(output_file, "w") as f:
        json.dump(output_data, f, indent=4)
        
    print(f"Successfully wrote {len(all_events)} total events to {output_file}")

if __name__ == "__main__":
    main()
