# VoyageRoom reliability review — November 16, 2026

The dashboard showed historical errors but no retained event details. Their
cause is unconfirmed; the following is a separately reproduced defect.

- Sending JSON `null` over an admitted WebSocket threw `Cannot read properties
  of null (reading 'type')` in `webSocketMessage`. Control messages now require
  an object with a string type. Invalid values close only that connection with
  code 1008. The regression covers null, arrays, numbers, strings and invalid
  type values, and checks that the captain remains responsive.
- Socket attachment initialization now reuses the already computed ticket hash,
  avoiding an asynchronous gap after socket acceptance.
- Connection admission explicitly rejects an ended room.

Validation: TypeScript check and Worker deployment dry run passed. All 17 service
checks passed. Four real headless Godot clients passed with 9.98 host packets/s,
2.67 guest packets/s, 125 snapshots per guest and under four pixels maximum
prediction correction. The three-client gameplay regression passed 51 checks.
A three-minute local transport test held 60 connections in 15 crews, delivered
74,745 snapshots and reported zero errors; projected gameplay request units were
56,046/hour. These are local tests, not school Wi-Fi or a full classroom-duration
endurance test. Existing gameplay, protocol and traffic intervals are unchanged.
