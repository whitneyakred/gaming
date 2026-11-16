import { chromium } from "playwright";
const browser = await chromium.launch({
  executablePath: "C:/Program Files/Google/Chrome/Application/chrome.exe",
  headless: true,
  args: [
    "--enable-webgl",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
page.on("console", (m) => {
  if (
    m.type() === "error" ||
    m.text().includes("ERROR") ||
    m.text().includes("Godot")
  )
    console.log(m.type(), m.text());
});
page.on("pageerror", (e) => console.log("PAGE_ERROR", e.message));
await page.goto("http://127.0.0.1:8787/", { waitUntil: "networkidle" });
await page.screenshot({ path: "../.godot/website-home.png", fullPage: true });
await page.getByRole("link", { name: "PLAY FREE" }).click();
await page.waitForTimeout(20000);
await page.screenshot({ path: "../.godot/browser-title.png" });
console.log("TITLE", await page.title(), "URL", page.url());
await browser.close();
