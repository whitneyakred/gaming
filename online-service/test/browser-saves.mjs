import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import path from 'node:path';
const base=process.env.HARBOR_TEST_URL ?? 'http://127.0.0.1:8789';
const profile=path.resolve('../.godot/browser-save-'+Date.now());
const errors=[];
const options={executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:1280,height:720},args:['--enable-webgl','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-background-timer-throttling','--disable-renderer-backgrounding']};
let context;
async function open(){
 context=await chromium.launchPersistentContext(profile,options);
 const page=await context.newPage();
 page.on('console',m=>{if(m.type()==='error'||m.text().includes('SCRIPT ERROR'))errors.push(m.text())});
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(base+'/play/');await page.waitForTimeout(16000);
 return page;
}
async function hostTab(page){await page.mouse.click(680,260);await page.waitForTimeout(1000);await page.mouse.click(450,170);await page.waitForTimeout(500);}
const read=page=>page.evaluate(()=>JSON.parse(localStorage.getItem('holyShip.voyage.v1.0')||'null'));
try {
 let page=await open();await hostTab(page);
 await page.mouse.click(440,242);await page.keyboard.press('Control+A');await page.keyboard.type('Persistent test voyage');
 await page.mouse.click(440,394);await page.waitForTimeout(5000);
 let saved=await read(page);assert.equal(saved?.title,'Persistent test voyage');assert.ok(saved.payload.length>100);
 const identity=await page.evaluate(()=>localStorage.getItem('holyShip.identity'));
 console.log('PASS host writes real browser-local world snapshot');
 await page.goto(base+'/');await page.waitForTimeout(1000);
 let crews=await(await fetch(base+'/api/crews')).json();assert.ok(!crews.crews.some(c=>c.title==='Persistent test voyage'));
 console.log('PASS browser Back/navigation removes host listing within one second');
 await context.close();
 page=await open();assert.equal((await read(page)).title,'Persistent test voyage');
 assert.equal(await page.evaluate(()=>localStorage.getItem('holyShip.identity')),identity);
 console.log('PASS world and sailor identity survive full browser restart');
 await hostTab(page);await page.screenshot({path:'../.godot/saved-voyages-browser.png'});
 await page.mouse.click(440,394);await page.waitForTimeout(5000);
 crews=await(await fetch(base+'/api/crews')).json();assert.ok(crews.crews.some(c=>c.title==='Persistent test voyage'&&c.count===1));
 assert.equal((await read(page)).title,'Persistent test voyage');
 console.log('PASS dated slot resumes saved voyage from the host menu');
 await page.goto(base+'/');await page.waitForTimeout(1000);
 await page.goto(base+'/play/');await page.waitForTimeout(16000);await hostTab(page);
 await page.mouse.click(830,430);await page.waitForTimeout(300);await page.screenshot({path:'../.godot/reset-save-confirmation.png'});
 await page.keyboard.press('Enter');await page.waitForTimeout(500);
 assert.equal(await read(page),null);
 console.log('PASS confirmed reset clears only selected local slot');
 assert.deepEqual(errors,[]);console.log('PASS no browser runtime errors');
} finally {await context?.close();}
