# Windows development

Use `.\windows.ps1` from PowerShell for builds, tests, packaging and installation; the README lists the actions and dependencies. The restored repository contains uncommitted development work: preserve it. Windows-generated build files live under `.cache/windows`, separate from the restored Linux outputs. The installed game may already contain Play As and other mods; preserve player settings, choices and portraits when installing, and do not install while the game is running.
