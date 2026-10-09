/* ************************************************************************
   MY Regicide: King rules
   Part of the MY mod for Age of Empires II: Definitive Edition.
   Loaded by MY_Regicide.rms through #includeXS; main() runs once when the
   map is generated.

   Turns the King into a frontline warrior with a leadership aura.
   Also removes the Spies/Treason technology from the Castle.
   Also runs the MY cavalry system (see "Cavalry" below).

   The King's death still defeats its owner (handled by the map and by
   the Regicide game mode, not here).

   Order matters: the engine "freezes" a unit for non-task changes once an
   aura task is added, so stats are set first, then tasks, then auras.
   ************************************************************************ */

/* ---------- Tunable values ---------- */

const int cMyKing = 434;
const int cMyKnight = 38;  /* attack animation donor if the King has none */
const int cMySpiesTreason = 408;  /* Castle tech, removed in MY */

const float cMyKingHitpoints = 250.0;
const int cMyKingMeleeAttack = 12;
const float cMyKingReloadTime = 2.0;
const int cMyKingMeleeArmor = 3;
const int cMyKingPierceArmor = 3;

const float cMyAuraRange = 6.0;           /* tiles */
const float cMyAuraAttackBonus = 2.0;     /* added to attack */
const float cMyAuraReloadFactor = 0.85;   /* 15% faster attacks */

/* ---------- Constants ---------- */

const int cMyDamageClassPierce = 3;
const int cMyDamageClassMelee = 4;

const int cMyHeroFlagSelfRegeneration = 4;
const int cMyCombatAbilityAura = 32;
const int cMyCombatAbilityAuraSelf = 64;

const int cMyAuraBitMultiply = 1;
const int cMyAuraBitCircular = 2;
const int cMyAuraBitRangeIndicator = 4;
const int cMyAuraBitAdvancedRangeIndicator = 32;

const int cMyOwnerYou = 1;
const int cMyOwnerGaiaYouAlly = 4;
const int cMyOwnerGaiaNeutralEnemy = 5;

/* ---------- Helpers ---------- */

bool myHasBit(int value = 0, int bit = 1) {
    return (((value / bit) % 2) == 1);
}

bool myKingHasCombatTask(int player = -1) {
    int count = xsGetObjectTaskCount(cMyKing, player);
    int i = 0;
    while (i < count) {
        if (xsObjectTaskAmount(cMyKing, player, i)) {
            if (xsGetTaskAmount(cTaskAttrTaskType) == cTaskTypeCombat) {
                return (true);
            }
        }
        i++;
    }
    return (false);
}

void myAppendTask(int objectId = -1, int player = -1) {
    xsModifyObjectTasks(objectId, player, xsGetObjectTaskCount(objectId, player));
}

/* Gives the King a melee attack class and animation when the base data has
   no combat task. Returns true when the combat task still has to be added. */
bool myPrepareKingCombat(int player = -1) {
    if (myKingHasCombatTask(player)) {
        return (false);
    }

    xsEffectAmount(cSetAttribute, cMyKing, cAddAttackType, cMyDamageClassMelee, player);

    int attackGraphic = xsGetObjectAttribute(player, cMyKing, cAttackGraphic);
    if (attackGraphic < 0) {
        xsEffectAmount(cSetAttribute, cMyKing, cAttackGraphic, xsGetObjectAttribute(player, cMyKnight, cAttackGraphic), player);
        xsEffectAmount(cSetAttribute, cMyKing, cAttackDelay, xsGetObjectAttribute(player, cMyKnight, cAttackDelay), player);
    }
    xsEffectAmount(cSetAttribute, cMyKing, cMaxRange, 0, player);
    xsEffectAmount(cSetAttribute, cMyKing, cAccuracyPercent, 100, player);
    return (true);
}

void myAddKingCombatTask(int player = -1) {
    xsResetTaskAmount();
    xsTaskAmount(cTaskAttrTaskType, 0.0 + cTaskTypeCombat);
    xsTaskAmount(cTaskAttrObjectId, -1.0);
    xsTaskAmount(cTaskAttrObjectClass, -1.0);
    xsTaskAmount(cTaskAttrOwnerType, 0.0 + cMyOwnerGaiaNeutralEnemy);
    xsTaskAmount(cTaskAttrSearchWaitTime, 3.0);
    xsTaskAmount(cTaskAttrEnableTargeting, 1.0);
    myAppendTask(cMyKing, player);
}

