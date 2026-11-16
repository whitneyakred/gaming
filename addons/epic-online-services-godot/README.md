# EOSG dependency

Upstream: https://github.com/3ddelano/epic-online-services-godot
Release: 2.3.1, commit 56238973e2cd7ac9ac99ca14f88934465f0a8997.
Included GDScript wrappers are MIT licensed; see LICENSE.md. Native libraries
are installed with tools/install-eos.ps1 and ignored by Git. The Epic SDK inside
those packages is governed by Epic's SDK terms, not the wrapper's MIT license.

Only the low-level wrapper and native transport are used. High-level autoloads,
voice, overlays, and third-party example assets are not installed.
Local wrapper change: EOS RTCData's HAuth.product_user_id default now uses
EOSGRuntime.local_product_user_id, removing an unused high-level dependency.

Before SDK shutdown, the game closes peers, clears lobby handles, and disconnects
EOSG's native process_frame mediator. Search callables must release their native
RefCounted search handles before shutdown; retaining them causes an exit crash.
