import {mkdir,readFile,writeFile,copyFile,readdir,stat,rm} from 'node:fs/promises';
import {gzipSync} from 'node:zlib';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const out=path.join(root,'online-service/public');
await mkdir(path.join(out,'play'),{recursive:true});
for(const file of ['index.html','style.css'])await copyFile(path.join(root,'web-site',file),path.join(out,file));
await copyFile(path.join(root,'assets/menus/title_wordmark.png'),path.join(out,'logo.png'));
await copyFile(path.join(root,'builds/web/index.icon.png'),path.join(out,'icon.png'));
for(const name of await readdir(path.join(root,'builds/web'))){
 const source=path.join(root,'builds/web',name);if(!(await stat(source)).isFile())continue;
 if(name.endsWith('.import'))continue;
 if(name.endsWith('.pck')){
  const packed=gzipSync(await readFile(source),{level:9});
  const chunkSize=16*1024*1024;
  const parts=[];
  for(let offset=0;offset<packed.length;offset+=chunkSize){
   const part=name+'.gz.part'+parts.length;
   await writeFile(path.join(out,'play',part),packed.subarray(offset,offset+chunkSize));
   parts.push(part);
  }
  await writeFile(path.join(out,'play',name+'.parts.json'),JSON.stringify({parts}));
  await rm(path.join(out,'play',name),{force:true});
  await rm(path.join(out,'play',name+'.gz'),{force:true});
 }
 else if(name.endsWith('.wasm')){
  await writeFile(path.join(out,'play',name+'.gz'),gzipSync(await readFile(source),{level:9}));
  await rm(path.join(out,'play',name),{force:true});
 }
 else await copyFile(source,path.join(out,'play',name));
}
await writeFile(path.join(out,'_headers'),'/play/*\n  Cache-Control: no-cache\n  X-Content-Type-Options: nosniff\n/*\n  Referrer-Policy: same-origin\n  X-Frame-Options: SAMEORIGIN\n');
console.log('Website and compressed game assets prepared.');
await copyFile(path.join(root,'assets/menus/title_ocean.png'),path.join(out,'ocean.png'));
await copyFile(path.join(root,'assets/menus/title_wreck_wood.png'),path.join(out,'wreck.png'));
await copyFile(path.join(root,'assets/menus/menu_plank.png'),path.join(out,'plank.png'));
await copyFile(path.join(root,'assets/fonts/PixelifySans.ttf'),path.join(out,'PixelifySans.ttf'));
await copyFile(path.join(root,'assets/fonts/OFL.txt'),path.join(out,'font-license.txt'));