void myApplyKingStats(int player = -1) {
    xsEffectAmount(cSetAttribute, cMyKing, cHitpoints, cMyKingHitpoints, player);
    xsEffectAmount(cSetAttribute, cMyKing, cAttackReloadTime, cMyKingReloadTime, player);

    /* Damage classes use the class * 256 + value encoding. */
    xsEffectAmount(cSetAttribute, cMyKing, cAttack, cMyDamageClassMelee * 256 + cMyKingMeleeAttack, player);
    xsEffectAmount(cSetAttribute, cMyKing, cArmor, cMyDamageClassMelee * 256 + cMyKingMeleeArmor, player);
    xsEffectAmount(cSetAttribute, cMyKing, cArmor, cMyDamageClassPierce * 256 + cMyKingPierceArmor, player);

    /* Heals 30 HP per minute when out of combat, like other heroes. */
    int heroStatus = xsGetObjectAttribute(player, cMyKing, cHeroStatus);
    if (heroStatus < 0) {
        heroStatus = 0;
    }
    if (myHasBit(heroStatus, cMyHeroFlagSelfRegeneration) == false) {
        xsEffectAmount(cSetAttribute, cMyKing, cHeroStatus, heroStatus + cMyHeroFlagSelfRegeneration, player);
    }
}

/* Adapted from the AoE2DE UGC Guide's xsAddAura (permanent aura only). */
void myAddKingAura(int player = -1, int affectedClass = -1, int attribute = -1, float value = 0.0, int effectBits = 0) {
    int combatAbility = xsGetObjectAttribute(player, cMyKing, cCombatAbility);
    if (combatAbility < 0) {
        combatAbility = 0;
    }
    int newCombatAbility = combatAbility;
    if (myHasBit(combatAbility, cMyCombatAbilityAura) == false) {
        newCombatAbility = newCombatAbility + cMyCombatAbilityAura;
    }
    if (myHasBit(combatAbility, cMyCombatAbilityAuraSelf)) {
        newCombatAbility = newCombatAbility - cMyCombatAbilityAuraSelf;
    }
    if (newCombatAbility != combatAbility) {
        xsEffectAmount(cSetAttribute, cMyKing, cCombatAbility, newCombatAbility, player);
    }

    xsResetTaskAmount();
    xsTaskAmount(cTaskAttrTaskType, 0.0 + cTaskTypeAura);
    xsTaskAmount(cTaskAttrWorkValue1, value);
    xsTaskAmount(cTaskAttrWorkValue2, 1.0);          /* units in range to turn on */
    xsTaskAmount(cTaskAttrWorkRange, cMyAuraRange);
    xsTaskAmount(cTaskAttrSearchWaitTime, 0.0 + attribute);
    xsTaskAmount(cTaskAttrCombatLevelFlag, 0.0 + effectBits);
    xsTaskAmount(cTaskAttrOwnerType, 0.0 + cMyOwnerGaiaYouAlly);
    xsTaskAmount(cTaskAttrObjectClass, 0.0 + affectedClass);
    myAppendTask(cMyKing, player);
}

void myAddKingAuras(int player = -1, int affectedClass = -1) {
    int shape = cMyAuraBitCircular + cMyAuraBitRangeIndicator + cMyAuraBitAdvancedRangeIndicator;
    myAddKingAura(player, affectedClass, cAttack, cMyAuraAttackBonus, shape);
    myAddKingAura(player, affectedClass, cAttackReloadTime, cMyAuraReloadFactor, shape + cMyAuraBitMultiply);
}

/* ************************************************************************
   Cavalry: soldiers mount horses
   Human players train Light, Medium and Heavy horses at the Stable instead
   of cavalry. A swordsman (Militia line) or archer (Archer line) garrisons
   into one of their own horses and comes out as cavalry:
     swordsman + Light horse  = Scout line (Scout / Light Cavalry / Hussar)
     swordsman + Medium horse = Knight line (Knight / Cavalier / Paladin)
     swordsman + Heavy horse  = Paladin
     archer    + Light horse  = Cavalry Archer line
   Computer players use the same horses. The game's AI keeps ordering
   cavalry at the Stable and Archery Range, but for them that order pays
   for a horse: the trained unit is swapped for a horse, and this script
   sends the AI's nearest swordsman or archer to mount it.
   ************************************************************************ */

