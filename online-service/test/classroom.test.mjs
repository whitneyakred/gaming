import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes, randomUUID} from 'node:crypto';
const base=process.env.HARBOR_TEST_URL??'http://127.0.0.1:8787';
const token=()=>randomBytes(24).toString('hex');
async function attempt(identity) {
  return fetch(base+'/api/crews/'+randomUUID()+'/join', {method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({protocol:'holy-ship-coop-15',token:identity,password:''})});
}
test('Shared school IP allows a classroom burst, but one sailor cannot monopolize admission',async()=>{
  const students=Array.from({length:60},token);
  const responses=await Promise.all(students.map(attempt));
  assert.ok(responses.every(r=>r.status===404),'All sixty pass the gate (rooms intentionally absent)');
  await Promise.all(responses.map(r=>r.arrayBuffer()));
  const identity=token();
  for(let i=0;i<20;i++) {const r=await attempt(identity);assert.equal(r.status,404);await r.arrayBuffer();}
  const limited=await attempt(identity);assert.equal(limited.status,429);await limited.arrayBuffer();
  const other=await attempt(token());assert.equal(other.status,404);await other.arrayBuffer();
});
test('Public listing is briefly cacheable without exposing tickets or identities',async()=>{
  const response=await fetch(base+'/api/crews');
  assert.equal(response.status,200);
  assert.match(response.headers.get('cache-control'),/max-age=5/);
  const data=await response.json();
  for(const room of data.crews) {
    assert.ok(!('ticket' in room));assert.ok(!('password' in room));assert.ok(!('identity' in room));
  }
});
