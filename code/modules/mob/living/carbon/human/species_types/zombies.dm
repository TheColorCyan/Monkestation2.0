#define REGENERATION_DELAY 60  // After taking damage, how long it takes for automatic regeneration to begin

/datum/species/zombie
	// 1spooky
	name = "High-Functioning Zombie"
	id = SPECIES_ZOMBIE
	sexes = FALSE
	meat = /obj/item/food/meat/slab/human/mutant/zombie
	mutanttongue = /obj/item/organ/internal/tongue/zombie
	inherent_traits = list(
		// SHARED WITH ALL ZOMBIES
		TRAIT_NO_ZOMBIFY,
		TRAIT_NO_TRANSFORMATION_STING,
		TRAIT_EASILY_WOUNDED,
		TRAIT_EASYDISMEMBER,
		TRAIT_FAKEDEATH,
		TRAIT_NOBREATH,
		TRAIT_NOCLONELOSS,
		TRAIT_NODEATH,
		TRAIT_NOHUNGER,
		TRAIT_LIVERLESS_METABOLISM,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_TOXIMMUNE,
		// monkestation addition: pain system
		TRAIT_ABATES_SHOCK,
		TRAIT_ANALGESIA,
		TRAIT_NO_PAIN_EFFECTS,
		TRAIT_NO_SHOCK_BUILDUP,
		// monkestation end
		// HIGH FUNCTIONING UNIQUE
		TRAIT_NOBLOOD,
		TRAIT_SUCCUMB_OVERRIDE,
	)
	mutantstomach = null
	mutantheart = null
	mutantliver = null
	mutantlungs = null
	inherent_biotypes = MOB_UNDEAD|MOB_HUMANOID
	var/static/list/spooks = list('sound/hallucinations/growl1.ogg','sound/hallucinations/growl2.ogg','sound/hallucinations/growl3.ogg','sound/hallucinations/veryfar_noise.ogg','sound/hallucinations/wail.ogg')
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | ERT_SPAWN
	bodytemp_normal = T0C // They have no natural body heat, the environment regulates body temp
	bodytemp_heat_damage_limit = FIRE_MINIMUM_TEMPERATURE_TO_EXIST // Take damage at fire temp
	bodytemp_cold_damage_limit = MINIMUM_TEMPERATURE_TO_MOVE // take damage below minimum movement temp

	// Infectious zombies have slow legs
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/zombie,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/zombie,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/zombie,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/zombie,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/zombie,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/zombie,
	)

/datum/species/zombie/check_roundstart_eligible()
	if(check_holidays(HALLOWEEN))
		return TRUE
	return ..()

/datum/species/zombie/get_species_description()
	return "A rotting zombie! They descend upon Space Station Thirteen Every year to spook the crew! \"Sincerely, the Zombies!\""

// Override for the default temperature perks, so we can establish that they don't care about temperature very much
/datum/species/zombie/create_pref_temperature_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "thermometer-half",
		SPECIES_PERK_NAME = "No Body Temperature",
		SPECIES_PERK_DESC = "Having long since departed, Zombies do not have anything \
			regulating their body temperature anymore. This means that \
			the environment decides their body temperature - which they don't mind at \
			all, until it gets a bit too hot.",
	))

	return to_add

/datum/species/zombie/infectious
	name = "Infectious Zombie"
	id = SPECIES_ZOMBIE_INFECTIOUS
	examine_limb_id = SPECIES_ZOMBIE
	armor = 20 // 120 damage to KO a zombie, which kills it
	mutanteyes = /obj/item/organ/internal/eyes/zombie
	mutantbrain = /obj/item/organ/internal/brain/zombie
	mutanttongue = /obj/item/organ/internal/tongue/zombie
	changesource_flags = MIRROR_BADMIN | WABBAJACK | ERT_SPAWN
	/// The rate the zombies regenerate at
	var/heal_rate = 0.6
	/// The cooldown before the zombie can start regenerating
	COOLDOWN_DECLARE(regen_cooldown)

	inherent_traits = list(
		// SHARED WITH ALL ZOMBIES
		TRAIT_EASILY_WOUNDED,
		TRAIT_EASYDISMEMBER,
		TRAIT_FAKEDEATH,
		TRAIT_NOBREATH,
		TRAIT_NOCLONELOSS,
		TRAIT_NODEATH,
		TRAIT_NOHUNGER,
		TRAIT_LIVERLESS_METABOLISM,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_TOXIMMUNE,
		// monkestation addition: pain system
		TRAIT_ABATES_SHOCK,
		TRAIT_ANALGESIA,
		TRAIT_NO_PAIN_EFFECTS,
		TRAIT_NO_SHOCK_BUILDUP,
		// monkestation end
		// INFECTIOUS UNIQUE
		TRAIT_STABLEHEART, // Replacement for noblood. Infectious zombies can bleed but don't need their heart.
		TRAIT_STABLELIVER, // Not necessary but for consistency with above
	)
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/zombie,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/zombie,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/zombie,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/zombie,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/zombie/infectious,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/zombie/infectious,
	)


