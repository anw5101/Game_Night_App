from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://challengeentertainment.com/find-a-game/")
    page.wait_for_timeout(3000)
    print(page.title())
    
    html = page.content()
    with open("singo_dump.html", "w") as f:
        f.write(html)
    
    print("Dumped HTML to singo_dump.html")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
