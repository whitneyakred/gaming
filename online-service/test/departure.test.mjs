import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
const base = process.env.HARBOR_TEST_URL ?? 'http://127.0.0.1:8787';
const token = () => randomBytes(24).toString('hex');
async function post(path, data) {
  const response = await fetch(base + path, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({protocol:'holy-ship-coop-4', password:'', token:token(), ...data})});
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
    let list = await (await fetch(base + '/api/crews')).json();
    assert.equal(list.crews.find(c => c.id === room.id).count, 2);
    await post(path + '/leave', {ticket:first.ticket});
    list = await (await fetch(base + '/api/crews')).json();
    assert.equal(list.crews.find(c => c.id === room.id).count, 1);
    replacement = await connect(await post(path + '/join', {token:identity}));
    await post(path + '/leave', {ticket:first.ticket});
    list = await (await fetch(base + '/api/crews')).json();
    assert.equal(list.crews.find(c => c.id === room.id).count, 2);
    const closed = new Promise(resolve => replacement.addEventListener('close', resolve, {once:true}));
    replacement.send(JSON.stringify({type:'leave'}));
    await Promise.race([closed, new Promise((_,reject) => setTimeout(() => reject(Error('Leave was not closed promptly')), 3000))]);
    await post(path + '/leave', {ticket:room.ticket});
    list = await (await fetch(base + '/api/crews')).json();
    assert.ok(!list.crews.some(c => c.id === room.id));
  } finally {host.close();guest.close();replacement?.close();}
});
