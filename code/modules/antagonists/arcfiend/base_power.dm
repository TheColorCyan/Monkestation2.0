/datum/action/cooldown/arcfiend
	/// Our antagonist datum
	var/datum/antagonist/arcfiend/arcfiend

	///Background icon when the Power is active.
	active_background_icon_state = "vamp_power_on"
	///Background icon when the Power is NOT active.
	base_background_icon_state = "vamp_power_off"

	/// How much power it takes to cast an ability
	var/power_cost = 0
	/// How much power it takes to keep the ability active
	var/active_power_cost = 0
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

/datum/action/cooldown/arcfiend/Trigger(trigger_flags, atom/target)
	find_arcfiend_datum()
	if(active)
		DeactivatePower()
		return FALSE
	if(!can_pay_power_cost() || !can_use(owner, trigger_flags))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	pay_power_cost()
	ActivatePower(trigger_flags)
	if(!active)
		StartCooldown()
	return TRUE

// When power is processing we check if we can actually still use it
// If not, we deactivate it
/datum/action/cooldown/arcfiend/process()
	SHOULD_CALL_PARENT(TRUE)
	. = ..()
	if (!active)
		return
	if (!can_use(owner))
		DeactivatePower()
		return
	/// Use up power when it's active
	if(arcfiend)
		arcfiend.gain_power(-active_power_cost)
	return TRUE

/datum/action/cooldown/arcfiend/IsAvailable(feedback = FALSE)
	return COOLDOWN_FINISHED(src, next_use_time)

/datum/action/cooldown/arcfiend/proc/can_pay_power_cost()
	if(QDELETED(owner) || QDELETED(owner.mind))
		return FALSE
	if(!COOLDOWN_FINISHED(src, next_use_time))
		owner.balloon_alert(owner, "power unavailable!")
		return FALSE
	if(!arcfiend)
		return FALSE
	if(arcfiend.stored_power < power_cost)
		to_chat(owner, span_warning("You need at least [power_cost] stored energy to activate [name]"))
		return FALSE
	return TRUE

/datum/action/cooldown/arcfiend/proc/can_use(mob/living/carbon/user, trigger_flags)
	if(QDELETED(owner))
		return FALSE
	if(!isliving(user))
		return FALSE
	// Conscious
	if((user.stat != CONSCIOUS))
		to_chat(user, span_warning("You can't do this while you are unconcious!"))
		return FALSE
	// Incapacitated
	if(user.incapacitated())
		to_chat(user, span_warning("Not while you're incapacitated!"))
		return FALSE
	// Constant Cost
	if(active_power_cost > 0)
		var/can_upkeep = arcfiend.stored_power > 0
		if(!can_upkeep)
			to_chat(user, span_warning("You don't have the energy to upkeep [src]!"))
			return FALSE
	return TRUE

/datum/action/cooldown/arcfiend/proc/pay_power_cost()
	if(!arcfiend)
		return
	arcfiend.stored_power -= power_cost
	//arcfiend.update_hud()
