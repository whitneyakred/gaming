// Actual Godot Web transport against the local Worker; never creates live rooms.
// node tools/run-webrtc-browser.mjs GODOT_EXE [http://127.0.0.1:8790]
import {mkdir, copyFile, writeFile, readFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {randomBytes} from 'node:crypto';
import http from 'node:http';
import net from 'node:net';
import path from 'node:path';
import assert from 'node:assert/strict';
import {chromium, devices} from '../online-service/node_modules/playwright/index.mjs';
const [godot, base='http://127.0.0.1:8790'] = process.argv.slice(2);
if (!godot || new URL(base).hostname !== '127.0.0.1') throw Error('Provide Godot executable and a local relay URL');
const root=process.cwd(), project=path.join(root,'.godot/rtc-browser'), out=path.join(project,'web');
await mkdir(out,{recursive:true});
for(const file of ['harbor_peer.gd','harbor_rtc.gd','relay_snapshot_window.gd']) await copyFile(path.join(root,'scripts/network',file),path.join(project,file));
await copyFile(path.join(root,'tests/harbor_rtc_browser.gd'),path.join(project,'main.gd'));
await writeFile(path.join(project,'project.godot'),'config_version=5\n[application]\nrun/main_scene="res://main.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
await writeFile(path.join(project,'main.tscn'),'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Test" type="Node"]\nscript = ExtResource("1")\n');
const template=path.join(root,'export_templates/web_nothreads_debug.zip').replaceAll('\\','/');
await writeFile(path.join(project,'export_presets.cfg'),`[preset.0]\nname="Web"\nplatform="Web"\nexport_filter="all_resources"\ninclude_filter=""\nexclude_filter="web/*"\n[preset.0.options]\ncustom_template/debug="${template}"\nvariant/thread_support=false\n`);
async function run(args) {
 const child=spawn(godot,['--headless','--path',project,...args],{windowsHide:true,env:{...process.env,APPDATA:path.join(project,'profile')}});
 let output='';child.stdout.on('data',c=>output+=c);child.stderr.on('data',c=>output+=c);
 const code=await new Promise((resolve,reject)=>{child.on('close',resolve);child.on('error',reject);});
 if(code || /SCRIPT ERROR|Parse Error|^ERROR:/m.test(output)) throw Error(output);
}
await run(['--editor','--quit']);
await run(['--export-debug','Web',path.join(out,'index.html')]);
const server=http.createServer(async(req,res)=>{
 try {
  const name=new URL(req.url,'http://localhost').pathname.slice(1)||'index.html';
  if(!/^[\w.-]+$/.test(name)) throw Error('path');
  const data=await readFile(path.join(out,name));
  res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm'})[path.extname(name)]||'application/octet-stream');
  res.end(data);
 }catch{res.writeHead(404);res.end();}
});
const sockets=new Set();
server.on('connection',socket=>{sockets.add(socket);socket.on('close',()=>sockets.delete(socket));});
server.on('upgrade',(request,socket,head)=>{
 const relay=new URL(base);
 const upstream=net.connect({host:relay.hostname,port:Number(relay.port)},()=>{
  const headers={...request.headers,host:relay.host,origin:base};
  upstream.write(`${request.method} ${request.url} HTTP/1.1\r\n${Object.entries(headers).map(([k,v])=>`${k}: ${v}`).join('\r\n')}\r\n\r\n`);
  if(head.length)upstream.write(head);
  socket.pipe(upstream);upstream.pipe(socket);
 });
 upstream.on('error',()=>socket.destroy());socket.on('error',()=>upstream.destroy());
 socket.on('close',()=>upstream.destroy());upstream.on('close',()=>socket.destroy());
});
await new Promise(r=>server.listen(8793,'127.0.0.1',r));
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const errors=[], results=[];
const protocol=(await (await fetch(base+'/api/health')).json()).protocol;
async function ticket(endpoint, data={}) {
 const res=await fetch(base+endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({protocol,token:randomBytes(24).toString('hex'),password:'',...data})});
 const result=await res.json(); if(!res.ok) throw Error(JSON.stringify(result)); return result;
}
async function pageFor(ticket, mobile=false, disabled=false, blocked=false, holdAcks=false) {
 const context=await browser.newContext(mobile?{...devices['Pixel 7']}:{viewport:{width:800,height:600}});
 await context.addInitScript(({url,disabled,blocked,holdAcks})=>{
  window.rtcURL=url;window.rtcDisabled=disabled;
  window.rtcDrop=blocked;
  window.holdSnapshotAcks=holdAcks;
  window.heldAcks=[];
  window.flushSnapshotAcks=()=>{window.holdSnapshotAcks=false;window.heldAcks.splice(0).forEach(send=>send());};
  const OriginalSocket=window.WebSocket;
  window.WebSocket=class extends OriginalSocket {
   send(data){
    const bytes=data instanceof ArrayBuffer?new Uint8Array(data):ArrayBuffer.isView(data)?new Uint8Array(data.buffer,data.byteOffset,data.byteLength):null;
    if(window.holdSnapshotAcks&&bytes?.[11]===1){
     const message=JSON.parse(new TextDecoder().decode(bytes.subarray(12)));
     if(message.type==='snapshot_ack'){const copy=bytes.slice();window.heldAcks.push(()=>super.send(copy));return;}
    }
    return super.send(data);
   }
  };
  const original=window.RTCPeerConnection;
  window.RTCPeerConnection=class extends original {
   createDataChannel(...args) {const channel=super.createDataChannel(...args),send=channel.send.bind(channel);channel.send=data=>{if(!window.rtcDrop)send(data);};return channel;}
  };
 },{url:'ws://127.0.0.1:8793/api/socket/'+ticket.id+'?ticket='+encodeURIComponent(ticket.ticket),disabled,blocked,holdAcks});
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto('http://127.0.0.1:8793/');
 await page.waitForFunction(()=>window.rtcResult?.state===2,{},{timeout:30000});
 return page;
}
async function sample(page){return page.evaluate(()=>window.rtcResult);}
try {
 const room=await ticket('/api/crews',{title:'Local WebRTC test'});
 const host=await pageFor(room);
 const guest=await pageFor(await ticket('/api/crews/'+room.id+'/join'),true);
 await guest.waitForFunction(()=>window.rtcResult?.rtc.peers['1']==='direct',{},{timeout:20000});
 await guest.waitForFunction(()=>window.rtcResult.snapshots>15 && window.rtcResult.reliable>15);
 let before=await sample(guest);
 assert.ok(before.rtc.direct_received_bytes>0,'Mobile browser receives direct Godot snapshots');
 const fallback=await pageFor(await ticket('/api/crews/'+room.id+'/join'),false,true,false,true);
 await fallback.waitForFunction(()=>window.heldAcks.length===2);
 const heldSnapshotCount=(await sample(fallback)).snapshots;
 assert.ok(heldSnapshotCount>0 && heldSnapshotCount<=2,'At most two snapshots delivered before receipts');
 const movingBefore=await sample(guest);
 await guest.waitForFunction(old=>window.rtcResult.snapshots>old+15,movingBefore.snapshots);
 assert.equal((await sample(fallback)).snapshots,heldSnapshotCount,'Unacknowledged relay snapshots are bounded while direct peer continues');
 const hostBeforeFlush=await sample(host);
 assert.equal(hostBeforeFlush.window.pending[String((await sample(fallback)).id)],2);
 await fallback.evaluate(()=>window.flushSnapshotAcks());
 await fallback.waitForFunction(()=>window.rtcResult.snapshots>10 && window.rtcResult.reliable>10);
 assert.ok((await sample(fallback)).last_snapshot>=hostBeforeFlush.sent_tick,'Recovery sends fresh state rather than replaying a backlog');
 assert.equal((await sample(fallback)).rtc.direct_received_bytes,0,'Disabled peer stays on relay in mixed crew');
 results.push({case:'direct + mixed relay crew',host:await sample(host),mobile:before,fallback:await sample(fallback)});
 await guest.evaluate(()=>window.rtcStop=true);
 await guest.waitForFunction(()=>window.rtcResult.rtc.fallbacks>0);
 const stoppedBaseline=await sample(guest);
 await guest.waitForFunction(old=>window.rtcResult.snapshots>old.snapshots+15 && window.rtcResult.reliable>old.reliable+15,stoppedBaseline);
 const after=await sample(guest);
 assert.equal(after.rtc.direct_received_bytes,stoppedBaseline.rtc.direct_received_bytes,'Fallback traffic no longer uses direct channel');
 results.push({case:'mid-session fallback',guest:after});
 for(const p of [guest,fallback,host]) await p.context().close();
 const blockedRoom=await ticket('/api/crews',{title:'Blocked direct test'});
 const host2=await pageFor(blockedRoom,true);
 const blocked=await pageFor(await ticket('/api/crews/'+blockedRoom.id+'/join'),false,false,true);
 await blocked.waitForFunction(()=>window.rtcResult.rtc.fallbacks>0,{},{timeout:20000});
 const blockedResult=await sample(blocked);
 assert.ok(blockedResult.snapshots>30 && blockedResult.reliable>30,'Unusable direct channel does not delay relay gameplay');
 assert.equal(blockedResult.rtc.direct_received_bytes,0);
 results.push({case:'unusable direct path',guest:blockedResult});
 await blocked.context().close();await host2.context().close();
 const lossRoom=await ticket('/api/crews',{title:'Direct loss test'});
 const mobileHost=await pageFor(lossRoom,true);
 const desktop=await pageFor(await ticket('/api/crews/'+lossRoom.id+'/join'));
 await desktop.waitForFunction(()=>window.rtcResult?.rtc.peers['1']==='direct',{},{timeout:20000});
 await desktop.waitForFunction(()=>window.rtcResult.rtc.direct_received_bytes>1000);
 const preLoss=await sample(desktop);
 await desktop.evaluate(()=>window.rtcDrop=true);
 await desktop.waitForFunction(()=>window.rtcResult.rtc.fallbacks>0,{},{timeout:8000});
 await desktop.waitForFunction(old=>window.rtcResult.snapshots>old.snapshots+40 && window.rtcResult.reliable>old.reliable+40,preLoss);
 results.push({case:'mobile host + silent established path loss',guest:await sample(desktop)});
 await desktop.context().close();await mobileHost.context().close();
 assert.deepEqual(errors,[],'No browser/Godot runtime errors');
 await writeFile(path.join(project,'results.json'),JSON.stringify(results,null,2));
 console.log('PASS: direct Godot WebRTC, mobile host/guest emulation, mixed relay crew, mid-session fallback, blocked path, silent path loss; no runtime errors.');
} catch(error) {console.error('Browser errors:',errors);for(const c of browser.contexts())for(const p of c.pages())console.error(await p.evaluate(()=>({result:window.rtcResult,heldAcks:window.heldAcks?.length})).catch(()=>null));throw error;}
finally {await browser.close();for(const socket of sockets)socket.destroy();await new Promise(r=>server.close(r));}