const int cMyStable = 101;

const int cMyHorseLight = 814;    /* HORSE */
const int cMyHorseMedium = 1604;  /* HORSEGBR, grey-brown horse */
const int cMyHorseHeavy = 1356;   /* HORSEHVY, armored horse */

const float cMyMountCheckSeconds = 1.0;

/* Horse prices (food, gold) and Stable buttons. */
const int cMyHorseLightFood = 40;
const int cMyHorseLightGold = 0;
const int cMyHorseMediumFood = 40;
const int cMyHorseMediumGold = 50;
const int cMyHorseHeavyFood = 80;
const int cMyHorseHeavyGold = 100;
const float cMyHorseTrainTime = 20.0;

/* Ages in which each horse becomes trainable (1 Feudal, 2 Castle, 3 Imperial). */
const int cMyHorseLightAge = 1;
const int cMyHorseMediumAge = 2;
const int cMyHorseHeavyAge = 3;

const int cMyArcheryRange = 87;

/* Computer players: how many unmounted horses they may have before their
   cavalry orders pause, how far a rider is fetched from, and how often. */
const int cMyAiMaxWaitingHorses = 4;
const float cMyAiRiderSearchTiles = 40.0;
const int cMyAiOrderEverySeconds = 5;

const int cMyMilitia = 74;
const int cMyManAtArms = 75;
const int cMyLongSwordsman = 77;
const int cMyTwoHandedSwordsman = 473;
const int cMyChampion = 567;
const int cMyArcher = 4;
const int cMyCrossbowman = 24;
const int cMyArbalester = 492;

const int cMyScoutCavalry = 448;
const int cMyLightCavalry = 546;
const int cMyHussar = 441;
const int cMyKnightUnit = 38;
const int cMyCavalier = 283;
const int cMyPaladin = 569;
const int cMyCavalryArcher = 39;
const int cMyHeavyCavalryArcher = 474;

const int cMyTechLightCavalry = 254;
const int cMyTechHussar = 428;
const int cMyTechCavalier = 209;
const int cMyTechPaladin = 265;
const int cMyTechHeavyCavalryArcher = 218;

const int cMyTraitGarrisonable = 1;

int gMyHorseAgeReached = -1;  /* per player: highest horse age unlocked */
int gMyHorseIds = -1;         /* reused unit id list, XS arrays cannot be freed */

bool myIsHuman(int player = -1) {
    return (xsGetPlayerType(player) == cPlayerTypeHuman);
}

bool myTechDone(int tech = -1, int player = -1) {
    return (xsGetTechState(tech, player) == cTechStateDone);
}

bool myIsSwordsman(int unitType = -1) {
    return (unitType == cMyMilitia || unitType == cMyManAtArms || unitType == cMyLongSwordsman
        || unitType == cMyTwoHandedSwordsman || unitType == cMyChampion);
}

bool myIsArcher(int unitType = -1) {
    return (unitType == cMyArcher || unitType == cMyCrossbowman || unitType == cMyArbalester);
}

/* Inserts a "garrison into this horse" task first in the soldier's list,
   so right-clicking your own horse mounts it instead of guarding it. */
void myAddMountTask(int soldier = -1, int horse = -1, int player = -1) {
    xsResetTaskAmount();
    xsTaskAmount(cTaskAttrTaskType, 0.0 + cTaskTypeGarrison);
    xsTaskAmount(cTaskAttrObjectId, 0.0 + horse);
    xsTaskAmount(cTaskAttrObjectClass, -1.0);
    xsTaskAmount(cTaskAttrOwnerType, 0.0 + cMyOwnerYou);
    xsTaskAmount(cTaskAttrWorkRange, 1.0);
    xsModifyObjectTasks(soldier, player, 0);
}

/* Lets one soldier garrison into the horse. */
void myMakeHorseRideable(int horse = -1, int player = -1) {
    int traits = xsGetObjectAttribute(player, horse, cTraits);
    if (traits < 0) {
        traits = 0;
    }
    if (myHasBit(traits, cMyTraitGarrisonable) == false) {
        xsEffectAmount(cSetAttribute, horse, cTraits, traits + cMyTraitGarrisonable, player);
    }
    xsEffectAmount(cSetAttribute, horse, cGarrisonCapacity, 1, player);
}

