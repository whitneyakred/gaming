import {mkdir,readFile,writeFile,copyFile,readdir,stat} from 'node:fs/promises';
import {gzipSync} from 'node:zlib';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const out=path.join(root,'online-service/public');
await mkdir(path.join(out,'play'),{recursive:true});
for(const file of ['index.html','style.css'])await copyFile(path.join(root,'web-site',file),path.join(out,file));
await copyFile(path.join(root,'assets/menus/holy_ship_logo.png'),path.join(out,'logo.png'));
await copyFile(path.join(root,'builds/web/index.icon.png'),path.join(out,'icon.png'));
for(const name of await readdir(path.join(root,'builds/web'))){
 const source=path.join(root,'builds/web',name);if(!(await stat(source)).isFile())continue;
 if(name.endsWith('.wasm'))await writeFile(path.join(out,'play',name+'.gz'),gzipSync(await readFile(source),{level:9}));
 else await copyFile(source,path.join(out,'play',name));
}
await writeFile(path.join(out,'_headers'),'/play/*\n  Cache-Control: no-cache\n  X-Content-Type-Options: nosniff\n/*\n  Referrer-Policy: same-origin\n  X-Frame-Options: SAMEORIGIN\n');
console.log('Website and compressed game assets prepared.');
