# missilSLBM-misterplace (SLBM blocks)

Space Engineers 1 data mod: submarine-launched missile block. Depends on the brain mod
[../missil-misterplace](../missil-misterplace/CLAUDE.md). Workspace overview: [../CLAUDE.md](../CLAUDE.md).

## Docs
- [README.md](README.md): quick start, first dev publish
- [docs/contents.md](docs/contents.md): what the mod defines, and its dependency on the brain
- [../missil-misterplace/docs/deployment.md](../missil-misterplace/docs/deployment.md): dev/final deploy rules (shared by all mods)

## Rules
- Edit only inside `Mod/`. Never edit the copies in `%APPDATA%\SpaceEngineers\Mods` directly.
- Deploy with `.\deploy.ps1 dev`. Run `.\deploy.ps1 final` only when the user asks for a release.
- `Mod/modinfo.sbmi` is generated and git-ignored. The dev target has no Workshop ID until the first dev publish;
  never copy the final ID (3685206054) into the dev target.
- Ammo subtypes are looked up by name in the brain's code; keep `docs/contents.md` in sync with the brain's docs.
- Keep the docs current whenever behaviour, layout or the workflow changes.
