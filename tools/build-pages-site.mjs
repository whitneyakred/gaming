import { cp, writeFile } from 'node:fs/promises';
import path from 'node:path';
const root = path.resolve(import.meta.dirname, '..');
const out = path.join(root, 'web-site/dist');
await cp(path.join(root, 'online-service/public'), out, { recursive: true });
await cp(path.join(root, 'web-site/_worker.js'), path.join(out, '_worker.js'));
await writeFile(path.join(out, '_routes.json'), JSON.stringify({
  version: 1, include: ['/api/*', '/play/index.wasm'], exclude: []
}));
console.log('Pages site prepared; static files bypass function invocations.');
