import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
const base = process.env.HARBOR_TEST_URL ?? 'http://127.0.0.1:8787';
const token = () => randomBytes(24).toString('hex');
async function listingCount(id, count) {
  const until = Date.now() + 7000;
  while (Date.now() < until) {
    const list = await (await fetch(base + '/api/crews')).json();
    if ((list.crews.find(c => c.id === id)?.count ?? 0) === count) return;
    await new Promise(r => setTimeout(r, 200));
  }
  assert.fail('Directory did not converge within its five-second cache TTL');
}
async function post(path, data) {
  const response = await fetch(base + path, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({protocol:'holy-ship-coop-15', password:'', token:token(), ...data})});
  assert.equal(response.status, 200, await response.clone().text());
  return response.json();
}
async function connect(ticket) {
  const ws = new WebSocket(base.replace(/^http/, 'ws') + '/api/socket/' + ticket.id + '?ticket=' + ticket.ticket);
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(Error('No welcome')), 5000);
    ws.addEventListener('message', e => { if (typeof e.data === 'string' && JSON.parse(e.data).type === 'welcome') {clearTimeout(timer);resolve();} });
  });
  return ws;
}
test('Departure frees identity immediately and old departure cannot close a rejoin', async () => {
  const room = await post('/api/crews', {title:'Departure test'});
  const host = await connect(room);
  const identity = token();
  const path = '/api/crews/' + room.id;
  const first = await post(path + '/join', {token:identity});
  const guest = await connect(first);
  let replacement;
  try {
    await post(path + '/leave', {ticket:randomUUID()});
    await listingCount(room.id, 2);
    await post(path + '/leave', {ticket:first.ticket});
    // Rejoin admission is immediate, even while the public listing is cached.
    replacement = await connect(await post(path + '/join', {token:identity}));
    await post(path + '/leave', {ticket:first.ticket});
    await listingCount(room.id, 2);
    const closed = new Promise(resolve => replacement.addEventListener('close', resolve, {once:true}));
    replacement.send(JSON.stringify({type:'leave'}));
    await Promise.race([closed, new Promise((_,reject) => setTimeout(() => reject(Error('Leave was not closed promptly')), 3000))]);
    await post(path + '/leave', {ticket:room.ticket});
    await listingCount(room.id, 0);
  } finally {host.close();guest.close();replacement?.close();}
});

test('Host and guest departures cannot republish an empty ended crew', async () => {
  const room = await post('/api/crews', {title:'Close race'});
  const host = await connect(room);
  const tickets = await Promise.all([0,1,2].map(() => post('/api/crews/' + room.id + '/join', {})));
  const guests = await Promise.all(tickets.map(connect));
  try {
    await Promise.all([room, ...tickets].map(t => post('/api/crews/' + room.id + '/leave', {ticket:t.ticket})));
    await listingCount(room.id, 0);
    for (const delay of [0, 100, 500, 2500]) {
      await new Promise(r => setTimeout(r, delay));
      const listing = await (await fetch(base + '/api/crews')).json();
      assert.ok(!listing.crews.some(c => c.id === room.id), 'Ended crew must stay absent after late close handlers');
    }
  } finally { host.close(); guests.forEach(ws => ws.close()); }
});
