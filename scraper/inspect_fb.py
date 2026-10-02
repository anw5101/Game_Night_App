from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    print("Navigating to Facebook...")
    page.goto("https://www.facebook.com/events/search/?q=trivia")
    page.wait_for_timeout(3000)
    print("Title:", page.title())
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
