# Menu soundtrack

`menu_theme.ogg` is the audio track extracted from the user-provided
`ScreenRecording_11-15-2026 21-27-14_1.mp4` on November 15, 2026.
The video remains outside the repository. The complete first audio stream was
encoded as stereo Ogg Vorbis quality 5 with metadata removed (about 159 seconds,
3 MB). No gameplay tracks have been supplied or added yet.

Extraction command (FFmpeg executable location depends on the developer):

```text
ffmpeg -i "ScreenRecording_11-15-2026 21-27-14_1.mp4" -map 0:a:0 -vn -map_metadata -1 -c:a libvorbis -q:a 5 menu_theme.ogg
```

`GameWindow` loads this file, enables looping, and routes it through the Music
bus. It plays on the title screen and its crew/settings panels, stops when solo
or multiplayer gameplay starts, and does not play in the in-game pause menu.
Browser playback starts on a user click/key gesture to satisfy autoplay policy.
Master/Music volume and mute-when-unfocused preferences continue to apply.
Replace the file or loading path when a new menu track is supplied. Gameplay
music should use a separate lifecycle so pause/UI clicks cannot start this song.
