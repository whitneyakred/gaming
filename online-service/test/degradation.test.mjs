import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';

// Run the production request handler; only the Cloudflare base class and the
// external room binding are substituted. No real room or player is affected.
let source = await readFile(new URL('../src/index.ts', import.meta.url), 'utf8');
source = source.replace('import { DurableObject } from "cloudflare:workers";', 'class DurableObject {}');
if (process.env.HARBOR_REMOVE_RECOVERY === '1') {
  const original = 'return route(request, env, url).catch(() => {';
  assert.ok(source.includes(original), 'mutation must match production recovery');
  source = source.replace(original, 'return route(request, env, url); /*').replace(
    'return error("The harbor is unavailable. Please try again shortly.", 503);\n    });',
    'return error("The harbor is unavailable. Please try again shortly.", 503);\n    }); */');
}
const javascript = stripTypeScriptTypes(source) + '\n//# sourceURL=harbor-handler-under-test.mjs';
const { default: worker } = await import('data:text/javascript;base64,' + Buffer.from(javascript).toString('base64'));

test('ROB-HARBOR-unavailable: failed room RPC returns safe retry guidance', async () => {
  const logs = [];
  const previous = console.error;
  console.error = value => logs.push(value);
  let calls = 0;
  try {
    const response = await worker.fetch(new Request(
      'https://example.test/api/socket/12345678-1234-4234-8234-123456789abc'), {
      ROOMS: { getByName: () => ({ fetch: async () => {
        calls++; throw new Error('private-ticket-must-not-leak');
      } }) },
    }, {});
    assert.equal(calls, 1, 'exercise the external room dependency');
    assert.equal(response.status, 503);
    assert.equal(response.headers.get('Cache-Control'), 'no-store');
    assert.deepEqual(await response.json(), {
      error: 'The harbor is unavailable. Please try again shortly.',
    });
    assert.deepEqual(logs.map(JSON.parse), [{ event: 'harbor_dependency_failure', status: 503 }]);
  } finally { console.error = previous; }
});
