import { chromium } from "playwright";
const browser = await chromium.launch({
  executablePath: "C:/Program Files/Google/Chrome/Application/chrome.exe",
  headless: true,
  args: [
    "--enable-webgl",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
    "--disable-background-timer-throttling",
    "--disable-renderer-backgrounding",
  ],
});
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
});
const page = await context.newPage();
page.on("console", (m) => {
  if (m.type() === "error" || m.text().includes("ERROR"))
    console.log("CONSOLE", m.text());
});
page.on("pageerror", (e) => console.log("PAGE_ERROR", e.message));
await page.goto("http://127.0.0.1:8787/play/");
await page.waitForTimeout(15000);
await page.mouse.click(680, 260);
await page.waitForTimeout(2000);
await page.screenshot({ path: "../.godot/browser-crews.png" });
await page.mouse.click(430, 177);
await page.waitForTimeout(500);
await page.screenshot({ path: "../.godot/browser-host-form.png" });
await browser.close();
