/mob/living/carbon/human/Initialize(mapload)
	add_verb(src, /mob/living/proc/mob_sleep)
	add_verb(src, /mob/living/proc/toggle_resting)

	icon_state = "" //Remove the inherent human icon that is visible on the map editor. We're rendering ourselves limb by limb, having it still be there results in a bug where the basic human icon appears below as south in all directions and generally looks nasty.

	setup_mood()
	// This needs to be called very very early in human init (before organs / species are created at the minimum)
	setup_organless_effects()

	create_dna()
	dna.species.create_fresh_body(src)
	setup_human_dna()

	create_carbon_reagents()
	set_species(dna.species.type)

	prepare_huds() //Prevents a nasty runtime on human init

	physiology = new()

	. = ..()

	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_FACE_ACT, PROC_REF(clean_face))
	AddComponent(/datum/component/personal_crafting)
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_HUMAN, 1, -6)
	AddComponent(/datum/component/bloodysoles/feet, FOOTPRINT_SPRITE_SHOES)
	AddElement(/datum/element/ridable, /datum/component/riding/creature/human)
	AddElement(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human/, should_strip))
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	GLOB.human_list += src

/mob/living/carbon/human/proc/setup_mood()
	if (CONFIG_GET(flag/disable_human_mood))
		return
	mob_mood = new /datum/mood(src)

/mob/living/carbon/human/dummy/setup_mood()
	return

/// This proc is for holding effects applied when a mob is missing certain organs
/// It is called very, very early in human init because all humans innately spawn with no organs and gain them during init
/// Gaining said organs removes these effects
/mob/living/carbon/human/proc/setup_organless_effects()
	// All start without eyes, and get them via set species
	become_blind(NO_EYES)
	// Mobs cannot taste anything without a tongue; the tongue organ removes this on Insert
	ADD_TRAIT(src, TRAIT_AGEUSIA, NO_TONGUE_TRAIT)
	// No lungs until you get lungs
	apply_status_effect(/datum/status_effect/lungless)

/mob/living/carbon/human/proc/setup_human_dna()
	//initialize dna. for spawned humans; overwritten by other code
	randomize_human(src)
	dna.initialize_dna()

/mob/living/carbon/human/Destroy()
	QDEL_NULL(physiology)
	GLOB.human_list -= src

	if (mob_mood)
		QDEL_NULL(mob_mood)

	return ..()

/mob/living/carbon/human/ZImpactDamage(turf/T, levels)
	if(stat != CONSCIOUS || levels > 1) // you're not The One
		return ..()
	var/obj/item/organ/external/wings/gliders = get_organ_by_type(/obj/item/organ/external/wings)
	if(HAS_TRAIT(src, TRAIT_FREERUNNING) || gliders?.can_soften_fall()) // the power of parkour or wings allows falling short distances unscathed
		visible_message(span_danger("[src] makes a hard landing on [T] but remains unharmed from the fall."), \
						span_userdanger("You brace for the fall. You make a hard landing on [T] but remain unharmed."))
		Knockdown(levels * 40)
		return
	return ..()

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...sec hud images...
	sec_hud_set_ID()
	sec_hud_set_implants()
	sec_hud_set_security_status()
	//...fan gear
	fan_hud_set_fandom()
	//...and display them.
	add_to_all_human_data_huds()

/mob/living/carbon/human/reset_perspective(atom/new_eye, force_reset = FALSE)
	if(dna?.species?.prevent_perspective_change && !force_reset) // This is in case a species needs to prevent perspective changes in certain cases, like Dullahans preventing perspective changes when they're looking through their head.
		update_fullscreen()
		return
	return ..()


/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["item"]) //canUseTopic check for this is handled by mob/Topic()
		var/slot = text2num(href_list["item"])
		if(check_obscured_slots(TRUE) & slot)
			to_chat(usr, span_warning("You can't reach that! Something is covering it."))
			return

