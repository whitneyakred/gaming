# Shared galley cooking

Walk next to the galley and press **E**, then **Prepare fish**. One raw **Fish**
starts the teammate's cooking activity from `main`: slice potato, add pieces,
slice fish, add pieces, and control heat. The refreshed teammate version skips water. Follow its on-screen guide
and **Serve** to finish. The activity runs locally, so pointer motion does not
wait on the network. A successful served meal gives one **Cooked Fish**; a served
zero-star result burns it.

One sailor prepares at a time. Others see that the galley is occupied. **Close**,
**E**, **Esc**, walking away, death or disconnect releases the attempt and returns
unfinished fish. The host limits an attempt to two minutes; cancel/reopen if you
need to start over. Inventory overflow drops items at the sailor's feet.

The fuel/grate version is preserved on `backup/furnace-cooking-before-minigame`
(`2c77de2`). Existing saved furnace food and unused fuel are accessible with
**Recover stored food / fuel**. No fuel is required by the new activity; the
preparation ingredients are supplied by the minigame. Internal `fish_cod` and
`dried_fish` IDs remain compatible with existing inventory and food systems.

See [shared gameplay](shared-gameplay.md) for authority, save migration, duplicate
reward protection, testing and the client-side cooking score trust boundary.
