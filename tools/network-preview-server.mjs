// Serves an isolated Web export alongside the local relay. Never publishes it.
// node tools/network-preview-server.mjs [export=.godot/network-web] [port=8792] [relay=8790]
import http from 'node:http';
import net from 'node:net';
import path from 'node:path';
import {createReadStream, statSync} from 'node:fs';
const [directory='.godot/network-web', port='8792', relay='8790'] = process.argv.slice(2);
const root = path.resolve(directory);
const mime = {'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
const server = http.createServer((request,response) => {
  const pathname = new URL(request.url,'http://localhost').pathname;
  if (pathname.startsWith('/api/')) {
    const headers = {...request.headers,host:`127.0.0.1:${relay}`};
    if (headers.origin) headers.origin = `http://127.0.0.1:${relay}`;
    const upstream = http.request({host:'127.0.0.1',port:relay,path:request.url,method:request.method,headers}, res => {
      response.writeHead(res.statusCode,res.headers); res.pipe(response);
    });
    upstream.on('error', () => {response.writeHead(502); response.end();});
    request.pipe(upstream); return;
  }
  const file = path.resolve(root, pathname === '/play/' || pathname === '/' ? 'index.html' : '.' + pathname.replace(/^\/play/,'') );
  if (!file.startsWith(root + path.sep)) {response.writeHead(403); response.end(); return;}
  try {
    const stat = statSync(file);
    if (!stat.isFile()) throw Error('Not a file');
    response.writeHead(200,{'Content-Type':mime[path.extname(file)] ?? 'application/octet-stream','Content-Length':stat.size,'Cache-Control':'no-store'});
    createReadStream(file).pipe(response);
  } catch {response.writeHead(404); response.end();}
});
server.on('upgrade',(request,socket,head) => {
  if (!request.url.startsWith('/api/socket/')) {socket.destroy(); return;}
  const upstream = net.connect({host:'127.0.0.1',port:Number(relay)},() => {
    const headers = {...request.headers,host:`127.0.0.1:${relay}`,origin:`http://127.0.0.1:${relay}`};
    upstream.write(`${request.method} ${request.url} HTTP/1.1\r\n${Object.entries(headers).map(([key,value])=>`${key}: ${value}`).join('\r\n')}\r\n\r\n`);
    if (head.length) upstream.write(head);
    socket.pipe(upstream); upstream.pipe(socket);
  });
  upstream.on('error',()=>socket.destroy()); socket.on('error',()=>upstream.destroy());
  socket.on('close',()=>upstream.destroy()); upstream.on('close',()=>socket.destroy());
});
server.listen(Number(port),'127.0.0.1',()=>console.log(`Local Web export: http://127.0.0.1:${port}/play/`));
