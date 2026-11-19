# Holy Ship online release

For the complete explanation, see [Multiplayer system and operations guide](multiplayer-system.md).
For current classroom limits and traffic optimizations, see [60-student demo](classroom-demo.md).

Live website and shared harbor: https://holy-ship.pages.dev

## Players

Open the website, choose Play Free, and use Sail with a crew. Browse crews opens
first. Hosting asks for a voyage name and Public / Private; Private reveals a
blank password field that the host must fill in. Public voyages have no password. Private voyages
remain listed but require the password. The captain's previous hosted voyage
resumes automatically. There is no IP address, direct-connect, or LAN UI.

Use a desktop browser with WebGL 2, keyboard, and mouse. The host must keep the
game tab in the foreground and the device awake. Leaving ends the voyage for
everyone. Mac browser play does not require an Apple developer account, EOS
installation, or downloaded-app security exceptions. Native Mac distributions
still require their own signing/notarization process before public release.

## Teammates

Clone/pull the repository, open project.godot in Godot 4.7.2, and press F5.
The public harbor URL is a normal Project Settings value, not a secret.
No Epic project, EOS library install, or private .local/eos.cfg is needed for the
current game. The old EOS adapter and vendor folder have .gdignore files and
are excluded from releases. Their installer scripts are legacy rollback tools.
Editor, desktop, and browser players share the same directory and protocol.

## Service and release setup

The Cloudflare service lives in online-service/. It uses SQLite Durable Objects:
one room per voyage, four directory shards, and per-IP request gates. The host
still simulates the game; Cloudflare relays packets and handles room admission.
It assigns packet sources and never permits a guest to impersonate the captain.
Room tickets are short-lived, single-use, and issued only after password/capacity
checks. Persistent sailor tokens are sent only in HTTPS bodies. Temporary
hashed IP identifiers enforce request limits; game traffic is not logged.

Development commands from online-service/:

    npm ci
    npm run dev
    npm run check
    npm test

The tests expect wrangler dev on 127.0.0.1:8787. Authentication for deployment is
wrangler login; do not share tokens in Git. wrangler.jsonc contains only public
configuration. Use npm run types after modifying bindings.

Release from the project root:

    powershell -File tools/release-harbor.ps1 -GodotPath "path/to/Godot_console.exe"

This validates configuration, exports the game, prepares compressed web assets,
and runs the service type check/dry run. It does not deploy. Then run
npm run deploy from online-service/ to publish the backend. Then, from web-site/:

    ../online-service/node_modules/.bin/wrangler pages deploy dist --project-name holy-ship --branch systems-revamp --force

The --force flag selects Pages rather than Wrangler's automatic Workers migration.
Pages serves static files directly and forwards only /api/* and /play/index.wasm
through its HARBOR service binding. Browser users stay on holy-ship.pages.dev;
the native game still connects directly to the same backend. Changing website
origins does not migrate browser-local saves or sailor identities.

All files under public/ and web-site/dist/ are
reproducible generated output and ignored by Git. The 38 MB WebAssembly file is
stored compressed below Cloudflare's per-asset limit; the Worker serves it with
manual gzip encoding so browsers decode it exactly once.

The free Workers plan has daily request, duration, and storage limits. It does
not guarantee unlimited public multiplayer. This deployment did not purchase a
domain or enable a paid plan. Stay on Free to avoid usage billing; reaching a
limit can make online play unavailable until reset. Track Cloudflare's usage
before expanding promotion. No permanent server or host migration is provided.

References:
- https://developers.cloudflare.com/durable-objects/platform/pricing/
- https://developers.cloudflare.com/workers/platform/limits/
- https://docs.godotengine.org/en/stable/classes/class_multiplayerpeerextension.html
