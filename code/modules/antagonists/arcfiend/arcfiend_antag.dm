/// The arcfiend antagonist
/datum/antagonist/arcfiend
	name = "\improper Arcfiend"
	roundend_category = "Arcfiends"
	antagpanel_category = "Arcfiend"
	//ui_name = "AntagInfoArcfiend"
	antag_moodlet = /datum/mood_event/heretics
	job_rank = ROLE_ARCFIEND
	antag_hud_name = "arcfiend"
	hijack_speed = 0.5
	preview_outfit = /datum/outfit/heretic
	can_assign_self_objectives = TRUE
	default_custom_objective = "Turn a department into a testament for your dark knowledge."

	/// How much power the arcfiend has stored
	var/stored_power = 300
	/// How much power can we store at maximum
	var/max_stored_power = 600

	///Arcfiend traits
	var/static/list/arcfiend_traits = list(
		TRAIT_SHOCKIMMUNE,
		TRAIT_STABLEHEART,
		TRAIT_VIRUSIMMUNE,
		//Arcfiends are beings made out of electricity, so batons do not work on them
		TRAIT_BATON_RESISTANCE,
	)

/datum/antagonist/arcfiend/on_gain()
	owner.current.add_traits(arcfiend_traits)
	return ..()