///////HUDs///////
	if(href_list["hud"])
		if(!ishuman(usr))
			return
		var/mob/living/carbon/human/human_user = usr
		var/perpname = get_face_name(get_id_name(""))
		if(!HAS_TRAIT(human_user, TRAIT_SECURITY_HUD) && !HAS_TRAIT(human_user, TRAIT_MEDICAL_HUD))
			return
		if((text2num(href_list["examine_time"]) + 1 MINUTES) < world.time)
			to_chat(human_user, "[span_notice("It's too late to use this now!")]")
			return
		var/datum/record/crew/target_record = find_record(perpname)
		if(href_list["photo_front"] || href_list["photo_side"])
			if(!target_record)
				return
			if(!human_user.canUseHUD())
				return
			if(!HAS_TRAIT(human_user, TRAIT_SECURITY_HUD) && !HAS_TRAIT(human_user, TRAIT_MEDICAL_HUD))
				return
			var/obj/item/photo/photo_from_record = null
			if(href_list["photo_front"])
				photo_from_record = target_record.get_front_photo()
			else if(href_list["photo_side"])
				photo_from_record = target_record.get_side_photo()
			if(photo_from_record)
				photo_from_record.show(human_user)
			return

		if(href_list["hud"] == "m")
			if(!HAS_TRAIT(human_user, TRAIT_MEDICAL_HUD))
				return
			if(href_list["evaluation"])
				if(!getBruteLoss() && !getFireLoss() && !getOxyLoss() && getToxLoss() < 20)
					to_chat(human_user, "[span_notice("No external injuries detected.")]<br>")
					return
				var/span = "notice"
				var/status = ""
				if(getBruteLoss())
					to_chat(human_user, "<b>Physical trauma analysis:</b>")
					for(var/X in bodyparts)
						var/obj/item/bodypart/BP = X
						var/brutedamage = BP.brute_dam
						if(brutedamage > 0)
							status = "received minor physical injuries."
							span = "notice"
						if(brutedamage > 20)
							status = "been seriously damaged."
							span = "danger"
						if(brutedamage > 40)
							status = "sustained major trauma!"
							span = "userdanger"
						if(brutedamage)
							to_chat(human_user, "<span class='[span]'>[BP] appears to have [status]</span>")
				if(getFireLoss())
					to_chat(human_user, "<b>Analysis of skin burns:</b>")
					for(var/X in bodyparts)
						var/obj/item/bodypart/BP = X
						var/burndamage = BP.burn_dam
						if(burndamage > 0)
							status = "signs of minor burns."
							span = "notice"
						if(burndamage > 20)
							status = "serious burns."
							span = "danger"
						if(burndamage > 40)
							status = "major burns!"
							span = "userdanger"
						if(burndamage)
							to_chat(human_user, "<span class='[span]'>[BP] appears to have [status]</span>")
				if(getOxyLoss())
					to_chat(human_user, span_danger("Patient has signs of suffocation, emergency treatment may be required!"))
				if(getToxLoss() > 20)
					to_chat(human_user, span_danger("Gathered data is inconsistent with the analysis, possible cause: poisoning."))
			if(!human_user.wear_id) //You require access from here on out.
				to_chat(human_user, span_warning("ERROR: Invalid access"))
				return
			var/list/access = human_user.wear_id.GetAccess()
			if(!(ACCESS_MEDICAL in access))
				to_chat(human_user, span_warning("ERROR: Invalid access"))
				return

			if(href_list["physical_status"])
				var/health_status = tgui_input_list(human_user, "Specify a new physical status for this person.", "Medical HUD", PHYSICAL_STATUSES, target_record.physical_status)
				if(!health_status || !target_record || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_MEDICAL_HUD))
					return

				target_record.physical_status = health_status
				return

			if(href_list["mental_status"])
				var/health_status = tgui_input_list(human_user, "Specify a new mental status for this person.", "Medical HUD", MENTAL_STATUSES, target_record.mental_status)
				if(!health_status || !target_record || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_MEDICAL_HUD))
					return

				target_record.mental_status = health_status
				return

			if(href_list["quirk"])
				var/quirkstring = get_quirk_string(TRUE, CAT_QUIRK_ALL, from_scan = TRUE)
				if(quirkstring)
					to_chat(human_user,  "<span class='notice ml-1'>Detected physiological traits:</span>\n<span class='notice ml-2'>[quirkstring]</span>")
				else
					to_chat(human_user,  "<span class='notice ml-1'>No physiological traits found.</span>")
			return //Medical HUD ends here.

		if(href_list["hud"] == "s")
			if(!HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
				return
			if(human_user.stat || human_user == src) //|| !human_user.canmove || human_user.restrained()) Fluff: Sechuds have eye-tracking technology and sets 'arrest' to people that the wearer looks and blinks at.
				return   //Non-fluff: This allows sec to set people to arrest as they get disarmed or beaten
			// Checks the user has security clearence before allowing them to change arrest status via hud, comment out to enable all access
			var/allowed_access = null
			var/obj/item/clothing/glasses/hud/security/user_glasses = human_user.glasses
			if(istype(user_glasses) && (user_glasses.obj_flags & EMAGGED))
				allowed_access = "@%&ERROR_%$*"
			else //Implant and standard glasses check access
				if(human_user.wear_id)
					var/list/access = human_user.wear_id.GetAccess()
					if(ACCESS_SECURITY in access)
						allowed_access = human_user.get_authentification_name()

			if(!allowed_access)
				to_chat(human_user, span_warning("ERROR: Invalid access."))
				return

			if(!perpname)
				to_chat(human_user, span_warning("ERROR: Can not identify target."))
				return
			target_record = find_record(perpname)
			if(!target_record)
				to_chat(human_user, span_warning("ERROR: Unable to locate data core entry for target."))
				return
			if(href_list["status"])
				var/new_status = tgui_input_list(human_user, "Specify a new criminal status for this person.", "Security HUD", WANTED_STATUSES(), target_record.wanted_status)
				if(!new_status || !target_record || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
					return

				if(new_status == WANTED_ARREST)
					var/datum/crime/new_crime = new(author = human_user, details = "Set by SecHUD.")
					target_record.crimes += new_crime
					investigate_log("SecHUD auto-crime | Added to [target_record.name] by [key_name(human_user)]", INVESTIGATE_RECORDS)

				investigate_log("has been set from [target_record.wanted_status] to [new_status] via HUD by [key_name(human_user)].", INVESTIGATE_RECORDS)
				target_record.wanted_status = new_status
				update_matching_security_huds(target_record.name)
				return

			if(href_list["view"])
				if(!human_user.canUseHUD())
					return
				if(!HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
					return
				to_chat(human_user, "<b>Name:</b> [target_record.name]")
				to_chat(human_user, "<b>Criminal Status:</b> [target_record.wanted_status]")
				to_chat(human_user, "<b>Citations:</b> [length(target_record.citations)]")
				to_chat(human_user, "<b>Note:</b> [target_record.security_note || "None"]")
				to_chat(human_user, "<b>Rapsheet:</b> [length(target_record.crimes)] incidents")
				if(length(target_record.crimes))
					for(var/datum/crime/crime in target_record.crimes)
						if(!crime.valid)
							to_chat(human_user, span_notice("-- REDACTED --"))
							continue

						to_chat(human_user, "<b>Crime:</b> [crime.name]")
						to_chat(human_user, "<b>Details:</b> [crime.details]")
						to_chat(human_user, "Added by [crime.author] at [crime.time]")
				to_chat(human_user, "----------")

				return

			if(href_list["add_citation"])
				var/max_fine = CONFIG_GET(number/maxfine)
				var/citation_name = tgui_input_text(human_user, "Citation crime", "Security HUD")
				var/fine = tgui_input_number(human_user, "Citation fine", "Security HUD", 50, max_fine, 5)
				if(!fine || !target_record || !citation_name || !allowed_access || !isnum(fine) || fine > max_fine || fine <= 0 || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
					return

				var/datum/crime/citation/new_citation = new(name = citation_name, author = allowed_access, fine = fine)

				target_record.citations += new_citation
				new_citation.alert_owner(usr, src, target_record.name, "You have been fined [fine] credits for '[citation_name]'. Fines may be paid at security.")
				investigate_log("New Citation: <strong>[citation_name]</strong> Fine: [fine] | Added to [target_record.name] by [key_name(human_user)]", INVESTIGATE_RECORDS)
				SSblackbox.ReportCitation(REF(new_citation), human_user.ckey, human_user.real_name, target_record.name, citation_name, fine)

				return

			if(href_list["add_crime"])
				var/crime_name = tgui_input_text(human_user, "Crime name", "Security HUD")
				if(!target_record || !crime_name || !allowed_access || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
					return

				var/datum/crime/new_crime = new(name = crime_name, author = allowed_access)

				target_record.crimes += new_crime
				investigate_log("New Crime: <strong>[crime_name]</strong> | Added to [target_record.name] by [key_name(human_user)]", INVESTIGATE_RECORDS)
				to_chat(human_user, span_notice("Successfully added a crime."))

				return

			if(href_list["add_note"])
				var/new_note = tgui_input_text(human_user, "Security note", "Security Records", multiline = TRUE)
				if(!target_record || !new_note || !allowed_access || !human_user.canUseHUD() || !HAS_TRAIT(human_user, TRAIT_SECURITY_HUD))
					return

				target_record.security_note = new_note

				return

	..() //end of this massive fucking chain. TODO: make the hud chain not spooky. - Yeah, great job doing that.

//called when something steps onto a human
/mob/living/carbon/human/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	spreadFire(AM)

/mob/living/carbon/human/proc/canUseHUD()
	return (mobility_flags & MOBILITY_USE)

/mob/living/carbon/human/can_inject(mob/user, target_zone, injection_flags)
	. = TRUE // Default to returning true.
	// we may choose to ignore species trait pierce immunity in case we still want to check skellies for thick clothing without insta failing them (wounds)
	if(injection_flags & INJECT_CHECK_IGNORE_SPECIES)
		if(HAS_TRAIT_NOT_FROM(src, TRAIT_PIERCEIMMUNE, SPECIES_TRAIT))
			. = FALSE
	else if(HAS_TRAIT(src, TRAIT_PIERCEIMMUNE))
		. = FALSE
	if(user && !target_zone)
		target_zone = get_bodypart(check_zone(user.zone_selected)) //try to find a bodypart. if there isn't one, target_zone will be null, and check_zone in the next line will default to the chest.
	var/obj/item/bodypart/the_part = isbodypart(target_zone) ? target_zone : get_bodypart(check_zone(target_zone)) //keep these synced
	// Loop through the clothing covering this bodypart and see if there's any thiccmaterials
	if(!(injection_flags & INJECT_CHECK_PENETRATE_THICK))
		for(var/obj/item/clothing/iter_clothing in get_clothing_on_part(the_part))
			if(iter_clothing.clothing_flags & THICKMATERIAL)
				. = FALSE
				break

/mob/living/carbon/human/try_inject(mob/user, target_zone, injection_flags)
	. = ..()
	if(!. && (injection_flags & INJECT_TRY_SHOW_ERROR_MESSAGE) && user)
		if(!target_zone)
			target_zone = get_bodypart(check_zone(user.zone_selected))
		var/obj/item/bodypart/the_part = isbodypart(target_zone) ? target_zone : get_bodypart(check_zone(target_zone)) //keep these synced
		to_chat(user, span_alert("There is no exposed flesh or thin material on [p_their()] [the_part.name]."))

/mob/living/carbon/human/get_footprint_sprite()
	var/obj/item/bodypart/leg/L = get_bodypart(BODY_ZONE_R_LEG) || get_bodypart(BODY_ZONE_L_LEG)
	return shoes?.footprint_sprite || L?.footprint_sprite

#define CHECK_PERMIT(item) (item && item.item_flags & NEEDS_PERMIT)

/mob/living/carbon/human/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null)
	if(judgement_criteria & JUDGE_EMAGGED)
		return 10 //Everyone is a criminal!

	var/threatcount = judgement_criteria & JUDGE_CHILLOUT ? -5 : 0

	//Lasertag bullshit
	if(lasercolor)
		if(lasercolor == "b")//Lasertag turrets target the opposing team, how great is that? -Sieve
			if(istype(wear_suit, /obj/item/clothing/suit/redtag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/redtag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/redtag))
				threatcount += 2

		if(lasercolor == "r")
			if(istype(wear_suit, /obj/item/clothing/suit/bluetag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/bluetag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/bluetag))
				threatcount += 2

		return threatcount

	//Check for ID
	var/obj/item/card/id/idcard = get_idcard(FALSE)
	if( (judgement_criteria & JUDGE_IDCHECK) && !idcard && name == "Unknown")
		threatcount += 4

	//Check for weapons
	if( (judgement_criteria & JUDGE_WEAPONCHECK) && weaponcheck)
		if(!idcard || !(ACCESS_WEAPONS in idcard.access))
			for(var/obj/item/I in held_items) //if they're holding a gun
				if(weaponcheck.Invoke(I))
					threatcount += 4
			if(weaponcheck.Invoke(belt) || weaponcheck.Invoke(back)) //if a weapon is present in the belt or back slot
				threatcount += 2 //not enough to trigger look_for_perp() on it's own unless they also have criminal status.

	//Check for arrest warrant
	if(judgement_criteria & JUDGE_RECORDCHECK)
		var/perpname = get_face_name(get_id_name())
		var/datum/record/crew/record = find_record(perpname)
		if(record?.wanted_status)
			switch(record.wanted_status)
				if(WANTED_ARREST)
					threatcount += 5
				if(WANTED_PRISONER)
					threatcount += 2
				if(WANTED_SUSPECT)
					threatcount += 2
				if(WANTED_PAROLE)
					threatcount += 2

	if(istype(head, /obj/item/clothing/head/hats/tophat/syndicate))
		threatcount += 2

	if(istype(wear_neck, /obj/item/clothing/neck/cloak/syndicate))
		threatcount += 2

	//Check for nonhuman scum
	if(dna && dna.species.id && dna.species.id != SPECIES_HUMAN)
		threatcount += 1

	//mindshield implants imply trustworthyness
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		threatcount -= 1

	return threatcount


//Used for new human mobs created by cloning/goleming/podding
/mob/living/carbon/human/proc/set_cloned_appearance()
	if(gender == MALE)
		set_facial_hairstyle("Full Beard", update = FALSE)
	else
		set_facial_hairstyle("Shaved", update = FALSE)
	set_hairstyle(pick("Bedhead", "Bedhead 2", "Bedhead 3"), update = FALSE)
	underwear = "Nude"
	update_body(is_creating = TRUE)

/mob/living/carbon/human/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_THREE)
		for(var/obj/item/hand in held_items)
			if(prob(current_size * 5) && hand.w_class >= ((11-current_size)/2)  && dropItemToGround(hand))
				step_towards(hand, src)
				to_chat(src, span_warning("\The [S] pulls \the [hand] from your grip!"))

#define CPR_PANIC_SPEED (0.8 SECONDS)

/// Performs CPR on the target after a delay.
/mob/living/carbon/human/proc/do_cpr(mob/living/carbon/target)
	if(target == src)
		return

	var/panicking = FALSE

	do
		CHECK_DNA_AND_SPECIES(target)

		if (DOING_INTERACTION_WITH_TARGET(src,target))
			return FALSE

		if (target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH))
			to_chat(src, span_warning("[target.name] is dead!"))
			return FALSE

		if (is_mouth_covered())
			to_chat(src, span_warning("Remove your mask first!"))
			return FALSE

		if (target.is_mouth_covered())
			to_chat(src, span_warning("Remove [p_their()] mask first!"))
			return FALSE

		if (!get_organ_slot(ORGAN_SLOT_LUNGS))
			to_chat(src, span_warning("You have no lungs to breathe with, so you cannot perform CPR!"))
			return FALSE

		if (HAS_TRAIT(src, TRAIT_NOBREATH))
			to_chat(src, span_warning("You do not breathe, so you cannot perform CPR!"))
			return FALSE

		visible_message(span_notice("[src] is trying to perform CPR on [target.name]!"), \
						span_notice("You try to perform CPR on [target.name]... Hold still!"))

		if (!do_after(src, delay = panicking ? CPR_PANIC_SPEED : (3 SECONDS), target = target))
			to_chat(src, span_warning("You fail to perform CPR on [target]!"))
			return FALSE

		if (target.health > target.crit_threshold)
			return FALSE

		visible_message(span_notice("[src] performs CPR on [target.name]!"), span_notice("You perform CPR on [target.name]."))
		add_mood_event("saved_life", /datum/mood_event/saved_life)
		log_combat(src, target, "CPRed")

		if (HAS_TRAIT(target, TRAIT_NOBREATH))
			to_chat(target, span_unconscious("You feel a breath of fresh air... which is a sensation you don't recognise..."))
		else if (!target.get_organ_slot(ORGAN_SLOT_LUNGS))
			to_chat(target, span_unconscious("You feel a breath of fresh air... but you don't feel any better..."))
		else
			target.adjustOxyLoss(-min(target.getOxyLoss(), 7))
			to_chat(target, span_unconscious("You feel a breath of fresh air enter your lungs... It feels good..."))

		if (target.health <= target.crit_threshold)
			if (!panicking)
				to_chat(src, span_warning("[target] still isn't up! You try harder!"))
			panicking = TRUE
		else
			panicking = FALSE
	while (panicking)

#undef CPR_PANIC_SPEED

/mob/living/carbon/human/cuff_resist(obj/item/I)
	if(dna?.check_mutation(/datum/mutation/hulk))
		say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ), forced = "hulk")
		if(..(I, cuff_break = FAST_CUFFBREAK))
			dropItemToGround(I)
	else
		if(..())
			dropItemToGround(I)

