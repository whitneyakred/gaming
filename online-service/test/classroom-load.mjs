// Local-only by default. Explicitly opt in before spending live daily quotas.
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { writeFile } from 'node:fs/promises';
const base = process.env.HARBOR_TEST_URL ?? 'http://127.0.0.1:8787';
if (!['127.0.0.1', 'localhost'].includes(new URL(base).hostname) && process.env.ALLOW_LIVE_LOAD !== 'yes')
  throw Error('Load tests use the local emulator; set ALLOW_LIVE_LOAD=yes explicitly for a live run.');
const seconds = Number(process.env.CLASSROOM_SECONDS ?? 60);
assert.ok(Number.isFinite(seconds) && seconds >= 10 && seconds <= 7200);
const protocol = 'holy-ship-coop-23';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const sockets = [], timers = [], errors = [], latencies = [];
let sent = 0, sentBytes = 0, receivedSnapshots = 0, stopping = false;
async function post(path, data) {
  const response = await fetch(base + path, {method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({protocol, token:randomBytes(24).toString('hex'), password:'classroom', ...data})});
  assert.equal(response.status, 200, await response.clone().text());
  return response.json();
}
async function connect(ticket, onPacket) {
  const ws = new WebSocket(base.replace(/^http/, 'ws') + '/api/socket/' + ticket.id + '?ticket=' + ticket.ticket);
  sockets.push(ws); ws.binaryType = 'arraybuffer';
  const welcome = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(Error('Welcome timed out')), 10000);
    ws.addEventListener('error', () => { clearTimeout(timeout); reject(Error('Socket error')); });
    ws.addEventListener('message', e => {
      if (typeof e.data === 'string') {
        const message = JSON.parse(e.data);
        if (message.type === 'welcome') { clearTimeout(timeout); resolve(message); }
      } else { try { onPacket(new DataView(e.data)); } catch (e) { errors.push(e.message); } }
    });
  });
  ws.addEventListener('close', e => { if (!stopping) errors.push('Unexpected close: ' + e.code + ' ' + e.reason); });
  timers.push(setInterval(() => { if (ws.readyState === WebSocket.OPEN) ws.send('{"type":"heartbeat"}'); }, 10000));
  return {ws, id:welcome.id};
}
function packet(room, target, size) {
  const bytes = new ArrayBuffer(size), view = new DataView(bytes);
  view.setInt32(4,target,true); view.setUint8(8,2); view.setUint8(9,1);
  view.setInt32(12,room,true); return view;
}
function send(ws, view) { ws.send(view.buffer); sent++; sentBytes += view.byteLength; }
try {
  // All requests originate from one IP. The initial browser wave must also fit.
  const browsing = await Promise.all(Array.from({length:60}, () => fetch(base + '/api/crews')));
  assert.ok(browsing.every(r => r.status === 200), '60 browsers on one NAT admitted');
  for (const r of browsing) await r.arrayBuffer();
  const rooms = await Promise.all(Array.from({length:15}, async (_, roomIndex) => {
    const ticket = await post('/api/crews', {title:'Classroom load ' + roomIndex});
    const acknowledgements = new Map();
    const host = await connect(ticket, view => {
      assert.equal(view.getInt32(12,true),roomIndex,'cross-room input leak');
      acknowledgements.set(view.getInt32(0,true),view.getFloat64(24,true));
    });
    const guests = [];
    for (let n=0;n<3;n++) {
      let lastAck = 0;
      const guest = await connect(await post('/api/crews/'+ticket.id+'/join',{}), view => {
        assert.equal(view.getInt32(12,true),roomIndex,'cross-room snapshot leak');
        assert.equal(view.getInt32(0,true),1,'snapshot sender must be the captain');
        const stamp = view.getFloat64(32+n*8,true);
        if (stamp > lastAck) { latencies.push(performance.now()-stamp); lastAck=stamp; }
        receivedSnapshots++;
      });
      guests.push(guest);
    }
    return {roomIndex,host,guests,acknowledgements};
  }));
  assert.equal(sockets.length,60);
  const start = performance.now();
  for (const room of rooms) {
    timers.push(setInterval(() => {
      const view=packet(room.roomIndex,0,2048);
      view.setUint8(10,1);
      room.guests.forEach((g,n)=>view.setFloat64(32+n*8,room.acknowledgements.get(g.id)??0,true));
      send(room.host.ws,view);
    },100));
    for (const guest of room.guests) timers.push(setInterval(() => {
      const view=packet(room.roomIndex,1,64); view.setFloat64(24,performance.now(),true);
      send(guest.ws,view);
    },250)); // 4 inputs/s: twice the unchanged-input rate, allowing regular changes.
  }
  console.log('60 sockets / 15 crews running for '+seconds+' seconds; all share one IP.');
  await delay(seconds*1000);
  timers.forEach(clearInterval); await delay(300);
  const elapsed=(performance.now()-start)/1000;
  latencies.sort((a,b)=>a-b);
  const percentile=p=>Math.round(latencies[Math.floor((latencies.length-1)*p)]??0);
  const report={seconds:Math.round(elapsed),crews:15,players:60,sent,sentBytes,receivedSnapshots,
    inputToSnapshotMs:{p50:percentile(.5),p95:percentile(.95),p99:percentile(.99)},
    projectedGameplayRequestUnitsPerHour:Math.ceil(sent/elapsed*3600/20),
    note:'Local transport simulation, not 60 rendered games or campus/WAN latency. Excludes API, alarms and heartbeat accounting.',errors};
  await writeFile('../.godot/classroom-load-report.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
  assert.equal(errors.length,0);
  assert.ok(receivedSnapshots > seconds*15*3*8,'At least 8 delivered snapshots/s per guest under load');
  assert.ok(report.projectedGameplayRequestUnitsPerHour<70000,'Classroom traffic fits a one-hour free-tier budget with headroom');
} finally {
  stopping=true; timers.forEach(clearInterval);
  for(const ws of sockets) if(ws.readyState===WebSocket.OPEN) {ws.send('{"type":"leave"}');ws.close();}
}
