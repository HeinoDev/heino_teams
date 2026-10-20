## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)

Works with ESX (`es_extended`) and QBox (`qbx_core`), detected automatically. Without either it runs standalone and uses the FiveM player name.

## Installation

1. Put the resource in your `resources` folder.
2. Add to `server.cfg` after your framework:

```cfg
ensure ox_lib
ensure es_extended / qbx_core
ensure heino_teams
```

## Configuration

Edit `config.lua`:

| Key | Default | Description |
| --- | --- | --- |
| `Locale` | `'en'` | Language file in `locales/` |
| `Framework` | `'auto'` | `'auto'`, `'esx'`, `'qbox'` or `'standalone'` |
| `Command` | `'teams'` | Command that opens the window |
| `MaxSize` | `4` | Maximum members per team, leader included |
| `InviteTimeout` | `30000` | Invite lifetime in milliseconds |
| `InviteCooldown` | `3000` | Delay between invites from one leader, in milliseconds |
| `InviteDistance` | `50.0` | Maximum distance in meters for inviting or joining |

## Exports

Server-side only. Call with `exports.heino_teams:<Name>(...)`, where `source` is a player's server ID.

| Export | Arguments | Returns |
| --- | --- | --- |
| `CreateTeam` | `source` | `teamId` or `nil, error` |
| `InvitePlayer` | `source, targetId` | `true` or `false, error` |
| `AcceptInvite` | `source` | `true` or `false, error` |
| `DeclineInvite` | `source` | nothing |
| `LeaveTeam` | `source` | `true` |
| `IsInTeam` | `source` | `boolean` |
| `GetTeam` | `source` | team table `{ id, leader, maxSize, members }` or `nil` |
| `GetTeamMembers` | `source` | array of server IDs, or `{ source }` if not in a team |
| `ForEachTeamMember` | `source, fn` | nothing. Calls `fn(memberId)` for each member |

`error` is one of `alreadyInTeam`, `invalidTarget`, `notInTeam`, `notLeader`, `teamFull`, `targetInTeam`, `tooFar`, `tooFast`, `noInvite`, `teamGone`.

`GetTeam` returns the live team table. Treat it as read-only and change teams only through the exports.

## Locales

To add a language, copy `locales/en.json` to `locales/<code>.json`, translate both sections, and set `Locale` in `config.lua`. UI placeholders use `{name}`, notification placeholders use `%s`.

## Development

The UI is a Svelte 5 app in `web/`. The resource loads `web/build`, so rebuild after UI changes:

```bash
cd web
bun install (npm also works if you dont have bun)
bun run dev
bun run build
```

## Contributing

Feel free to contribute if you see any room for improvement.