/datum/species/zombie/infectious/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.AddComponent(/datum/component/mutant_hands, mutant_hand_path = hand_path) //monkestation edit: replaces the original mutant_hand_path with hand_path
//monkestation edit start
	for(var/datum/action/granted_action as anything in granted_action_types)
		granted_action = new granted_action
		granted_action.Grant(C)
		granted_actions += granted_action
//monkestation edit end

/datum/species/zombie/infectious/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	. = ..()
	qdel(C.GetComponent(/datum/component/mutant_hands))
//monkestation edit start
	for(var/datum/action/removed_action in granted_actions)
		granted_actions -= removed_action
		removed_action.Remove(C)
		qdel(removed_action)
//monkestation edit end

/datum/species/zombie/infectious/check_roundstart_eligible()
	return FALSE

/datum/species/zombie/infectious/spec_stun(mob/living/carbon/human/H,amount)
	. = min(20, amount)

/datum/species/zombie/infectious/spec_life(mob/living/carbon/C, seconds_per_tick, times_fired)
	. = ..()
	C.set_combat_mode(TRUE) // THE SUFFERING MUST FLOW

	//Zombies never actually die, they just fall down until they regenerate enough to rise back up.
	//They must be restrained, beheaded or gibbed to stop being a threat.
	if(COOLDOWN_FINISHED(src, regen_cooldown))
		var/heal_amt = heal_rate
		if(HAS_TRAIT(C, TRAIT_CRITICAL_CONDITION))
			heal_amt *= 2
		C.heal_overall_damage(heal_amt * seconds_per_tick, heal_amt * seconds_per_tick)
		C.adjustToxLoss(-heal_amt * seconds_per_tick)
		for(var/i in C.all_wounds)
			var/datum/wound/iter_wound = i
			if(SPT_PROB(2-(iter_wound.severity/2), seconds_per_tick))
				iter_wound.remove_wound()
	if(!HAS_TRAIT(C, TRAIT_CRITICAL_CONDITION) && SPT_PROB(2, seconds_per_tick))
		playsound(C, pick(spooks), 50, TRUE, 10)

//Congrats you somehow died so hard you stopped being a zombie
/datum/species/zombie/infectious/spec_death(gibbed, mob/living/carbon/C)
	. = ..()
	var/obj/item/organ/internal/zombie_infection/infection
	infection = C.get_organ_slot(ORGAN_SLOT_ZOMBIE)
	if(infection)
		qdel(infection)

/datum/species/zombie/infectious/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()

	// Deal with the source of this zombie corruption
	// Infection organ needs to be handled separately from mutant_organs
	// because it persists through species transitions
	var/obj/item/organ/internal/zombie_infection/infection
	infection = C.get_organ_slot(ORGAN_SLOT_ZOMBIE)
	if(!infection)
		infection = new()
		infection.Insert(C)

// Your skin falls off
/datum/species/human/krokodil_addict
	name = "\improper Human"
	id = SPECIES_ZOMBIE_KROKODIL
	examine_limb_id = SPECIES_HUMAN
	sexes = 0
	changesource_flags = MIRROR_BADMIN | WABBAJACK | ERT_SPAWN

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/zombie,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/zombie,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/zombie,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/zombie,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/zombie,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/zombie
	)


#undef REGENERATION_DELAY
