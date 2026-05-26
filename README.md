# Raid Roster Export

A small World of Warcraft Classic Anniversary addon that exports the current raid or party roster as copyable CSV for attendance tracking.

## Features

- Exports raid or party members with player name, class, and group.
- Includes export metadata: date, time, source addon, format version, and exporting player.
- Normalises player names to `Name-Realm` where realm data is available.
- Opens a copyable in-game text box with the generated CSV.
- Supports an optional attendance date override.

## Installation

Clone or copy this folder into your Classic Anniversary addons directory:

```text
World of Warcraft/_anniversary_/Interface/AddOns/RaidRosterExport
```

Then restart the game or run:

```text
/reload
```

Make sure **Raid Roster Export** is enabled in the AddOns menu.

## Usage

Join a raid or party, then run:

```text
/roster
```

The addon opens a window containing the generated CSV. Press `Ctrl+C` to copy it.

To export attendance for a specific date, pass it as `YYYY/MM/DD`:

```text
/roster 2026/05/26
```

If no date is provided, the addon uses the current local date.

## CSV Format

The export starts with metadata rows, followed by a blank line and roster rows:

```csv
type,raid-attendance
date,2026/05/26
time,20:00:00
source,RaidRosterExport
formatVersion,1
exportedBy,Player-Realm

player,class,group
PlayerOne-Realm,WARRIOR,1
PlayerTwo-Realm,PRIEST,1
```

Players are sorted by group, then by player name.
