# MY: a Regicide mod for Age of Empires II: Definitive Edition

MY adds a new random map, **MY_Regicide**, that changes how a Regicide game starts and plays:

- **No starting Castle.**
- **3 starting villagers** instead of the extra Regicide villagers. Civilization bonuses that add villagers (Chinese, Mayans) still apply.
- **The King is a warrior.** He fights in melee, is much tougher, heals himself out of combat, and gives nearby friendly troops a leadership aura.
- **Losing the King still defeats you.** This holds in the Regicide game mode and also if the map is started in plain Random Map mode.

## King and aura values

| | Default King | MY King |
| :-- | :-- | :-- |
| Hit points | 75 | 250 |
| Melee attack | none | 12 (every 2.0 s) |
| Armor (melee / pierce) | base | 3 / 3 |
| Self-regeneration | no | 30 HP per minute |

**Leadership aura:** friendly and allied military units within **6 tiles** of the King get **+2 attack** and attack **15% faster**. It affects infantry, archers, cavalry, cavalry archers, skirmisher/spear/pike lines, scouts, raiders, elephants, hand cannoneers and conquistadors. The aura range is shown around the King.

All of these numbers are constants at the top of `MY/resources/_common/xs/MY_Regicide.xs` if you want to tune them.

## Install

1. Open your AoE2 DE **profile** mods folder (not the Steam install folder):
   `C:\Users\<your user>\Games\Age of Empires 2 DE\<long number>\mods\local\`
2. Copy the `MY` folder from this repository into it, so you end up with
   `...\mods\local\MY\info.json` and `...\mods\local\MY\resources\...`.
3. Start the game. Under **Mods > My Mods** make sure **MY** is enabled.

## Play

1. Single Player (or Multiplayer) > Skirmish.
2. **Game Mode:** Regicide (Random Map also works; the map always gives you a King and you lose when he dies).
3. **Map Style:** Custom, then pick **MY_Regicide**.
4. Start the game.

In multiplayer every player should have the mod enabled.

## How it works

- `MY/resources/_common/random-map-scripts/MY_Regicide.rms` is an open land (Arabia style) map. It places a Town Center, the normal 3 villagers, a scout and a King, and never creates a Castle. `guard_state KING AMOUNT_GOLD 0 1` makes losing your King a defeat in every game mode.
- `MY/resources/_common/xs/MY_Regicide.xs` is loaded by the map through `#includeXS` and runs once when the map is generated. It upgrades the King's stats, gives him a melee attack task if the base data has none, and adds the aura tasks. Stats are applied before the auras because the engine locks a unit's non-task attributes once an aura is added.

## Limits

- The stock maps (Arabia, Arena, ...) are unchanged and still give the usual Regicide Castle and villagers. MY's rules apply on the MY_Regicide map.
- The mod only uses map scripting and XS, so it does not touch the game's data files and works with game updates as long as these scripting features stay.
