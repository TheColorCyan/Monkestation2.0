/datum/action/cooldown/arcfiend
	/// Our antagonist datum
	var/datum/antagonist/arcfiend/arcfiend
	/// How much power it takes to cast an ability
	var/power_cost = 0
	/// Is the ability active
	var/active = FALSE

// Find arcfiend datum
/datum/action/cooldown/arcfiend/proc/find_arcfiend_datum()
	arcfiend ||= IS_ARCFIEND(owner)

/datum/action/cooldown/arcfiend/Grant(mob/user)
	. = ..()
	find_arcfiend_datum()

/datum/action/cooldown/arcfiend/proc/ActivatePower(trigger_flags)
	active = TRUE
	START_PROCESSING(SSprocessing, src)
	build_all_button_icons()

/datum/action/cooldown/arcfiend/proc/DeactivatePower()
	if(!active)
		return
	STOP_PROCESSING(SSprocessing, src)
	active = FALSE
	StartCooldown()
	build_all_button_icons()

/datum/action/cooldown/arcfiend/targeted
	///If set, how far the target has to be for the power to work.
	var/target_range

/// Modify description to add notice that this is aimed.
/datum/action/cooldown/arcfiend/targeted/New(Target)
	desc += "<br>\[<i>Targeted Power</i>\]"
	return ..()

/datum/action/cooldown/arcfiend/targeted/Remove(mob/living/remove_from)
	. = ..()
	if(remove_from.click_intercept == src)
		unset_click_ability(remove_from)

/datum/action/cooldown/arcfiend/targeted/Trigger(trigger_flags, atom/target)
	if(active)
		DeactivatePower()
		return FALSE
	ActivatePower(trigger_flags)
	if(!QDELETED(target))
		return InterceptClickOn(owner, null, target)
	return set_click_ability(owner)

/datum/action/cooldown/arcfiend/targeted/DeactivatePower()
	STOP_PROCESSING(SSprocessing, src)
	active = FALSE
	build_all_button_icons()
	unset_click_ability(owner)

/// Check if target is VALID (wall, turf, or character?)
/datum/action/cooldown/arcfiend/targeted/proc/CheckValidTarget(atom/target_atom)
	if(target_atom == owner)
		return FALSE
	return TRUE

/// Check if valid target meets conditions
/datum/action/cooldown/arcfiend/targeted/proc/CheckCanTarget(atom/target_atom)
	if(target_range)
		// Out of Range
		if(!(target_atom in view(target_range, owner)))
			if(target_range > 1) // Only warn for range if it's greater than 1. Brawn doesn't need to announce itself.
				owner.balloon_alert(owner, "out of range.")
			return FALSE
	return istype(target_atom)

/// Click Target
/datum/action/cooldown/arcfiend/targeted/proc/click_with_power(atom/target_atom)
	if(!CheckValidTarget(target_atom))
		return FALSE
	if(!CheckCanTarget(target_atom))
		return TRUE
	power_activated_sucessfully()
	FireTargetedPower(target_atom) // We use this instead of ActivatePower(trigger_flags), which has no input
	return TRUE

/// Like ActivatePower, but specific to Targeted (and takes an atom input). We don't use ActivatePower for targeted.
/datum/action/cooldown/arcfiend/targeted/proc/FireTargetedPower(atom/target_atom)
	log_combat(owner, target_atom, "used [name] on")

/// The power went off! We now pay the cost of the power.
/datum/action/cooldown/arcfiend/targeted/proc/power_activated_sucessfully()
	unset_click_ability(owner)
	StartCooldown()
	DeactivatePower()

/datum/action/cooldown/arcfiend/targeted/InterceptClickOn(mob/living/user, params, atom/target)
	click_with_power(target)

/datum/action/cooldown/arcfiend/targeted/drain_power
	name = "Drain power"
	desc = "Allows you to drain power out of machinery or people"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "moon_smile"
	ranged_mousepointer = 'icons/effects/mouse_pointers/moon_target.dmi'

	cooldown_time = 1 SECOND
	target_range = 1

	/// How much power we drain
	var/drain = 300
	// How much power we drain from a living being
	var/living_drain = 500
	/// Are we draining something?
	var/currently_draining = FALSE

/// Proc used to drain power and transfer it to the arcfiend
/datum/action/cooldown/arcfiend/targeted/drain_power/proc/drain(var/amount, atom/target)
	// Sparks
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, FALSE, get_turf(target))

	// Powercells
	if (istype(target, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/cell = target
		cell.use(amount)
		arcfiend.gain_power(amount)

	// Machinery
	if (istype(target, /obj/machinery))
		var/obj/machinery/machinery = target
		machinery.directly_use_power(amount)
		arcfiend.gain_power(amount)

	// Living
	if (istype(target, /mob/living))
		var/mob/living/living_thing = target
		living_thing.apply_damage(25, BURN, spread_damage = TRUE)
		living_thing.Disorient(5 SECONDS, 70, knockdown = 0.5 SECONDS)
		arcfiend.gain_power(amount)

	spark_system.start()
	playsound(owner.loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/datum/action/cooldown/arcfiend/targeted/drain_power/FireTargetedPower(atom/target)
	. = ..()
	if (currently_draining)
		return
	if (!owner.Adjacent(target))
		return
	currently_draining = TRUE
	// Check if our target is a machine
	if (istype(target, /obj/machinery))
		if (istype(target, /obj/machinery/power/apc))
			// Special interactions with apcs
			var/obj/machinery/power/apc/apc = target
			if(apc.cell?.charge)
				while(apc.cell.charge > 0)
					// When APC reaches 0 charge, destroy it and stop the drain
					if(apc.cell.charge < drain)
						arcfiend.gain_power(apc.cell.charge)
						apc.take_damage(300)
						break
					if (do_after(owner, 1 SECONDS, target))
						drain(drain, apc.cell)
					else
						currently_draining = FALSE
						break
			currently_draining = FALSE
			return

		// Interaction with machinery
		// We drain directly from the APC machine is connected to, but slower
		var/obj/machinery/machinery = target
		var/area/machine_area = get_area(machinery)
		var/obj/machinery/power/apc/local_apc
		if(!machine_area)
			return FALSE
		local_apc = machine_area.apc
		if(local_apc?.cell?.charge)
			while(local_apc.cell.charge > drain)
				if (do_after(owner, 1 SECONDS, target))
					// Less power
					drain(drain - 200, machinery)
				else
					currently_draining = FALSE
					break

	// Check if our target is a living being
	else if (isliving(target))
		var/mob/living/living_target = target
		while (living_target.stat != DEAD)
			if (do_after(owner, 1 SECONDS, living_target))
				drain(living_drain, living_target)
			else
				currently_draining = FALSE
				break

	currently_draining = FALSE