/* Horses, and which soldiers may ride them, for every player. */
void mySetupRiding(int player = -1) {
    myMakeHorseRideable(cMyHorseLight, player);
    myMakeHorseRideable(cMyHorseMedium, player);
    myMakeHorseRideable(cMyHorseHeavy, player);

    /* Swordsmen can ride every horse; archers only the Light horse. */
    int soldiers = xsArrayCreateInt(5, 0, "myMountSwordsmen" + player);
    xsArraySetInt(soldiers, 0, cMyMilitia);
    xsArraySetInt(soldiers, 1, cMyManAtArms);
    xsArraySetInt(soldiers, 2, cMyLongSwordsman);
    xsArraySetInt(soldiers, 3, cMyTwoHandedSwordsman);
    xsArraySetInt(soldiers, 4, cMyChampion);
    int i = 0;
    while (i < 5) {
        myAddMountTask(xsArrayGetInt(soldiers, i), cMyHorseLight, player);
        myAddMountTask(xsArrayGetInt(soldiers, i), cMyHorseMedium, player);
        myAddMountTask(xsArrayGetInt(soldiers, i), cMyHorseHeavy, player);
        i++;
    }
    myAddMountTask(cMyArcher, cMyHorseLight, player);
    myAddMountTask(cMyCrossbowman, cMyHorseLight, player);
    myAddMountTask(cMyArbalester, cMyHorseLight, player);
}

void mySetupHorse(int horse = -1, int player = -1, int food = 0, int gold = 0, int button = 0, string description = "") {
    xsEffectAmount(cSetAttribute, horse, cFoodCost, food, player);
    if (gold > 0) {
        /* Horses only cost food in the base data; add a gold cost slot. */
        xsEffectAmount(cMulAttribute, horse, cGoldCost, -1, player);
        xsEffectAmount(cSetAttribute, horse, cGoldCost, gold, player);
    }
    xsEffectAmount(cSetAttribute, horse, cTrainTime, cMyHorseTrainTime, player);
    xsEffectAmount(cSetAttribute, horse, cTrainButton, button, player);
    xsEffectAmount(cEnableObject, horse, cAttributeEnable, 0, player);
    xsSetObjectDescription(player, horse, description);
}

void myUnlockHorse(int horse = -1, int player = -1) {
    xsEffectAmount(cSetAttribute, horse, cTrainLocation, cMyStable, player);
}

void myRemoveTraining(int unitType = -1, int player = -1) {
    xsEffectAmount(cSetAttribute, unitType, cTrainLocation, -1, player);
}

void mySetupCavalryForHuman(int player = -1) {
    mySetupHorse(cMyHorseLight, player, cMyHorseLightFood, cMyHorseLightGold, 6,
        "Light horse: fast, no armor. Garrison a swordsman to make Scout cavalry, or an archer to make a Cavalry Archer.");
    mySetupHorse(cMyHorseMedium, player, cMyHorseMediumFood, cMyHorseMediumGold, 7,
        "Medium horse: armored like a knight. Garrison a swordsman to make a Knight.");
    mySetupHorse(cMyHorseHeavy, player, cMyHorseHeavyFood, cMyHorseHeavyGold, 8,
        "Heavy horse: fully armored. Garrison a swordsman to make a Paladin.");

    /* Cavalry only comes from mounting. */
    myRemoveTraining(cMyScoutCavalry, player);
    myRemoveTraining(cMyLightCavalry, player);
    myRemoveTraining(cMyHussar, player);
    myRemoveTraining(cMyKnightUnit, player);
    myRemoveTraining(cMyCavalier, player);
    myRemoveTraining(cMyPaladin, player);
    myRemoveTraining(cMyCavalryArcher, player);
    myRemoveTraining(cMyHeavyCavalryArcher, player);
}

/* Computer players pay horse prices for the cavalry they order, since
   what they actually get is a horse. */
