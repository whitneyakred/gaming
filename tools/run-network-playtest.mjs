// Runs isolated host + two guests. Pass --relay-test --harbor-url URL for the
// local Cloudflare relay; no production rooms are created by default.
import {spawn} from 'node:child_process';
import {mkdirSync, writeFileSync} from 'node:fs';
import path from 'node:path';
const [executable, ...extra] = process.argv.slice(2);
if (!executable) throw Error('Usage: node tools/run-network-playtest.mjs GODOT_EXE [test arguments]');
const outputDir = path.resolve('.godot/network-validation');
mkdirSync(outputDir, {recursive:true});
const roles = ['host', 'alpha', 'beta'];
const guestIndex = extra.indexOf('--guest-harbor-url');
const guestUrl = guestIndex >= 0 ? extra.splice(guestIndex,2)[1] : null;
const results = await Promise.all(roles.map(async role => {
  const profile = path.join(outputDir, role);
  mkdirSync(profile, {recursive:true});
  const args = [...extra];
  if (guestUrl && role !== 'host') {
    const index = args.indexOf('--harbor-url');
    if (index >= 0) args.splice(index,2);
    args.push('--harbor-url',guestUrl);
  }
  const child = spawn(executable, ['--headless', '--path', '.', '--script', 'res://tests/network_smoke.gd', '--', '--settings-test', `--test-${role}`, ...args],
    {windowsHide:true, env:{...process.env, APPDATA:profile}});
  let output = '';
  child.stdout.on('data', chunk => output += chunk);
  child.stderr.on('data', chunk => output += chunk);
  const timer = setTimeout(() => child.kill(), 85000);
  const code = await new Promise((resolve,reject) => {child.on('close',resolve); child.on('error',reject);});
  clearTimeout(timer);
  writeFileSync(path.join(outputDir, `${role}.log`),output);
  const passed = code === 0 && /NETWORK .+: [1-9]\d* checks, 0 failures/.test(output) && !/SCRIPT ERROR|^ERROR:/m.test(output);
  console.log(`${role}: ${passed ? 'PASS' : 'FAIL'} (exit ${code})`);
  console.log(output.split('\n').filter(line => /NETWORK |RELAY TRAFFIC|SCRIPT ERROR|^ERROR:/.test(line)).slice(0,20).join('\n'));
  return passed;
}));
process.exitCode = results.every(Boolean) ? 0 : 1;
