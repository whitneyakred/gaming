import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
const base = process.env.HARBOR_TEST_URL ?? "http://127.0.0.1:8787";
const protocol = "holy-ship-coop-9";
const token = () => randomBytes(24).toString("hex");
const delay = (ms) => new Promise((r) => setTimeout(r, ms));
async function api(path, data) {
  const response = await fetch(
    base + path,
    data
      ? {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            protocol,
            token: token(),
            password: "123",
            ...data,
          }),
        }
      : {},
  );
  return { status: response.status, ...(await response.json()) };
}
async function connect(ticket) {
  const ws = new WebSocket(
    base.replace(/^http/, "ws") +
      "/api/socket/" +
      ticket.id +
      "?ticket=" +
      ticket.ticket,
  );
  ws.binaryType = "arraybuffer";
  const messages = [];
  ws.addEventListener("message", (e) =>
    messages.push(typeof e.data === "string" ? JSON.parse(e.data) : e.data),
  );
  const next = async (predicate) => {
    const end = Date.now() + 5000;
    while (Date.now() < end) {
      const index = messages.findIndex(predicate);
      if (index >= 0) return messages.splice(index, 1)[0];
      await delay(10);
    }
    throw Error("Timed out awaiting packet");
  };
  const welcome = await next((m) => m.type === "welcome");
  return { ws, next, welcome };
}
test("Harbor admission, identities, routing, capacity, and cleanup", async (t) => {
  const hostToken = token();
  const room = await api("/api/crews", {
    title: "Service test",
    token: hostToken,
  });
  assert.equal(room.status, 200);
  const host = await connect(room);
  assert.equal(host.welcome.id, 1);
  const clients = [];
  try {
    await t.test(
      "listing shows password protection and occupancy",
      async () => {
        const list = await api("/api/crews");
        const row = list.crews.find((c) => c.id === room.id);
        assert.equal(row.count, 1);
        assert.equal(row.locked, true);
        assert.ok(!("password" in row));
      },
    );
    await t.test("wrong password rejected before connection", async () => {
      assert.equal(
        (await api("/api/crews/" + room.id + "/join", { password: "bad" }))
          .status,
        403,
      );
    });
    await t.test(
      "simultaneous joins receive distinct identities and enforce capacity",
      async () => {
        const tickets = await Promise.all(
          [0, 1, 2, 3].map(() => api("/api/crews/" + room.id + "/join", {})),
        );
        assert.equal(tickets.filter((r) => r.status === 200).length, 3);
        assert.equal(tickets.filter((r) => r.status === 409).length, 1);
        for (const ticket of tickets.filter((r) => r.status === 200))
          clients.push(await connect(ticket));
        assert.equal(new Set(clients.map((c) => c.welcome.id)).size, 3);
      },
    );
    await t.test("relay replaces forged packet sender", async () => {
      const bytes = new ArrayBuffer(16);
      const view = new DataView(bytes);
      view.setInt32(0, 999, true);
      view.setInt32(4, 1, true);
      view.setUint32(12, 12345, true);
      clients[0].ws.send(bytes);
      const packet = await host.next((m) => m instanceof ArrayBuffer);
      assert.equal(
        new DataView(packet).getInt32(0, true),
        clients[0].welcome.id,
      );
      assert.equal(new DataView(packet).getUint32(12, true), 12345);
    });
    await t.test("host can route state to a specific guest", async () => {
      const bytes = new ArrayBuffer(16);
      const view = new DataView(bytes);
      view.setInt32(4, clients[1].welcome.id, true);
      view.setUint32(12, 6789, true);
      host.ws.send(bytes);
      const packet = await clients[1].next((m) => m instanceof ArrayBuffer);
      assert.equal(new DataView(packet).getInt32(0, true), 1);
    });
    await t.test("guest cannot route packets to another guest", async () => {
      const closed = new Promise((resolve) =>
        clients[0].ws.addEventListener("close", resolve, { once: true }),
      );
      const bytes = new ArrayBuffer(12);
      new DataView(bytes).setInt32(4, clients[1].welcome.id, true);
      clients[0].ws.send(bytes);
      const event = await Promise.race([
        closed,
        delay(5000).then(() => {
          throw Error("Guest not closed");
        }),
      ]);
      assert.equal(event.code, 1008);
    });
  } finally {
    host.ws.close();
    for (const client of clients) client.ws.close();
  }
  await t.test("host departure removes crew listing", async () => {
    for (let i = 0; i < 20; i++) {
      const list = await api("/api/crews");
      if (!list.crews.some((c) => c.id === room.id)) return;
      await delay(100);
    }
    assert.fail("Closed room remains listed");
  });
  await t.test("incompatible builds are rejected", async () =>
    assert.equal(
      (await api("/api/crews", { title: "Old", protocol: "old" })).status,
      409,
    ),
  );
  await t.test("cross-origin API calls are rejected", async () =>
    assert.equal(
      (
        await fetch(base + "/api/crews", {
          headers: { Origin: "https://untrusted.example" },
        })
      ).status,
      403,
    ),
  );
});
