from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://www.geekswhodrink.com/venues/")
    page.wait_for_timeout(3000)
    print(page.title())
    
    # Try to find venue cards or elements
    html = page.content()
    with open("gwd_dump.html", "w") as f:
        f.write(html)
    
    print("Dumped HTML to gwd_dump.html")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
