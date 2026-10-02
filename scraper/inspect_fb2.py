from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://www.facebook.com/events/search/?q=trivia")
    page.wait_for_timeout(3000)
    with open("fb_dump.html", "w") as f:
        f.write(page.content())
    print("Dumped FB HTML.")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