/**
 * Wash the hands, cleaning either the gloves if equipped and not obscured, otherwise the hands themselves if they're not obscured.
 *
 * Returns false if we couldn't wash our hands due to them being obscured, otherwise true
 */
/mob/living/carbon/human/proc/wash_hands(clean_types)
	var/obscured = check_obscured_slots()
	if(obscured & ITEM_SLOT_GLOVES)
		return FALSE

	if(gloves)
		if(gloves.wash(clean_types))
			update_worn_gloves()
	else if((clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0)
		blood_in_hands = 0
		update_worn_gloves()

	return TRUE

/**
 * Called on the COMSIG_COMPONENT_CLEAN_FACE_ACT signal
 */
/mob/living/carbon/human/proc/clean_face(datum/source, clean_types)
	SIGNAL_HANDLER
	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	if(glasses && is_eyes_covered(ITEM_SLOT_MASK|ITEM_SLOT_HEAD) && glasses.wash(clean_types))
		update_worn_glasses()
		. = TRUE

	var/obscured = check_obscured_slots()
	if(wear_mask && !(obscured & ITEM_SLOT_MASK) && wear_mask.wash(clean_types))
		update_worn_mask()
		. = TRUE

/**
 * Called when this human should be washed
 */
/mob/living/carbon/human/wash(clean_types)
	. = ..()

	// Wash equipped stuff that cannot be covered
	if(wear_suit?.wash(clean_types))
		update_worn_oversuit()
		. = TRUE

	if(belt?.wash(clean_types))
		update_worn_belt()
		. = TRUE

	// Check and wash stuff that can be covered
	var/obscured = check_obscured_slots()

	if(w_uniform && !(obscured & ITEM_SLOT_ICLOTHING) && w_uniform.wash(clean_types))
		update_worn_undersuit()
		. = TRUE

	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	// Wash hands if exposed
	if(!gloves && (clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0 && !(obscured & ITEM_SLOT_GLOVES))
		blood_in_hands = 0
		update_worn_gloves()
		. = TRUE

//Turns a mob black, flashes a skeleton overlay
//Just like a cartoon!
/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	var/mutable_appearance/zap_appearance

	// If we have a species, we need to handle mutant parts and stuff
	if(dna?.species)
		add_atom_colour("#000000", TEMPORARY_COLOUR_PRIORITY)
		var/static/mutable_appearance/shock_animation_dna
		if(!shock_animation_dna)
			shock_animation_dna = mutable_appearance(icon, "electrocuted_base")
			shock_animation_dna.appearance_flags |= RESET_COLOR|KEEP_APART
		zap_appearance = shock_animation_dna

	// Otherwise do a generic animation
	else
		var/static/mutable_appearance/shock_animation_generic
		if(!shock_animation_generic)
			shock_animation_generic = mutable_appearance(icon, "electrocuted_generic")
			shock_animation_generic.appearance_flags |= RESET_COLOR|KEEP_APART
		zap_appearance = shock_animation_generic

	add_overlay(zap_appearance)
	addtimer(CALLBACK(src, PROC_REF(end_electrocution_animation), zap_appearance), anim_duration)

/mob/living/carbon/human/proc/end_electrocution_animation(mutable_appearance/MA)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#000000")
	cut_overlay(MA)

/mob/living/carbon/human/resist_restraints()
	if(wear_suit?.breakouttime)
		changeNext_move(CLICK_CD_BREAKOUT)
		last_special = world.time + CLICK_CD_BREAKOUT
		cuff_resist(wear_suit)
	else
		..()

/mob/living/carbon/human/clear_cuffs(obj/item/I, cuff_break)
	. = ..()
	if(.)
		return
	if(!I.loc || buckled)
		return FALSE
	if(I == wear_suit)
		visible_message(span_danger("[src] manages to [cuff_break ? "break" : "remove"] [I]!"))
		to_chat(src, span_notice("You successfully [cuff_break ? "break" : "remove"] [I]."))
		return TRUE

/mob/living/carbon/human/replace_records_name(oldname, newname) // Only humans have records right now, move this up if changed.
	var/datum/record/crew/crew_record = find_record(oldname)
	var/datum/record/locked/locked_record = find_record(oldname, locked_only = TRUE)

	if(crew_record)
		crew_record.name = newname
	if(locked_record)
		locked_record.name = newname

/mob/living/carbon/human/update_health_hud()
	if(!client || !hud_used)
		return
	// Updates the health bar, also sends signal
	. = ..()
	// Handles changing limb colors and stuff
	hud_used.healthdoll?.update_appearance()

/mob/living/carbon/human/fully_heal(heal_flags = HEAL_ALL)
	if(heal_flags & HEAL_NEGATIVE_MUTATIONS)
		for(var/datum/mutation/existing_mutation in dna.mutations)
			if(existing_mutation.quality != POSITIVE)
				dna.remove_mutation(existing_mutation.name, list(MUTATION_SOURCE_ACTIVATED, MUTATION_SOURCE_MUTATOR, MUTATION_SOURCE_TIMED_INJECTOR))
	return ..()

/mob/living/carbon/human/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if(blood && HAS_TRAIT(src, TRAIT_NOBLOOD) && !HAS_TRAIT(src, TRAIT_TOXINLOVER))
		if(message)
			visible_message(span_warning("[src] dry heaves!"), \
							span_userdanger("You try to throw up, but there's nothing in your stomach!"))
		if(stun)
			Stun(20 SECONDS)
		return 1
	..()

/mob/living/carbon/human/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, mob_height))
		// you wanna edit this one not that one
		var_name = NAMEOF(src, base_mob_height)
	. = ..()
	if(!.)
		return .
	if(var_name == NAMEOF(src, base_mob_height))
		update_mob_height()

