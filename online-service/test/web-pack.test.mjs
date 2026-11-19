import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const base = process.env.HARBOR_TEST_URL ?? 'http://127.0.0.1:8787';
test('streamed game pack decompresses to the exact exported file', async () => {
  const response = await fetch(base + '/play/index.pck');
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'application/octet-stream');
  const actual = Buffer.from(await response.arrayBuffer());
  const expected = await readFile(new URL('../../builds/web/index.pck', import.meta.url));
  const hash = data => createHash('sha256').update(data).digest('hex');
  assert.equal(hash(actual), hash(expected));
  const head = await fetch(base + '/play/index.pck', {method:'HEAD'});
  assert.equal(head.status, 200);
  assert.equal((await head.arrayBuffer()).byteLength, 0);
});