void mySetupCavalryForComputer(int player = -1) {
    xsEffectAmount(cSetAttribute, cMyScoutCavalry, cFoodCost, cMyHorseLightFood, player);
    xsEffectAmount(cSetAttribute, cMyLightCavalry, cFoodCost, cMyHorseLightFood, player);
    xsEffectAmount(cSetAttribute, cMyHussar, cFoodCost, cMyHorseLightFood, player);

    xsEffectAmount(cSetAttribute, cMyKnightUnit, cFoodCost, cMyHorseMediumFood, player);
    xsEffectAmount(cSetAttribute, cMyKnightUnit, cGoldCost, cMyHorseMediumGold, player);
    xsEffectAmount(cSetAttribute, cMyCavalier, cFoodCost, cMyHorseMediumFood, player);
    xsEffectAmount(cSetAttribute, cMyCavalier, cGoldCost, cMyHorseMediumGold, player);
    xsEffectAmount(cSetAttribute, cMyPaladin, cFoodCost, cMyHorseMediumFood, player);
    xsEffectAmount(cSetAttribute, cMyPaladin, cGoldCost, cMyHorseMediumGold, player);
}

/* Which cavalry a soldier becomes on a horse, at the player's current
   upgrade level. Returns -1 when the pair cannot mount. */
int myMountedType(int soldierType = -1, int horseType = -1, int player = -1) {
    if (myIsArcher(soldierType)) {
        if (horseType != cMyHorseLight) {
            return (-1);
        }
        if (myTechDone(cMyTechHeavyCavalryArcher, player)) {
            return (cMyHeavyCavalryArcher);
        }
        return (cMyCavalryArcher);
    }
    if (myIsSwordsman(soldierType) == false) {
        return (-1);
    }
    if (horseType == cMyHorseLight) {
        if (myTechDone(cMyTechHussar, player)) {
            return (cMyHussar);
        }
        if (myTechDone(cMyTechLightCavalry, player)) {
            return (cMyLightCavalry);
        }
        return (cMyScoutCavalry);
    }
    if (horseType == cMyHorseMedium) {
        if (myTechDone(cMyTechPaladin, player)) {
            return (cMyPaladin);
        }
        if (myTechDone(cMyTechCavalier, player)) {
            return (cMyCavalier);
        }
        return (cMyKnightUnit);
    }
    if (horseType == cMyHorseHeavy) {
        return (cMyPaladin);
    }
    return (-1);
}

/* ---------- Computer players ---------- */

int gMyKnownCavalry = -1;     /* cavalry that must not be swapped for a horse */
int gMyKnownCavalryCount = 0;
int gMyArcherHorses = -1;     /* AI horses bought with a Cavalry Archer order */
int gMyArcherHorsesCount = 0;
int gMyUsedRiders = -1;       /* riders already sent to a horse this pass */
int gMyUsedRidersCount = 0;
int gMyCavalryIds = -1;       /* reused unit id lists */
int gMyRiderIds = -1;
int gMyOrderIds = -1;
int gMyAiTrainingPaused = -1; /* per player: 1 while cavalry orders are paused */
bool gMyAiStarted = false;
int gMyAiTick = 0;

bool myListHas(int list = -1, int count = 0, int value = -1) {
    int i = 0;
    while (i < count) {
        if (xsArrayGetInt(list, i) == value) {
            return (true);
        }
        i++;
    }
    return (false);
}

/* Appends to a list, growing it as needed. Returns the new count. */
int myListAdd(int list = -1, int count = 0, int value = -1) {
    if (count >= xsArrayGetSize(list)) {
        xsArrayResizeInt(list, count * 2 + 16);
    }
    xsArraySetInt(list, count, value);
    return (count + 1);
}

/* Drops units that no longer exist. Returns the new count. */
int myListCompact(int list = -1, int count = 0) {
    int kept = 0;
    int i = 0;
    int value = -1;
    while (i < count) {
        value = xsArrayGetInt(list, i);
        if (xsDoesUnitExist(value)) {
            xsArraySetInt(list, kept, value);
            kept++;
        }
        i++;
    }
    return (kept);
}

void myKnownCavalryAdd(int unit = -1) {
    gMyKnownCavalryCount = myListAdd(gMyKnownCavalry, gMyKnownCavalryCount, unit);
}

void myMountRiders(int player = -1, int horseType = -1) {
    int horses = xsGetPlayerUnitIds(player, horseType, gMyHorseIds);
    int count = xsArrayGetSize(horses);
    int i = 0;
    int horse = -1;
    int riders = -1;
    int rider = -1;
    int mountedType = -1;
    int mounted = -1;
    vector position = cOriginVector;
    while (i < count) {
        horse = xsArrayGetInt(horses, i);
        riders = xsGetGarrisonedUnitIds(horse);
        if (xsArrayGetSize(riders) > 0) {
            rider = xsArrayGetInt(riders, 0);
            mountedType = myMountedType(xsGetUnitObjectId(rider), horseType, player);
            if (mountedType >= 0) {
                /* Create the rider first so nothing is lost if it fails. */
                position = xsGetUnitPosition(horse);
                mounted = xsCreateUnit(mountedType, player, position, false, true, false);
                if (mounted >= 0) {
                    xsRemoveUnit(rider);
                    xsRemoveUnit(horse);
                    myKnownCavalryAdd(mounted);
                }
            }
        }
        i++;
    }
}