/mob/living/carbon/human/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_COPY_OUTFIT, "Copy Outfit")
	VV_DROPDOWN_OPTION(VV_HK_MOD_MUTATIONS, "Add/Remove Mutation")
	VV_DROPDOWN_OPTION(VV_HK_MOD_QUIRKS, "Add/Remove Quirks")
	VV_DROPDOWN_OPTION(VV_HK_SET_SPECIES, "Set Species")

/mob/living/carbon/human/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_COPY_OUTFIT])
		if(!check_rights(R_SPAWN))
			return
		copy_outfit()
	if(href_list[VV_HK_MOD_MUTATIONS])
		if(!check_rights(R_SPAWN))
			return

		var/list/options = list("Clear"="Clear")
		for(var/x in subtypesof(/datum/mutation))
			var/datum/mutation/mut = x
			var/name = initial(mut.name)
			options[dna.check_mutation(mut) ? "[name] (Remove)" : "[name] (Add)"] = mut

		var/result = input(usr, "Choose mutation to add/remove","Mutation Mod") as null|anything in sort_list(options)
		if(result)
			if(result == "Clear")
				for(var/datum/mutation/mutation as anything in dna.mutations)
					dna.remove_mutation(mutation, mutation.sources)
			else
				var/mut = options[result]
				if(dna.check_mutation(mut))
					dna.remove_mutation(mut)
				else
					dna.add_mutation(mut, MUTATION_SOURCE_VV)
	if(href_list[VV_HK_MOD_QUIRKS])
		if(!check_rights(R_SPAWN))
			return

		var/list/options = list("Clear"="Clear")
		for(var/type in subtypesof(/datum/quirk))
			var/datum/quirk/quirk_type = type

			if(initial(quirk_type.abstract_parent_type) == type)
				continue

			var/qname = initial(quirk_type.name)
			options[has_quirk(quirk_type) ? "[qname] (Remove)" : "[qname] (Add)"] = quirk_type

		var/result = input(usr, "Choose quirk to add/remove","Quirk Mod") as null|anything in sort_list(options)
		if(result)
			if(result == "Clear")
				for(var/datum/quirk/q in quirks)
					remove_quirk(q.type)
			else
				var/T = options[result]
				if(has_quirk(T))
					remove_quirk(T)
				else
					add_quirk(T)
	if(href_list[VV_HK_SET_SPECIES])
		if(!check_rights(R_SPAWN))
			return
		var/result = input(usr, "Please choose a new species","Species") as null|anything in GLOB.species_list
		if(result)
			var/newtype = GLOB.species_list[result]
			admin_ticket_log("[key_name(usr)] has modified the bodyparts of [src] to [result]") // MONKESTATION EDIT - tgui tickets
			set_species(newtype)

