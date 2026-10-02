from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    
    def handle_response(response):
        if "json" in response.headers.get("content-type", "") and "venues" in response.url.lower():
            print(f"Found API URL: {response.url}")
            
    page.on("response", handle_response)
    print("Navigating to GWD...")
    page.goto("https://www.geekswhodrink.com/venues/", wait_until="networkidle")
    print("Done navigating.")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
