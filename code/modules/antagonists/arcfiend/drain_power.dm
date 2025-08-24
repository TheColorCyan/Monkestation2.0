/datum/action/cooldown/arcfiend
	/// Our antagonist datum
	var/datum/antagonist/arcfiend/arcfiend
	/// How much power it takes to cast an ability
	var/power_cost = 0

/datum/action/cooldown/arcfiend/targeted
	///If set, how far the target has to be for the power to work.
	var/target_range
	///Is this power LOCKED due to being used?
	var/power_in_use = FALSE

/// Modify description to add notice that this is aimed.
/datum/action/cooldown/arcfiend/targeted/New(Target)
	desc += "<br>\[<i>Targeted Power</i>\]"
	return ..()

/datum/action/cooldown/arcfiend/targeted/Trigger(trigger_flags, atom/target)
	if(!QDELETED(target))
		return InterceptClickOn(owner, null, target)

	return set_click_ability(owner)

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
	// CANCEL RANGED TARGET check
	if(!CheckValidTarget(target_atom))
		return FALSE
	// Valid? (return true means DON'T cancel power!)
	if(!CheckCanTarget(target_atom))
		return TRUE
	FireTargetedPower(target_atom) // We use this instead of ActivatePower(trigger_flags), which has no input
	// Skip this part so we can return TRUE right away.
	return TRUE

/// Like ActivatePower, but specific to Targeted (and takes an atom input). We don't use ActivatePower for targeted.
/datum/action/cooldown/arcfiend/targeted/proc/FireTargetedPower(atom/target_atom)
	log_combat(owner, target_atom, "used [name] on")

/// The power went off! We now pay the cost of the power.
/datum/action/cooldown/arcfiend/targeted/proc/power_activated_sucessfully()
	StartCooldown()

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

	/// How much power we drain
	var/drain = 50
	// How much power we drain from a living being
	var/living_drain = 100


/datum/action/cooldown/arcfiend/targeted/drain_power/FireTargetedPower(atom/target)
	. = ..()
	// Sparks!
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, FALSE, get_turf(target))
	if (istype(target, /obj/machinery))
		if (istype(target, /obj/machinery/power/apc))
			// Special interactions with apcs
			var/obj/machinery/power/apc/apc = target
			if(apc.cell?.charge)
				while(apc.cell.charge > 0)
					// When APC reaches 0 charge, destroy it and stop the drain
					if(apc.cell.charge < drain)
						arcfiend.gain_power(apc.cell.charge)
						apc.Destroy()
						break
					if (do_after(owner, 1 SECONDS, target))
						spark_system.start()
						playsound(apc.loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
						apc.cell.use(drain)
						arcfiend.gain_power(drain)
					// Same thing here
					else
						apc.Destroy()
						break

