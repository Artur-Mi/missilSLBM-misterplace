# Contents

A data-only mod (no scripts). Everything is in `Mod/Data/`.

| Item | Subtype | Notes |
|---|---|---|
| Block (`SmallMissileLauncher`) | `LargeMissileLauncherSLBM` | "Lança-Mísseis SLBM"; works only underwater (see Water config) |
| Weapon definition | `LargeMissileLauncherA` | Used by the block |
| Ammo | `AMissile` (speed 100 to 200, explosion radius 8) | Guided by the brain's code; the brain gives it special handling |
| Ammo | `WaterMissile` | Second ammo definition |
| Magazine and blueprint | `SLBMMissile` | "Míssil SLBM" |
| Water config | `WaterConfig.xml` | Block is `FunctionalUnderwater=true`, `FunctionalAboveWater=false` (Jakaria's Water Mod) |

Other files: `BlockCategories.sbc`, `BlockVariantGroups.sbc`, `BlueprintClasses.sbc` and `EntityContainer.sbc`
register the block in the Weapons category and the build UI.

## Underwater-only enforcement

`WaterConfig.xml` makes the block underwater-only through the Water Mod, which only tests the block's origin cell and does
nothing where there is no water. The brain's `AquaticLauncher` also switches the block off whenever its **muzzle** is not
under water (including space), as long as the Water Mod is loaded
([details](../../missil-misterplace/docs/architecture.md)).

## Dependency on the brain

The behaviour of `AMissile` lives in the brain ([../../missil-misterplace/docs/architecture.md](../../missil-misterplace/docs/architecture.md)),
which looks ammo up by subtype name. If an ammo subtype here is renamed or added, update the brain
and both docs. On the Workshop, the dev SLBM item must list the dev brain as a required item, and the
final SLBM item the final brain.

## Models

The block reuses vanilla rocket launcher models (`Models\Cubes\Large\RocketLauncher*.mwm`), so the repo has no
`Models/` folder. Binary assets would go through Git LFS (see `.gitattributes`).