/mob/living/carbon/human/limb_attack_self()
	var/obj/item/bodypart/arm = hand_bodyparts[active_hand_index]
	if(arm)
		arm.attack_self(src)
	return ..()

/mob/living/carbon/human/mouse_buckle_handling(mob/living/M, mob/living/user)
	if(pulling != M || grab_state != GRAB_AGGRESSIVE || stat != CONSCIOUS)
		return FALSE

	//If they dragged themselves to you and you're currently aggressively grabbing them try to piggyback
	if(user == M && can_piggyback(M))
		piggyback(M)
		return TRUE

	//If you dragged them to you and you're aggressively grabbing try to fireman carry them
	if(can_be_firemanned(M))
		fireman_carry(M)
		return TRUE

//src is the user that will be carrying, target is the mob to be carried
/mob/living/carbon/human/proc/can_piggyback(mob/living/carbon/target)
	return (istype(target) && target.stat == CONSCIOUS)

/mob/living/carbon/human/proc/can_be_firemanned(mob/living/carbon/target)
	return ishuman(target) && target.body_position == LYING_DOWN

/mob/living/carbon/human/proc/fireman_carry(mob/living/carbon/target)
	if(!can_be_firemanned(target) || incapacitated(IGNORE_GRAB))
		to_chat(src, span_warning("You can't fireman carry [target] while [target.p_they()] [target.p_are()] standing!"))
		return

	var/carrydelay = 5 SECONDS //if you have latex you are faster at grabbing
	var/skills_space = "" //cobby told me to do this
	if(HAS_TRAIT(src, TRAIT_QUICKER_CARRY))
		carrydelay = 3 SECONDS
		skills_space = " very quickly"
	else if(HAS_TRAIT(src, TRAIT_QUICK_CARRY))
		carrydelay = 4 SECONDS
		skills_space = " quickly"

	visible_message(span_notice("[src] starts[skills_space] lifting [target] onto [p_their()] back..."),
		span_notice("You[skills_space] start to lift [target] onto your back..."))
	if(!do_after(src, carrydelay, target))
		visible_message(span_warning("[src] fails to fireman carry [target]!"))
		return

	//Second check to make sure they're still valid to be carried
	if(!can_be_firemanned(target) || incapacitated(IGNORE_GRAB) || target.buckled)
		visible_message(span_warning("[src] fails to fireman carry [target]!"))
		return

	return buckle_mob(target, TRUE, TRUE, CARRIER_NEEDS_ARM)

