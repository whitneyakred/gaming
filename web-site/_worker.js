// Keep the browser on pages.dev while the existing harbor handles multiplayer.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (!url.pathname.startsWith('/api/') && url.pathname !== '/play/index.wasm') {
      return env.ASSETS.fetch(request);
    }
    const origin = request.headers.get('Origin');
    if (origin && origin !== url.origin) {
      return new Response('Cross-origin request denied', { status: 403 });
    }
    const upstream = new URL(request.url);
    upstream.hostname = 'holy-ship-harbor.petersonleiton.workers.dev';
    const forwarded = new Request(upstream, request);
    if (origin) forwarded.headers.set('Origin', upstream.origin);
    return env.HARBOR.fetch(forwarded);
  }
};
