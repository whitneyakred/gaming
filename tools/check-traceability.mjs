import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

const file = resolve('docs/traceability.md');
const text = readFileSync(file, 'utf8');
const failures = [];
for (const match of text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
  const target = match[1];
  if (/^https?:/.test(target)) continue;
  const [path, anchor] = target.split('#');
  const absolute = resolve(dirname(file), decodeURIComponent(path));
  if (!existsSync(absolute)) { failures.push(`Missing file: ${target}`); continue; }
  if (anchor && absolute.endsWith('.md')) {
    const headings = [...readFileSync(absolute,'utf8').matchAll(/^#{1,6}\s+(.+)$/gm)]
      .map(m => m[1].toLowerCase().replace(/[^\p{L}\p{N}_\-\s]/gu,'').replace(/ /g,'-').trim());
    if (!headings.includes(anchor)) failures.push(`Missing heading: ${target}`);
  }
}
const specs = readFileSync('docs/requirements/use-cases.md', 'utf8');
const ids = new Set([...specs.matchAll(/UC-[A-Z]+-[a-z0-9-]+/g)].map(m => m[0]));
for (const id of ids) if (!text.includes('`'+id+'`')) failures.push(`Untraced use case: ${id}`);
if (failures.length) { console.error(failures.join('\n')); process.exitCode = 1; }
else console.log(`Traceability local files/headings resolve; ${ids.size} cited use-case IDs represented. External URLs and test completeness require review.`);
