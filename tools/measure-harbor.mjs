import { writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';

const base = process.argv[2];
const output = process.argv[3];
if (!base || !output) throw Error('Usage: node tools/measure-harbor.mjs https://host result.json');
const events = [];
const started = new Date().toISOString();
for (let i = 0; i < 20; i++) {
  const start = performance.now();
  let status = null, valid = false;
  try {
    const response = await fetch(new URL('/api/crews', base), { signal: AbortSignal.timeout(5000) });
    status = response.status;
    const body = await response.json();
    valid = response.ok && Array.isArray(body.crews);
  } catch { /* A network error is a bad event, never a skipped sample. */ }
  const elapsed_ms = Math.round(performance.now() - start);
  events.push({ status, elapsed_ms, good: valid && elapsed_ms <= 2000 });
  if (i < 19) await new Promise(resolve => setTimeout(resolve, 1000));
}
const good = events.filter(e => e.good).length;
const result = { requirement: 'PER-HARBOR-discovery', target_status: 'proposed, team approval pending',
  source_commit: execFileSync('git', ['rev-parse', 'HEAD'], {encoding:'utf8'}).trim(),
  base, started, ended: new Date().toISOString(), target: 0.95, threshold_ms: 2000,
  good, total: events.length, sli: good / events.length, allowed_bad: 1, actual_bad: events.length-good,
  limitation: '20 synthetic discovery requests from one location; not gameplay, joins, frames, sustained uptime or uncached backend coverage.', events };
await writeFile(output, JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify({ good, total: events.length, sli: result.sli }));
process.exitCode = result.sli >= result.target ? 0 : 1;
