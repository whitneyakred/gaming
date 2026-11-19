import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
const [executable, ...requested] = process.argv.slice(2);
if (!executable) throw Error('Usage: node tools/run-godot-checkpoint.mjs GODOT_EXE [suite ...]');
const suites = requested.length ? requested : ['sailing_integration','wind_integration','station_camera_integration','island_minigames'];
mkdirSync('.godot', {recursive:true});
let failed = false;
for (const suite of suites) {
  if (!/^[a-z_]+$/.test(suite)) throw Error('Invalid suite name');
  const child = spawn(executable, ['--headless','--path','.', '--log-file', `${process.cwd()}/.godot/checkpoint-${suite}.log`, '--script', `res://tests/${suite}.gd`, '--','--settings-test'], {windowsHide:true});
  let output = '', timedOut = false;
  child.stdout.on('data', chunk => output += chunk);
  child.stderr.on('data', chunk => output += chunk);
  const timer = setTimeout(() => {
    timedOut = true;
    if (process.platform === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], {windowsHide:true});
    else child.kill('SIGKILL');
  }, suite === 'island_minigames' ? 240000 : 70000);
  const code = await new Promise((resolve,reject) => {child.on('close',resolve);child.on('error',reject);});
  clearTimeout(timer);
  writeFileSync(`.godot/checkpoint-${suite}-output.log`,output);
  const passed = code === 0 && !timedOut && !/SCRIPT ERROR|^ERROR:/m.test(output);
  console.log(`${suite}: ${passed ? 'PASS' : 'FAIL'} (exit=${code}, timeout=${timedOut})`);
  console.log(output.split('\n').filter(line => /checks|failures|failure\(s\)|^ERROR:|SCRIPT ERROR/.test(line)).slice(0,12).join('\n'));
  failed ||= !passed;
}
process.exitCode = failed ? 1 : 0;