/mob/living/carbon/human/proc/piggyback(mob/living/carbon/target)
	if(!can_piggyback(target))
		to_chat(target, span_warning("You can't piggyback ride [src] right now!"))
		return

	visible_message(span_notice("[target] starts to climb onto [src]..."))
	if(!do_after(target, 1.5 SECONDS, target = src) || !can_piggyback(target))
		visible_message(span_warning("[target] fails to climb onto [src]!"))
		return

	if(target.incapacitated(IGNORE_GRAB) || incapacitated(IGNORE_GRAB))
		target.visible_message(span_warning("[target] can't hang onto [src]!"))
		return

	return buckle_mob(target, TRUE, TRUE, RIDER_NEEDS_ARMS)

/mob/living/carbon/human/buckle_mob(mob/living/target, force = FALSE, check_loc = TRUE, buckle_mob_flags= NONE)
	if(!is_type_in_typecache(target, can_ride_typecache))
		target.visible_message(span_warning("[target] really can't seem to mount [src]..."))
		return

	if(!force)//humans are only meant to be ridden through piggybacking and special cases
		return

	return ..()


/mob/living/carbon/human/reagent_check(datum/reagent/chem, seconds_per_tick, times_fired)
	. = ..()
	if(. & COMSIG_MOB_STOP_REAGENT_CHECK)
		return
	return dna.species.handle_chemical(chem, src, seconds_per_tick, times_fired)