void myUnlockHorsesByAge(int player = -1) {
    int age = xsPlayerAttribute(player, cAttributeCurrentAge);
    int reached = xsArrayGetInt(gMyHorseAgeReached, player);
    if (age > reached) {
        if (age >= cMyHorseLightAge && reached < cMyHorseLightAge) {
            myUnlockHorse(cMyHorseLight, player);
        }
        if (age >= cMyHorseMediumAge && reached < cMyHorseMediumAge) {
            myUnlockHorse(cMyHorseMedium, player);
        }
        if (age >= cMyHorseHeavyAge && reached < cMyHorseHeavyAge) {
            myUnlockHorse(cMyHorseHeavy, player);
        }
        xsArraySetInt(gMyHorseAgeReached, player, age);
    }
}

bool myIsComputer(int player = -1) {
    return (xsGetPlayerType(player) == cPlayerTypeComputer);
}

/* Remembers every cavalry unit a player already owns (the starting Scout). */
void myAiRegisterCavalry(int player = -1, int unitType = -1) {
    int units = xsGetPlayerUnitIds(player, unitType, gMyCavalryIds);
    int count = xsArrayGetSize(units);
    int i = 0;
    while (i < count) {
        myKnownCavalryAdd(xsArrayGetInt(units, i));
        i++;
    }
}

/* Swaps freshly trained cavalry for the horse it paid for. */
void myAiSwapForHorses(int player = -1, int unitType = -1, int horseType = -1, bool forArcher = false) {
    int units = xsGetPlayerUnitIds(player, unitType, gMyCavalryIds);
    int count = xsArrayGetSize(units);
    int i = 0;
    int unit = -1;
    int horse = -1;
    while (i < count) {
        unit = xsArrayGetInt(units, i);
        if (myListHas(gMyKnownCavalry, gMyKnownCavalryCount, unit) == false) {
            horse = xsCreateUnit(horseType, player, xsGetUnitPosition(unit), false, false, false);
            if (horse >= 0) {
                xsRemoveUnit(unit);
                if (forArcher) {
                    gMyArcherHorsesCount = myListAdd(gMyArcherHorses, gMyArcherHorsesCount, horse);
                }
            } else {
                myKnownCavalryAdd(unit);
            }
        }
        i++;
    }
}

int myAiKnightHorse(int player = -1) {
    if (myTechDone(cMyTechPaladin, player)) {
        return (cMyHorseHeavy);
    }
    return (cMyHorseMedium);
}

float myDistance(vector a = cOriginVector, vector b = cOriginVector) {
    float dx = xsVectorGetX(a) - xsVectorGetX(b);
    float dy = xsVectorGetY(a) - xsVectorGetY(b);
    return (sqrt(dx * dx + dy * dy));
}

/* Nearest unused soldier of one type to a spot, or -1. */
int myNearestRider(int player = -1, int soldierType = -1, vector spot = cOriginVector, float maxDistance = 0.0) {
    int units = xsGetPlayerUnitIds(player, soldierType, gMyRiderIds);
    int count = xsArrayGetSize(units);
    int best = -1;
    float bestDistance = maxDistance;
    float distance = 0.0;
    int unit = -1;
    int i = 0;
    while (i < count) {
        unit = xsArrayGetInt(units, i);
        if (xsGetGarrisonedInUnitId(unit) < 0) {
            if (myListHas(gMyUsedRiders, gMyUsedRidersCount, unit) == false) {
                distance = myDistance(xsGetUnitPosition(unit), spot);
                if (distance <= bestDistance) {
                    best = unit;
                    bestDistance = distance;
                }
            }
        }
        i++;
    }
    return (best);
}

int myNearestSwordsman(int player = -1, vector spot = cOriginVector) {
    int best = -1;
    int candidate = -1;
    float range = cMyAiRiderSearchTiles;
    candidate = myNearestRider(player, cMyChampion, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyTwoHandedSwordsman, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyLongSwordsman, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyManAtArms, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyMilitia, spot, range);
    if (candidate >= 0) { best = candidate; }
    return (best);
}

