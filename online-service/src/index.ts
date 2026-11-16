import { DurableObject } from "cloudflare:workers";
type Listing = {
  id: string;
  title: string;
  count: number;
  locked: boolean;
  protocol: string;
  expires: number;
};
type Room = {
  id: string;
  title: string;
  password: string;
  protocol: string;
  nextPeer: number;
  ended?: boolean;
};
type Session = {
  leaveKey?: string;
  departed?: boolean;
  peer: number;
  identity: string;
  lastSeen: number;
  window: number;
  packets: number;
  bytes: number;
};
type Ticket = { peer: number; identity: string; expires: number };
const encoder = new TextEncoder();
const error = (message: string, status = 400) =>
  Response.json(
    { error: message },
    { status, headers: { "Cache-Control": "no-store" } },
  );
async function hash(value: string): Promise<string> {
  return [
    ...new Uint8Array(
      await crypto.subtle.digest("SHA-256", encoder.encode(value)),
    ),
  ]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
const validId = (v: string) => /^[a-f0-9-]{36}$/.test(v);
const shard = (id: string) => String(parseInt(id.slice(0, 2), 16) % 4);
async function body(request: Request): Promise<Record<string, unknown>> {
  if (!request.body) throw Error("Missing request");
  const reader = request.body.getReader();
  let size = 0;
  const chunks: Uint8Array[] = [];
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > 2048) {
        await reader.cancel();
        throw Error("Too large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  const data: unknown = JSON.parse(new TextDecoder().decode(bytes));
  if (!data || typeof data !== "object" || Array.isArray(data))
    throw Error("Invalid request");
  return data as Record<string, unknown>;
}
// Separate per-IP gates never process gameplay packets.
export class RequestGate extends DurableObject<Env> {
  async allow(action: string): Promise<boolean> {
    const period = action === "host" ? 3600000 : 60000;
    const max = action === "host" ? 8 : action === "join" ? 20 : 30;
    return this.ctx.storage.transaction(async (txn) => {
      const old = await txn.get<{ time: number; count: number }>(action);
      const row =
        !old || Date.now() - old.time >= period
          ? { time: Date.now(), count: 0 }
          : old;
      if (row.count >= max) return false;
      row.count++;
      await txn.put(action, row);
      await txn.setAlarm(Date.now() + 3600000);
      return true;
    });
  }
  async alarm() {
    await this.ctx.storage.deleteAll();
  }
}
// Bounded discovery shards; game packets never touch the directory.
export class CrewDirectory extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.ctx.storage.sql.exec(
      "CREATE TABLE IF NOT EXISTS crews(id TEXT PRIMARY KEY,data TEXT NOT NULL,expires INTEGER NOT NULL)",
    );
  }
  async publish(entry: Listing) {
    if (entry.count <= 0) return;
    // A late close callback must never resurrect an ended listing.
    const prior = this.ctx.storage.sql.exec<{data:string,expires:number}>("SELECT data,expires FROM crews WHERE id=?", entry.id).toArray()[0];
    if (prior?.data === "{}" && prior.expires > Date.now()) return;
    this.ctx.storage.sql.exec(
      "DELETE FROM crews WHERE expires < ?",
      Date.now(),
    );
    this.ctx.storage.sql.exec(
      "INSERT OR REPLACE INTO crews VALUES(?,?,?)",
      entry.id,
      JSON.stringify(entry),
      entry.expires,
    );
    await this.ctx.storage.setAlarm(Date.now() + 120000);
  }
  remove(id: string) {
    this.ctx.storage.sql.exec("INSERT OR REPLACE INTO crews VALUES(?,?,?)", id, "{}", Date.now() + 180000);
  }
  list(): Listing[] {
    return this.ctx.storage.sql
      .exec<{ data: string }>(
        "SELECT data FROM crews WHERE expires>? AND data != '{}' AND json_extract(data, '$.count') > 0 ORDER BY id LIMIT 100",
        Date.now(),
      )
      .toArray()
      .map((r) => JSON.parse(r.data) as Listing);
  }
  alarm() {
    this.ctx.storage.sql.exec("DELETE FROM crews WHERE expires<?", Date.now());
  }
}
export class VoyageRoom extends DurableObject<Env> {
  async leaveTicket(value: string): Promise<Response> {
    if (!validId(value)) return error("Invalid departure ticket.", 400);
    const key = await hash(value);
    await this.ctx.storage.delete("ticket:" + key);
    for (const ws of this.sessions()) {
      if ((ws.deserializeAttachment() as Session).leaveKey === key) {
        await this.depart(ws);
        ws.close(1000, "Left voyage");
      }
    }
    return Response.json({ ok: true });
  }
  private sessions() {
    return this.ctx
      .getWebSockets()
      .filter((ws) => ws.readyState === WebSocket.OPEN && !(ws.deserializeAttachment() as Session)?.departed);
  }
  private async ticket(peer: number, identity: string): Promise<string> {
    const value = crypto.randomUUID();
    await this.ctx.storage.put("ticket:" + (await hash(value)), {
      peer,
      identity,
      expires: Date.now() + 30000,
    } satisfies Ticket);
    return value;
  }
  async create(
    id: string,
    title: string,
    password: string,
    identity: string,
    protocol: string,
  ) {
    await this.ctx.storage.put("room", {
      id,
      title,
      password: password ? await hash(id + password) : "",
      protocol,
      nextPeer: 2,
    } satisfies Room);
    await this.ctx.storage.setAlarm(Date.now() + 45000);
    return { id, ticket: await this.ticket(1, identity), identity };
  }
  async reserve(
    password: string,
    identity: string,
    protocol: string,
  ): Promise<Response> {
    const room = await this.ctx.storage.get<Room>("room");
    const sockets = this.sessions();
    if (
      !room || room.ended ||
      !sockets.some((ws) => (ws.deserializeAttachment() as Session).peer === 1)
    )
      return error("This voyage has ended. Refresh the crew list.", 404);
    if (protocol !== room.protocol)
      return error("Update the game to join this voyage.", 409);
    if (
      room.password &&
      !crypto.subtle.timingSafeEqual(
        encoder.encode(await hash(room.id + password)),
        encoder.encode(room.password),
      )
    )
      return error("Incorrect password. Please try again.", 403);
    const value = crypto.randomUUID();
    const key = "ticket:" + (await hash(value));
    return this.ctx.storage.transaction(async (txn) => {
      const current = await txn.get<Room>("room");
      if (!current || current.ended) return error("This voyage has ended.", 404);
      const pending = [
        ...(await txn.list<Ticket>({ prefix: "ticket:" })).values(),
      ].filter((t) => t.expires > Date.now());
      const live = this.sessions();
      if (live.length + pending.length >= 4)
        return error("This crew is full.", 409);
      if (
        live.some(
          (ws) => (ws.deserializeAttachment() as Session).identity === identity,
        ) ||
        pending.some((t) => t.identity === identity)
      )
        return error(
          "Your sailor is already on this voyage. Close the other game tab first.",
          409,
        );
      const peer = current.nextPeer++;
      await txn.put("room", current);
      await txn.put(key, {
        peer,
        identity,
        expires: Date.now() + 30000,
      } satisfies Ticket);
      return Response.json({ id: current.id, ticket: value, identity });
    });
  }
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket")
      return error("WebSocket required.", 426);
    const value = new URL(request.url).searchParams.get("ticket") ?? "";
    if (!validId(value)) return error("Invalid connection ticket.", 403);
    const key = "ticket:" + (await hash(value));
    const ticket = await this.ctx.storage.transaction(async (txn) => {
      const found = await txn.get<Ticket>(key);
      await txn.delete(key);
      return found;
    });
    if (!ticket || ticket.expires <= Date.now())
      return error("Connection expired. Please join again.", 403);
    const room = await this.ctx.storage.get<Room>("room");
    const existing = this.sessions();
    if (
      !room ||
      existing.length >= 4 ||
      (ticket.peer !== 1 &&
        !existing.some(
          (ws) => (ws.deserializeAttachment() as Session).peer === 1,
        ))
    )
      return error("This voyage has ended.", 409);
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [String(ticket.peer)]);
    server.serializeAttachment({
      leaveKey: await hash(value),
      peer: ticket.peer,
      identity: ticket.identity,
      lastSeen: Date.now(),
      window: Date.now(),
      packets: 0,
      bytes: 0,
    } satisfies Session);
    const peers = existing.map((ws) => {
      const data = ws.deserializeAttachment() as Session;
      return { id: data.peer, identity: data.identity };
    });
    server.send(
      JSON.stringify({
        type: "welcome",
        id: ticket.peer,
        identity: ticket.identity,
        peers,
      }),
    );
    for (const ws of existing)
      ws.send(
        JSON.stringify({
          type: "peer_joined",
          id: ticket.peer,
          identity: ticket.identity,
        }),
      );
    await this.publish(room);
    await this.ctx.storage.setAlarm(Date.now() + 30000);
    return new Response(null, { status: 101, webSocket: client });
  }
  private async publish(room: Room) {
    if (room.ended || !this.sessions().some(ws => (ws.deserializeAttachment() as Session).peer === 1)) return;
    await this.env.DIRECTORY.getByName(shard(room.id)).publish({
      id: room.id,
      title: room.title,
      locked: !!room.password,
      count: this.sessions().length,
      protocol: room.protocol,
      expires: Date.now() + 75000,
    });
  }
  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    const session = ws.deserializeAttachment() as Session;
    if (session.departed) return;
    if (Date.now() - session.window > 1000) {
      session.window = Date.now();
      session.packets = 0;
      session.bytes = 0;
    }
    session.packets++;
    session.bytes +=
      typeof message === "string" ? message.length : message.byteLength;
    session.lastSeen = Date.now();
    ws.serializeAttachment(session);
    if (
      session.packets > 180 ||
      session.bytes > (session.peer === 1 ? 1500000 : 80000)
    ) {
      ws.close(1008, "Connection rate exceeded.");
      return;
    }
    if (typeof message === "string") {
      if (message.length > 256) {
        ws.close(1009, "Message too large.");
        return;
      }
      let command: { type?: string; id?: number };
      try {
        command = JSON.parse(message);
      } catch {
        ws.close(1008, "Invalid message.");
        return;
      }
      if (command.type === "heartbeat") {
        ws.send('{"type":"heartbeat"}');
        return;
      }
      if (command.type === "leave") {
        await this.depart(ws);
        ws.close(1000, "Left voyage");
        return;
      }
      if (
        command.type === "kick" &&
        session.peer === 1 &&
        Number.isInteger(command.id) &&
        command.id !== 1
      )
        for (const target of this.ctx.getWebSockets(String(command.id)))
          target.close(1008, "The captain closed your connection.");
      return;
    }
    if (message.byteLength < 12 || message.byteLength > 65548) {
      ws.close(1009, "Invalid packet size.");
      return;
    }
    const header = new DataView(message);
    const target = header.getInt32(4, true);
    if (header.getUint8(8) > 2 || header.getUint8(9) > 2) {
      ws.close(1008, "Invalid packet channel.");
      return;
    }
    // The relay assigns identity: a client cannot forge source or talk to guests.
    header.setInt32(0, session.peer, true);
    if (session.peer !== 1 && target !== 1) {
      ws.close(1008, "Invalid destination.");
      return;
    }
    for (const recipient of this.sessions()) {
      const id = (recipient.deserializeAttachment() as Session).peer;
      if (
        id !== session.peer &&
        (target === 0 || target === id || (target < 0 && id !== -target))
      )
        recipient.send(message);
    }
  }
  async webSocketClose(
    ws: WebSocket,
    _code: number,
    _reason: string,
    _clean: boolean,
  ) {
    await this.depart(ws);
  }
  async webSocketError(ws: WebSocket) {
    ws.close(1011, "Connection interrupted.");
    await this.depart(ws);
  }
  private async depart(ws: WebSocket) {
    const session = ws.deserializeAttachment() as Session | null;
    if (!session || session.departed) return;
    session.departed = true;
    ws.serializeAttachment(session);
    if (session.peer === 1) {
      await this.end();
      return;
    }
    for (const other of this.sessions())
      if (other !== ws)
        other.send(JSON.stringify({ type: "peer_left", id: session.peer }));
    const room = await this.ctx.storage.get<Room>("room");
    if (room) await this.publish(room);
  }
  private async end() {
    const room = await this.ctx.storage.get<Room>("room");
    if (room) { room.ended = true; await this.ctx.storage.put("room", room); }
    for (const socket of this.sessions()) {
      const state = socket.deserializeAttachment() as Session;
      state.departed = true;
      socket.serializeAttachment(state);
      socket.close(1000, "The captain ended this voyage.");
    }
    if (room)
      await this.env.DIRECTORY.getByName(shard(room.id)).remove(room.id);
    await this.ctx.storage.deleteAll();
  }
  async alarm() {
    const room = await this.ctx.storage.get<Room>("room");
    if (!room) return;
    for (const [key, ticket] of await this.ctx.storage.list<Ticket>({
      prefix: "ticket:",
    }))
      if (ticket.expires < Date.now()) await this.ctx.storage.delete(key);
    for (const ws of this.sessions())
      if (Date.now() - (ws.deserializeAttachment() as Session).lastSeen > 60000)
        ws.close(1001, "Connection timed out.");
    if (
      !this.sessions().some(
        (ws) => (ws.deserializeAttachment() as Session).peer === 1,
      )
    ) {
      await this.end();
      return;
    }
    await this.publish(room);
    await this.ctx.storage.setAlarm(Date.now() + 30000);
  }
}
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/play/index.wasm") {
      url.pathname += ".gz";
      const asset = await env.ASSETS.fetch(new Request(url, request));
      const headers = new Headers(asset.headers);
      headers.set("Content-Type", "application/wasm");
      headers.set("Content-Encoding", "gzip");
      headers.set("Cache-Control", "no-cache");
      return new Response(asset.body, {
        status: asset.status,
        headers,
        encodeBody: "manual",
      });
    }
    if (!url.pathname.startsWith("/api/")) return env.ASSETS.fetch(request);
    const origin = request.headers.get("Origin");
    if (origin && origin !== url.origin)
      return error("Use the game's own website to connect.", 403);
    return route(request, env, url).catch(() =>
      error("The harbor is unavailable. Please try again shortly.", 503),
    );
  },
} satisfies ExportedHandler<Env>;
async function route(request: Request, env: Env, url: URL): Promise<Response> {
  if (url.pathname === "/api/health")
    return Response.json({ ok: true, protocol: env.PROTOCOL });
  const parts = url.pathname.split("/").filter(Boolean);
  if (request.method === "POST" && parts.length === 4 && parts[1] === "crews" && validId(parts[2]) && parts[3] === "leave") {
    let data: Record<string, unknown>;
    try { data = await body(request); } catch { return error("Invalid request."); }
    return env.ROOMS.getByName(parts[2]).leaveTicket(String(data.ticket ?? ""));
  }
  if (parts.length === 3 && parts[1] === "socket" && validId(parts[2]))
    return env.ROOMS.getByName(parts[2]).fetch(request);
  const action =
    request.method === "GET" ? "browse" : parts.length === 2 ? "host" : "join";
  if (
    !(await env.GATES.getByName(
      await hash(request.headers.get("CF-Connecting-IP") ?? "local"),
    ).allow(action))
  )
    return error("Too many attempts. Wait a moment and try again.", 429);
  if (request.method === "GET" && url.pathname === "/api/crews") {
    const lists = await Promise.all(
      [0, 1, 2, 3].map((i) => env.DIRECTORY.getByName(String(i)).list()),
    );
    return Response.json(
      { crews: lists.flat().filter((c) => c.protocol === env.PROTOCOL) },
      { headers: { "Cache-Control": "no-store" } },
    );
  }
  if (request.method !== "POST" || parts[1] !== "crews")
    return error("Not found.", 404);
  let data: Record<string, unknown>;
  try {
    data = await body(request);
  } catch {
    return error("Invalid request.");
  }
  if (data.protocol !== env.PROTOCOL)
    return error(
      "This game is out of date. Reload the page or download the latest build.",
      409,
    );
  if (typeof data.token !== "string" || !/^[a-f0-9]{48}$/.test(data.token))
    return error("Invalid sailor identity.");
  if (typeof data.password !== "string" || data.password.length > 64)
    return error("Invalid password.");
  const identity = (await hash(data.token)).slice(0, 48);
  if (parts.length === 2) {
    if (typeof data.title !== "string") return error("Name your voyage first.");
    const title = data.title
      .replace(/[\u0000-\u001f\u007f]/g, "")
      .trim()
      .slice(0, 32);
    if (!title) return error("Name your voyage first.");
    const id = crypto.randomUUID();
    return Response.json(
      await env.ROOMS.getByName(id).create(
        id,
        title,
        data.password,
        identity,
        env.PROTOCOL,
      ),
    );
  }
  if (parts.length === 4 && validId(parts[2]) && parts[3] === "join")
    return env.ROOMS.getByName(parts[2]).reserve(
      data.password,
      identity,
      env.PROTOCOL,
    );
  return error("Not found.", 404);
}