/mob/living/carbon/human/updatehealth()
	. = ..()
	dna?.species.spec_updatehealth(src)
	update_damage_movespeed()

/mob/living/carbon/human/proc/update_damage_movespeed()
	var/health_deficiency = max((maxHealth - health), staminaloss)
	if(health_deficiency >= 40)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, multiplicative_slowdown = health_deficiency / 75)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying, TRUE, multiplicative_slowdown = health_deficiency / 25)
	else if(LAZYACCESS(movespeed_modification, "[/datum/movespeed_modifier/damage_slowdown]"))
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)

/mob/living/carbon/human/pre_stamina_change(diff as num, forced)
	if(diff < 0) //Taking damage, not healing
		return diff * physiology.stamina_mod * physiology.temp_stamina_mod
	return diff

/mob/living/carbon/human/get_exp_list(minutes)
	. = ..()

	if(mind.assigned_role.title in SSjob.name_occupations)
		.[mind.assigned_role.title] = minutes

/mob/living/carbon/human/monkeybrain
	ai_controller = /datum/ai_controller/monkey

/mob/living/carbon/human/species
	var/race = null
	var/use_random_name = TRUE

/mob/living/carbon/human/species/create_dna()
	dna = new /datum/dna(src)
	if (!isnull(race))
		dna.species = new race

