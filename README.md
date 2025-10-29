# EZLoot

Turboloot style looting for EZ Server done in lua.

Requires MQNext and MQ2MoveUtils.

Comes with a preconfigured JSON file for up to Tier 7 (loping plains) preconfigured looting for both main characters and bots.

## How to use

Run `/lua run ezloot/loot` to run the standard looting routine for your main character. This will loot all useful goodies and high value platinum items.

**THE FIRST TIME YOU RUN:** You will be prompted to install cjson. This is expected and you should only have to do this once. DO NOT INSTALL ANY PACKAGES YOU DO NOT RECOGNIZE.

`/lua run ezloot/loot bots` will run it but omit picking up goodies and high value plat items, sticking to only what is defined specifically for that charcter or class.

`/lua run ezloot/loot {tags}` will add whatever `tags` you have added to the loot list. Can be specific for a zone, tier, or global.

### Example 1:

`/lua run ezloot/loot bot charms` will have a character skip over most plat items and goodies and only loot up to 25 of each charm type, or items defined specifically for that class/character.

### Example 2:

`/lua run ezloot/loot pages` will have a character grab all goodies, plat, and the epic pages specific for that zone.

## JSON Configuration:

Inside the layout loot is defined as one of two ways:

1. A single `item` indicates that you will pick up as many of that `item` as possible.
2. A notation of `"item": x` indicates that you should only pick up `x` number of `item`s.

File layout:

- `main`: Things that your main character should loot in any zone at any time. Ommitted when `bots` is passed in as a tag.
- `tags`:
  - `{tag_name}` Global things you may want to specifically tag for such as charms.
- `zone`:
  - `{zone_name}`
    - `main`: Items you might want to pick up that are that zone specific. Ommitted when `bots` is passed in as a tag.
    - `{tag_name}`: tags for items only in that zone that may need to be picked up (like epic pages)
- `characters`:
  - `{character_name}`: Add items here for specific items you may want on specific characters.
- `classes`:
  - `{class_name}`: Add items here for class-specific items you may want.
    You can edit tags and create new ones as desired to your styling.

## Known Issues:

- Rarely, your character will reach a corpse and do nothing. Fix: run `/lua stop` or `/lua stop ezloot/loot` and rerun the script.
- Occasionally, your character will constantly nav to a corpse, but the corpse is descynhed and you'll loop constantly moving to the corpse. Fix: `/say #corpsefix` will fix this issue. May have to be done a few times depending on how bad the corpse pile/desync is. For best results try to use in places with level elevation.
- Very rarely, you will see errors in the window regarding dialog box popups. This doesn't currently seem to actually have any negative impact. No fix yet.
