import net from 'node:net';
import {once} from 'node:events';
import {setTimeout as wait} from 'node:timers/promises';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {createDelayProxy} from './network-delay-proxy.mjs';
test('Impairment preserves every TCP byte and EOF through jitter/stall bursts', {timeout:10000}, async () => {
  const echo=net.createServer({allowHalfOpen:true},socket=>socket.pipe(socket));
  echo.listen(0,'127.0.0.1'); await once(echo,'listening');
  const proxy=createDelayProxy({relay:echo.address().port,delay:20,jitter:20,stall:80,stallInterval:50});
  proxy.listen(0,'127.0.0.1'); await once(proxy,'listening');
  const client=net.connect(proxy.address().port,'127.0.0.1');
  const received=[]; client.on('data',chunk=>received.push(chunk));
  const ended=once(client,'end');
  const sent=[];
  try {
    await once(client,'connect');
    for(let i=0;i<100;i++) {
      const chunk=Buffer.alloc(1000+i,i);sent.push(chunk);client.write(chunk);
      await wait(2);
    }
    client.end(); await ended;
    const digest=chunks=>createHash('sha256').update(Buffer.concat(chunks)).digest('hex');
    assert.equal(digest(received),digest(sent),'Delayed TCP bytes remain identical and ordered');
  } finally {client.destroy();proxy.stop();echo.close();}
});
