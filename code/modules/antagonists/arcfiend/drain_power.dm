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
	if(!QDELETED(target))
		return InterceptClickOn(owner, null, target)
	return set_click_ability(owner)

/datum/action/cooldown/arcfiend/targeted/DeactivatePower()
	STOP_PROCESSING(SSprocessing, src)
	active = FALSE
	build_all_button_icons()
	unset_click_ability(owner)

/datum/action/cooldown/arcfiend/targeted/proc/is_valid_target(atom/target_atom)
	if(target_atom == owner)
		return FALSE
	return TRUE

/datum/action/cooldown/arcfiend/targeted/proc/can_use_targeted(atom/target)
	if(target_range)
		// Out of Range
		if(!(target in view(target_range, owner)))
			owner.balloon_alert(owner, "out of range.")
			return FALSE
	return TRUE

/// Click Target
/datum/action/cooldown/arcfiend/targeted/proc/click_with_power(atom/target_atom)
	if (!is_valid_target(target_atom))
		return FALSE
	if(!can_use_targeted(target_atom))
		return FALSE
	power_activated_sucessfully()
	use_targeted_power(target_atom)
	return TRUE

/datum/action/cooldown/arcfiend/targeted/proc/use_targeted_power(atom/target_atom)
	log_combat(owner, target_atom, "used [name] on")

/// The power went off! We now pay the cost of the power.
/datum/action/cooldown/arcfiend/targeted/proc/power_activated_sucessfully()
	unset_click_ability(owner)
	StartCooldown()

/datum/action/cooldown/arcfiend/targeted/InterceptClickOn(mob/living/user, params, atom/target)
	click_with_power(target)
	/// No afterattack to stop pulling cells out of APCs
	return COMPONENT_NO_AFTERATTACK

/datum/action/cooldown/arcfiend/targeted/drain_power
	name = "Drain power"
	desc = "Allows you to drain power out of machinery or people"
	button_icon = 'icons/mob/actions/arcfiend_actions.dmi'
	button_icon_state = "drain_power"
	ranged_mousepointer = 'icons/effects/mouse_pointers/moon_target.dmi'

	cooldown_time = 0 SECONDS
	target_range = 1

	/// How much power we drain
	var/drain = 300
	// How much power we drain from a living being
	var/living_drain = 500
	/// Are we draining something?
	var/currently_draining = FALSE


/datum/action/cooldown/arcfiend/targeted/drain_power/is_valid_target(atom/target_atom)
	. = ..()
	if (ismachinery(target_atom))
		return TRUE
	else if (isliving(target_atom))
		return TRUE
	else
		return FALSE

/**
 * Proc to take power from the target and transfer it to our arcfiend
 * Checks to actually see if we can drain are done in use_targeted_power()
 * amount - amount of power we are draining and transfering
 * target - what are we draining
 */
/datum/action/cooldown/arcfiend/targeted/drain_power/proc/drain(amount, atom/target)
	// Sparks
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, FALSE, get_turf(target))

	// Powercells
	if (istype(target, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/cell = target
		cell.use(amount)
		arcfiend.gain_power(amount)

	// Machinery
	if (ismachinery(target))
		var/obj/machinery/machinery = target
		machinery.directly_use_power(amount)
		arcfiend.gain_power(amount)

	// Living
	if (isliving(target))
		var/mob/living/living_thing = target
		living_thing.apply_damage(25, BURN, spread_damage = TRUE)
		living_thing.Disorient(5 SECONDS, 70)
		living_thing.Knockdown(0.5)
		arcfiend.gain_power(amount)

	spark_system.start()
	playsound(owner.loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/datum/action/cooldown/arcfiend/targeted/drain_power/use_targeted_power(atom/target)
	. = ..()
	if (active)
		return
	if (!owner.Adjacent(target))
		return
	active = TRUE
	build_all_button_icons()
	// Check if our target is a machine
	if (ismachinery(target))
		if (istype(target, /obj/machinery/power/apc))
			// Special interactions with apcs
			var/obj/machinery/power/apc/apc = target
			if(apc.cell?.charge)
				while((apc.cell.charge > 0) && active)
					// When APC reaches 0 charge, destroy it and stop the drain
					if(apc.cell.charge < drain)
						arcfiend.gain_power(apc.cell.charge)
						apc.take_damage(300)
						break
					if (do_after(owner, 1 SECONDS, target))
						drain(drain, apc.cell)
					else
						break
			DeactivatePower()

		// Interaction with machinery
		// We drain directly from the APC machine is connected to
		// As a downside, it only drains it's idle power usage
		var/obj/machinery/machinery = target
		var/area/machine_area = get_area(machinery)
		var/obj/machinery/power/apc/local_apc
		if(!machine_area)
			DeactivatePower()
			return
		local_apc = machine_area.apc
		if(local_apc?.cell?.charge)
			while((local_apc.cell.charge > drain) && active)
				if (do_after(owner, 1 SECONDS, target))
					// We drain the amount the machine uses when idle
					// If the machine doesn't use any power when idle, we don't get power either
					drain(machinery.idle_power_usage, machinery)
				else
					break

	// Check if our target is a living being
	// Ethereals get their blood drained as well
	// Ipcs and sillicons - their charge
	else if (isliving(target))
		var/mob/living/living_target = target
		while ((living_target.stat != DEAD) && active)
			if (do_after(owner, 1 SECONDS, living_target))
				if(isethereal(living_target))
					living_target.blood_volume -= 40
				drain(living_drain, living_target)
			else
				break

	DeactivatePower()
