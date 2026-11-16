import { chromium } from "playwright";
import assert from "node:assert/strict";
const base = process.env.HARBOR_TEST_URL ?? "http://127.0.0.1:8787";
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
const errors = [];
async function game(name) {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
  });
  const page = await context.newPage();
  page.on("console", (m) => {
    if (m.type() === "error" || m.text().includes("ERROR")) {
      errors.push(m.text());
      console.log("CONSOLE", m.text());
    }
  });
  page.on("pageerror", (e) => {
    errors.push(e.message);
    console.log("PAGE_ERROR", e.message);
  });
  await page.goto(base + "/play/");
  await page.waitForTimeout(16000);
  await page.mouse.click(1060, 540);
  await page.keyboard.press("Control+A");
  await page.keyboard.type(name);
  await page.mouse.click(680, 260);
  await page.waitForTimeout(1000);
  return { context, page };
}
try {
  const host = await game("Web Captain");
  await host.page.mouse.click(450, 180);
  await host.page.waitForTimeout(500);
  await host.page.mouse.click(500, 242);
  await host.page.keyboard.press("Control+A");
  await host.page.keyboard.type("Browser smoke");
  await host.page.mouse.click(640, 394);
  await host.page.waitForTimeout(3500);
  await host.page.screenshot({ path: "../.godot/browser-host-game.png" });
  const list = await (await fetch(base + "/api/crews")).json();
  const room = list.crews.find((c) => c.title === "Browser smoke");
  assert.ok(room, "Browser host appeared in directory");
  console.log("PASS browser host created room");
  const guest = await game("Web Sailor");
  await guest.page.screenshot({ path: "../.godot/browser-guest-list.png" });
  await guest.page.mouse.click(600, 222);
  await guest.page.waitForTimeout(4500);
  await guest.page.screenshot({ path: "../.godot/browser-guest-game.png" });
  const after = await (await fetch(base + "/api/crews")).json();
  assert.equal(
    after.crews.find((c) => c.id === room.id)?.count,
    2,
    "Two browser identities joined",
  );
  console.log("PASS second browser joined");
  await guest.page.keyboard.down("d");
  await guest.page.waitForTimeout(700);
  await guest.page.keyboard.up("d");
  await guest.page.waitForTimeout(500);
  await host.page.screenshot({ path: "../.godot/browser-two-players.png" });
  assert.equal(errors.length, 0, errors.join("\n"));
  console.log("PASS no browser runtime errors");
  await host.context.close();
  await guest.page.waitForTimeout(2000);
  await guest.page.screenshot({ path: "../.godot/browser-host-left.png" });
  console.log("PASS host disconnect delivered");
} finally {
  await browser.close();
}
