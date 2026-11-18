# missilSLBM-misterplace (SLBM blocks)

Submarine-launched missile blocks for the MisterWeapon modpack (Space Engineers 1). Data only, no scripts.
It depends on the brain mod [missil-misterplace](../missil-misterplace/README.md), which provides the guidance
logic and underwater behaviour.

| Target | Local folder in `%APPDATA%\SpaceEngineers\Mods` | Workshop ID |
|---|---|---|
| dev   | `missilSLBM-misterplace-dev` | none yet (created by the first dev Publish) |
| final | `missilSLBM-misterplace`     | 3685206054 |

## Quick start
```powershell
.\deploy.ps1 dev            # junction Mods\missilSLBM-misterplace-dev -> Mod\ (live edits)
.\deploy.ps1 final -DryRun  # preview a release
.\deploy.ps1 final          # needs a clean git tree; copies a snapshot, tags release/<date>
```
Then publish from the game's Mods screen. Never load dev and final in the same world.
Deploy details: [../missil-misterplace/docs/deployment.md](../missil-misterplace/docs/deployment.md).

## First dev publish
There is no dev Workshop item yet. `deploy.ps1 dev` writes a `modinfo.sbmi` without an ID, so the first
**Publish** of `missilSLBM-misterplace-dev` creates a new item. Afterwards the game writes the new ID into
`Mod/modinfo.sbmi` and deploys keep it. Copy that ID into `targets.dev.workshopId` in `deploy.json` and commit,
so the ID is recorded in git.

## Layout
- `Mod/`: everything that ships (Data, Textures, metadata.mod)
- `deploy.json` / `deploy.ps1`: deploy targets and script
- `docs/`: documentation

## Docs
- [Contents](docs/contents.md)