int myNearestArcher(int player = -1, vector spot = cOriginVector) {
    int best = -1;
    int candidate = -1;
    float range = cMyAiRiderSearchTiles;
    candidate = myNearestRider(player, cMyArbalester, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyCrossbowman, spot, range);
    if (candidate >= 0) { best = candidate; range = myDistance(xsGetUnitPosition(candidate), spot); }
    candidate = myNearestRider(player, cMyArcher, spot, range);
    if (candidate >= 0) { best = candidate; }
    return (best);
}

/* Sends a rider to every empty horse. Returns how many horses wait. */
int myAiSendRiders(int player = -1, int horseType = -1) {
    int horses = xsGetPlayerUnitIds(player, horseType, gMyHorseIds);
    int count = xsArrayGetSize(horses);
    int waiting = 0;
    int horse = -1;
    int rider = -1;
    vector spot = cOriginVector;
    int i = 0;
    while (i < count) {
        horse = xsArrayGetInt(horses, i);
        if (xsArrayGetSize(xsGetGarrisonedUnitIds(horse)) == 0) {
            waiting++;
            spot = xsGetUnitPosition(horse);
            rider = -1;
            if (horseType == cMyHorseLight && myListHas(gMyArcherHorses, gMyArcherHorsesCount, horse)) {
                rider = myNearestArcher(player, spot);
            }
            if (rider < 0) {
                rider = myNearestSwordsman(player, spot);
            }
            if (rider < 0 && horseType == cMyHorseLight) {
                rider = myNearestArcher(player, spot);
            }
            if (rider >= 0) {
                gMyUsedRidersCount = myListAdd(gMyUsedRiders, gMyUsedRidersCount, rider);
                xsArraySetInt(gMyOrderIds, 0, rider);
                xsTaskUnits(gMyOrderIds, cActionTypeGarrison, spot, horse);
            }
        }
        i++;
    }
    return (waiting);
}

void mySetAiCavalryTraining(int player = -1, bool allowed = true) {
    int stable = -1;
    int range = -1;
    if (allowed) {
        stable = cMyStable;
        range = cMyArcheryRange;
    }
    xsEffectAmount(cSetAttribute, cMyScoutCavalry, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyLightCavalry, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyHussar, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyKnightUnit, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyCavalier, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyPaladin, cTrainLocation, stable, player);
    xsEffectAmount(cSetAttribute, cMyCavalryArcher, cTrainLocation, range, player);
    xsEffectAmount(cSetAttribute, cMyHeavyCavalryArcher, cTrainLocation, range, player);
}

void myAiCavalry(int player = -1, bool sendRiders = false) {
    int waiting = 0;
    bool paused = false;
    myAiSwapForHorses(player, cMyScoutCavalry, cMyHorseLight, false);
    myAiSwapForHorses(player, cMyLightCavalry, cMyHorseLight, false);
    myAiSwapForHorses(player, cMyHussar, cMyHorseLight, false);
    myAiSwapForHorses(player, cMyKnightUnit, myAiKnightHorse(player), false);
    myAiSwapForHorses(player, cMyCavalier, myAiKnightHorse(player), false);
    myAiSwapForHorses(player, cMyPaladin, myAiKnightHorse(player), false);
    myAiSwapForHorses(player, cMyCavalryArcher, cMyHorseLight, true);
    myAiSwapForHorses(player, cMyHeavyCavalryArcher, cMyHorseLight, true);

    if (sendRiders) {
        waiting = waiting + myAiSendRiders(player, cMyHorseLight);
        waiting = waiting + myAiSendRiders(player, cMyHorseMedium);
        waiting = waiting + myAiSendRiders(player, cMyHorseHeavy);

        /* Stop buying horses nobody can ride yet. */
        paused = (xsArrayGetInt(gMyAiTrainingPaused, player) == 1);
        if (waiting >= cMyAiMaxWaitingHorses && paused == false) {
            mySetAiCavalryTraining(player, false);
            xsArraySetInt(gMyAiTrainingPaused, player, 1);
        } else if (waiting < cMyAiMaxWaitingHorses && paused) {
            mySetAiCavalryTraining(player, true);
            xsArraySetInt(gMyAiTrainingPaused, player, 0);
        }
    }
}

