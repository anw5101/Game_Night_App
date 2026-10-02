from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://www.google.com/search?q=site:facebook.com/events+trivia")
    page.wait_for_timeout(3000)
    
    html = page.content()
    with open("google_dump.html", "w") as f:
        f.write(html)
        
    print("Dumped Google HTML.")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