/mob/living/carbon/human/species/set_species(datum/species/mrace, icon_update, pref_load)
	. = ..()
	if(use_random_name)
		fully_replace_character_name(real_name, dna.species.random_name())

/mob/living/carbon/human/species/abductor
	race = /datum/species/abductor

/mob/living/carbon/human/species/android
	race = /datum/species/android

/mob/living/carbon/human/species/dullahan
	race = /datum/species/dullahan

/mob/living/carbon/human/species/fly
	race = /datum/species/fly

/mob/living/carbon/human/species/golem
	race = /datum/species/golem

/mob/living/carbon/human/species/golem/adamantine
	race = /datum/species/golem/adamantine

/mob/living/carbon/human/species/golem/plasma
	race = /datum/species/golem/plasma

/mob/living/carbon/human/species/golem/diamond
	race = /datum/species/golem/diamond

/mob/living/carbon/human/species/golem/gold
	race = /datum/species/golem/gold

/mob/living/carbon/human/species/golem/silver
	race = /datum/species/golem/silver

/mob/living/carbon/human/species/golem/plasteel
	race = /datum/species/golem/plasteel

/mob/living/carbon/human/species/golem/titanium
	race = /datum/species/golem/titanium

/mob/living/carbon/human/species/golem/plastitanium
	race = /datum/species/golem/plastitanium

/mob/living/carbon/human/species/golem/alien_alloy
	race = /datum/species/golem/alloy

/mob/living/carbon/human/species/golem/wood
	race = /datum/species/golem/wood

/mob/living/carbon/human/species/golem/uranium
	race = /datum/species/golem/uranium

/mob/living/carbon/human/species/golem/sand
	race = /datum/species/golem/sand

/mob/living/carbon/human/species/golem/glass
	race = /datum/species/golem/glass

/mob/living/carbon/human/species/golem/bluespace
	race = /datum/species/golem/bluespace

/mob/living/carbon/human/species/golem/bananium
	race = /datum/species/golem/bananium

/mob/living/carbon/human/species/golem/blood_cult
	race = /datum/species/golem/runic

/mob/living/carbon/human/species/golem/cloth
	race = /datum/species/golem/cloth

/mob/living/carbon/human/species/golem/plastic
	race = /datum/species/golem/plastic

/mob/living/carbon/human/species/golem/bronze
	race = /datum/species/golem/bronze

/mob/living/carbon/human/species/golem/cardboard
	race = /datum/species/golem/cardboard

/mob/living/carbon/human/species/golem/leather
	race = /datum/species/golem/leather

/mob/living/carbon/human/species/golem/bone
	race = /datum/species/golem/bone

/mob/living/carbon/human/species/golem/durathread
	race = /datum/species/golem/durathread

/mob/living/carbon/human/species/golem/snow
	race = /datum/species/golem/snow

/mob/living/carbon/human/species/oozeling
	race = /datum/species/oozeling

/mob/living/carbon/human/species/oozeling/stargazer
	race = /datum/species/oozeling/stargazer

/mob/living/carbon/human/species/oozeling/slime
	race = /datum/species/oozeling/slime

/mob/living/carbon/human/species/oozeling/luminescent
	race = /datum/species/oozeling/luminescent

/mob/living/carbon/human/species/lizard
	race = /datum/species/lizard

/mob/living/carbon/human/species/lizard/ashwalker
	race = /datum/species/lizard/ashwalker

/mob/living/carbon/human/species/lizard/silverscale
	race = /datum/species/lizard/silverscale

/mob/living/carbon/human/species/ethereal
	race = /datum/species/ethereal

/mob/living/carbon/human/species/moth
	race = /datum/species/moth

/mob/living/carbon/human/species/mush
	race = /datum/species/mush

/mob/living/carbon/human/species/plasma
	race = /datum/species/plasmaman

/mob/living/carbon/human/species/pod
	race = /datum/species/pod

/mob/living/carbon/human/species/shadow
	race = /datum/species/shadow

/mob/living/carbon/human/species/shadow/nightmare
	race = /datum/species/shadow/nightmare

/mob/living/carbon/human/species/skeleton
	race = /datum/species/skeleton

/mob/living/carbon/human/species/snail
	race = /datum/species/snail

/mob/living/carbon/human/species/vampire
	race = /datum/species/vampire

/mob/living/carbon/human/species/zombie
	race = /datum/species/zombie

/mob/living/carbon/human/species/zombie/infectious
	race = /datum/species/zombie/infectious