void myAiStart() {
    int player = 1;
    while (player <= 8) {
        if (myIsComputer(player)) {
            myAiRegisterCavalry(player, cMyScoutCavalry);
            myAiRegisterCavalry(player, cMyLightCavalry);
            myAiRegisterCavalry(player, cMyHussar);
            myAiRegisterCavalry(player, cMyKnightUnit);
            myAiRegisterCavalry(player, cMyCavalier);
            myAiRegisterCavalry(player, cMyPaladin);
            myAiRegisterCavalry(player, cMyCavalryArcher);
            myAiRegisterCavalry(player, cMyHeavyCavalryArcher);
        }
        player++;
    }
    gMyAiStarted = true;
}

rule myCavalryMounting
    active
    minInterval 1
    maxInterval 1
{
    int player = 1;
    if (gMyHorseAgeReached < 0) {
        player = 9;  /* main() has not run yet */
    }
    if (player <= 8) {
        if (gMyAiStarted == false) {
            myAiStart();
        }
        gMyAiTick++;
        gMyUsedRidersCount = 0;
        if (gMyAiTick % cMyAiOrderEverySeconds == 0) {
            gMyKnownCavalryCount = myListCompact(gMyKnownCavalry, gMyKnownCavalryCount);
            gMyArcherHorsesCount = myListCompact(gMyArcherHorses, gMyArcherHorsesCount);
        }
    }
    while (player <= 8) {
        if (myIsHuman(player)) {
            myUnlockHorsesByAge(player);
        }
        if (myIsComputer(player)) {
            myAiCavalry(player, gMyAiTick % cMyAiOrderEverySeconds == 0);
        }
        if (myIsHuman(player) || myIsComputer(player)) {
            myMountRiders(player, cMyHorseLight);
            myMountRiders(player, cMyHorseMedium);
            myMountRiders(player, cMyHorseHeavy);
        }
        player++;
    }
}

void mySetupCavalry() {
    gMyHorseIds = xsArrayCreateInt(0, 0, "myHorseIds");
    gMyCavalryIds = xsArrayCreateInt(0, 0, "myCavalryIds");
    gMyRiderIds = xsArrayCreateInt(0, 0, "myRiderIds");
    gMyOrderIds = xsArrayCreateInt(1, -1, "myOrderIds");
    gMyKnownCavalry = xsArrayCreateInt(64, -1, "myKnownCavalry");
    gMyArcherHorses = xsArrayCreateInt(16, -1, "myArcherHorses");
    gMyUsedRiders = xsArrayCreateInt(16, -1, "myUsedRiders");
    gMyAiTrainingPaused = xsArrayCreateInt(9, 0, "myAiTrainingPaused");
    gMyHorseAgeReached = xsArrayCreateInt(9, 0, "myHorseAgeReached");
    int player = 1;
    while (player <= 8) {
        mySetupRiding(player);
        if (myIsHuman(player)) {
            mySetupCavalryForHuman(player);
        } else if (myIsComputer(player)) {
            mySetupCavalryForComputer(player);
        }
        player++;
    }
}

void main() {
    int player = 1;
    bool needsCombatTask = false;
    while (player <= 8) {
        xsEffectAmount(cDisableTech, cMySpiesTreason, 0, 0, player);

        needsCombatTask = myPrepareKingCombat(player);
        myApplyKingStats(player);
        if (needsCombatTask) {
            myAddKingCombatTask(player);
        }

        /* Military unit classes that get the leadership aura. */
        myAddKingAuras(player, cArcherClass);
        myAddKingAuras(player, cInfantryClass);
        myAddKingAuras(player, cCavalryClass);
        myAddKingAuras(player, cConquistadorClass);
        myAddKingAuras(player, cWarElephantClass);
        myAddKingAuras(player, cElephantArcherClass);
        myAddKingAuras(player, cCavalryArcherClass);
        myAddKingAuras(player, cHandCannoneerClass);
        myAddKingAuras(player, cTwoHandedSwordsmanClass);
        myAddKingAuras(player, cPikemanClass);
        myAddKingAuras(player, cScoutCavalryClass);
        myAddKingAuras(player, cSpearmanClass);
        myAddKingAuras(player, cRaiderClass);
        myAddKingAuras(player, cCavalryRaiderClass);

        player++;
    }

    mySetupCavalry();
}
