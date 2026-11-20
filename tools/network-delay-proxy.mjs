// Local TCP impairment proxy, using only Node built-ins. Delays the ordered
// stream (including WebSocket data) without corrupting it. This is NOT UDP loss.
// node tools/network-delay-proxy.mjs [listen=8791] [relay=8790] [delay=80] [jitter=40] [stall=300]
import net from 'node:net';
import {pathToFileURL} from 'node:url';
export function createDelayProxy({relay,delay=80,jitter=40,stall=300,stallInterval=5000}) {
const sockets = new Set();
const server = net.createServer({allowHalfOpen:true},client => {
  const upstream = net.connect({host:'127.0.0.1',port:relay,allowHalfOpen:true});
  sockets.add(client); sockets.add(upstream);
  const started = Date.now();
  function forward(source, destination) {
    let scheduled = 0, sequence = 0, queued = 0, lastStall = 0, ended = false, timer;
    const pending = [];
    function pump() {
      clearTimeout(timer);
      while (pending.length && pending[0].at <= Date.now()) {
        const {bytes} = pending.shift();
        queued -= bytes.length;
        if (!destination.destroyed && !destination.write(bytes)) source.pause();
      }
      if (pending.length) timer=setTimeout(pump,Math.max(1,pending[0].at-Date.now()));
      else if (ended) destination.end();
    }
    source.on('data', bytes => {
      const now = Date.now();
      const stallNumber = Math.floor((now - started) / stallInterval);
      const extra = stallNumber > lastStall ? stall : 0;
      lastStall = stallNumber;
      scheduled = Math.max(scheduled, now + delay + ((sequence++ * 37) % (jitter + 1)) + extra);
      queued += bytes.length;
      if (queued > 1048576) { source.destroy(); destination.destroy(); return; }
      // A single FIFO pump preserves byte order even when many chunks acquire
      // the same release time. Independent timers can reorder a TCP stream.
      pending.push({at:scheduled,bytes});
      pump();
    });
    destination.on('drain', () => source.resume());
    source.on('end', () => {ended=true; pump();});
    source.on('error', () => destination.destroy());
    destination.on('close', () => { clearTimeout(timer); pending.length=0; });
    // A graceful upstream close must not destroy the client before buffered
    // downstream data has drained. Only abrupt closures abort the other half.
    source.on('close', () => { sockets.delete(source); if (!source.readableEnded) destination.destroy(); });
  }
  forward(client,upstream);
  forward(upstream,client);
});
server.stop = () => {for (const socket of sockets) socket.destroy(); server.close();};
return server;
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
const [listen=8791, relay=8790, delay=80, jitter=40, stall=300] = process.argv.slice(2).map(Number);
if (![listen,relay,delay,jitter,stall].every(Number.isFinite) || listen === relay || delay < 0 || jitter < 0 || stall < 0)
  throw Error('Use distinct ports and nonnegative delay/jitter/stall values in milliseconds');
const server = createDelayProxy({relay,delay,jitter,stall});
server.listen(listen,'127.0.0.1',() => console.log(`Local relay proxy: 127.0.0.1:${listen} → 127.0.0.1:${relay}; each direction ${delay}–${delay+jitter} ms, ${stall} ms stall every 5 s`));
process.on('SIGINT', () => server.stop());
}
