/* ************************************************************************
   MY Regicide: King rules
   Part of the MY mod for Age of Empires II: Definitive Edition.
   Loaded by MY_Regicide.rms through #includeXS; main() runs once when the
   map is generated.

   Turns the King into a frontline warrior with a leadership aura.
   The King's death still defeats its owner (handled by the map and by
   the Regicide game mode, not here).

   Order matters: the engine "freezes" a unit for non-task changes once an
   aura task is added, so stats are set first, then tasks, then auras.
   ************************************************************************ */

/* ---------- Tunable values ---------- */

const int cMyKing = 434;
const int cMyKnight = 38;  /* attack animation donor if the King has none */

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

const int cMyOwnerAll = 0;
const int cMyOwnerGaiaYouAlly = 4;

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
    xsTaskAmount(cTaskAttrOwnerType, 0.0 + cMyOwnerAll);
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

void main() {
    int player = 1;
    bool needsCombatTask = false;
    while (player <= 8) {
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
}
