const { test, expect } = require("@playwright/test");

test.describe("multi-controller quick harness", () => {
  test("spawns requested number of controller frames", async ({ page }) => {
    await page.goto("/controller/multi-controller.html");

    await page.locator("#count").selectOption("4");
    await page.locator("#namePrefix").fill("Alpha");
    await page.locator("#host").fill("ws://127.0.0.1:9080");
    await page.locator("#spawn").click();

    await expect(page.locator(".client")).toHaveCount(4);

    const firstSrc = await page.locator(".client iframe").first().getAttribute("src");
    expect(firstSrc).toContain("name=Alpha1");
    expect(firstSrc).toContain("autoconnect=1");
    expect(firstSrc).toContain("autojoin=1");
  });

  test("controller page hydrates from query params", async ({ page }) => {
    const params = new URLSearchParams({
      host: "ws://127.0.0.1:9080",
      name: "QueryUser",
      avatar: "3",
      debug: "1",
    });

    await page.goto(`/controller/index.html?${params.toString()}`);

    await expect(page.locator("#hostInput")).toHaveValue("ws://127.0.0.1:9080");
    await expect(page.locator("#nameInput")).toHaveValue("QueryUser");
    await expect(page.locator("#avatarInput")).toHaveValue("3");
    await expect(page.locator("#debugToggleBtn")).toContainText("On");
  });
});
