/datum/antagonist/ninja
	name = "\improper Space Ninja"
	antagpanel_category = ANTAG_GROUP_NINJAS
	job_rank = ROLE_NINJA
	antag_hud_name = "space_ninja"
	hijack_speed = 1
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	suicide_cry = "FOR THE SPIDER CLAN!!"
	preview_outfit = /datum/outfit/ninja_preview
	can_assign_self_objectives = TRUE
	ui_name = "AntagInfoNinja"
	default_custom_objective = "Destroy vital station infrastructure, without being seen."
	///Whether or not this ninja will obtain objectives
	var/give_objectives = TRUE
	///Whether or not this ninja receives the standard equipment
	var/give_equipment = TRUE

/**
 * Proc that equips the space ninja outfit on a given individual.  By default this is the owner of the antagonist datum.
 *
 * Proc that equips the space ninja outfit on a given individual.  By default this is the owner of the antagonist datum.
 * Arguments:
 * * ninja - The human to receive the gear
 * * Returns a proc call on the given human which will equip them with all the gear.
 */
/datum/antagonist/ninja/proc/equip_space_ninja(mob/living/carbon/human/ninja = owner.current)
	return ninja.equipOutfit(/datum/outfit/ninja)

/**
 * Proc that adds the proper memories to the antag datum
 *
 * Proc that adds the ninja starting memories to the owner of the antagonist datum.
 */
/datum/antagonist/ninja/proc/addMemories()
	antag_memory += "I am an elite mercenary of the mighty Spider Clan. A <font color='red'><B>SPACE NINJA</B></font>!<br>"
	antag_memory += "Surprise is my weapon. Shadows are my armor. Without them, I am nothing.<br>"

/datum/objective/cyborg_hijack
	explanation_text = "Use your gloves to convert at least one cyborg to aid you in sabotaging the station."

/* monkestation edit: remove doorjack objective
/datum/objective/door_jack
	///How many doors that need to be opened using the gloves to pass the objective
	var/doors_required = 0
*/

/datum/objective/plant_explosive
	var/area/detonation_location

/datum/objective/security_scramble
	explanation_text = "Use your gloves on a security console to set everyone to arrest at least once.  Note that the AI will be alerted once you begin!"

/datum/objective/terror_message
	explanation_text = "Use your gloves on a communication console in order to bring another threat to the station.  Note that the AI will be alerted once you begin!"

/datum/objective/research_secrets
	explanation_text = "Use your gloves on a research & development server to sabotage research efforts.  Note that the AI will be alerted once you begin!"

/**
 * Proc that adds all the ninja's objectives to the antag datum.
 *
 * Proc that adds all the ninja's objectives to the antag datum.  Called when the datum is gained.
 */
/datum/antagonist/ninja/proc/addObjectives()
	//Cyborg Hijack: Flag set to complete in the DrainAct in ninjaDrainAct.dm
	var/datum/objective/hijack = new /datum/objective/cyborg_hijack()
	objectives += hijack

	// Break into science and mess up their research. Only add this objective if the similar steal objective is possible.
	var/datum/objective/research_secrets/sabotage_research = new /datum/objective/research_secrets()
	objectives += sabotage_research

	/* monkestation edit: remove doorjack objective
	//Door jacks, flag will be set to complete on when the last door is hijacked
	var/datum/objective/door_jack/doorobjective = new /datum/objective/door_jack()
	doorobjective.doors_required = rand(15,40)
	doorobjective.explanation_text = "Use your gloves to doorjack [doorobjective.doors_required] airlocks on the station."
	objectives += doorobjective
	*/

	//Explosive plant, the bomb will register its completion on priming
	var/datum/objective/plant_explosive/bombobjective = new /datum/objective/plant_explosive()
	for(var/sanity in 1 to 100) // 100 checks at most.
		var/area/selected_area = pick(GLOB.areas)
		if(!is_station_level(selected_area.z) || !(selected_area.area_flags & VALID_TERRITORY))
			continue
		bombobjective.detonation_location = selected_area
		break
	if(bombobjective.detonation_location)
		bombobjective.explanation_text = "Detonate your starter bomb in [bombobjective.detonation_location].  Note that the bomb will not work anywhere else!"
		objectives += bombobjective

	//Security Scramble, set to complete upon using your gloves on a security console
	var/datum/objective/securityobjective = new /datum/objective/security_scramble()
	objectives += securityobjective

	//Message of Terror, set to complete upon using your gloves a communication console
	var/datum/objective/communicationobjective = new /datum/objective/terror_message()
	objectives += communicationobjective

	//Survival until end
	var/datum/objective/survival = new /datum/objective/survive()
	survival.owner = owner
	objectives += survival

/datum/antagonist/ninja/greet()
	. = ..()
	SEND_SOUND(owner.current, sound('sound/effects/ninja_greeting.ogg'))
	to_chat(owner.current, span_danger("I am an elite mercenary of the mighty Spider Clan!"))
	to_chat(owner.current, span_warning("Surprise is my weapon. Shadows are my armor. Without them, I am nothing."))
	to_chat(owner.current, span_notice("The station is located to your [dir2text(get_dir(owner.current, locate(world.maxx/2, world.maxy/2, owner.current.z)))]. A thrown ninja star will be a great way to get there."))
	owner.announce_objectives()

/datum/antagonist/ninja/on_gain()
	if(give_objectives)
		addObjectives()
	addMemories()
	if(give_equipment)
		equip_space_ninja(owner.current)

	owner.current.mind.set_assigned_role(SSjob.GetJobType(/datum/job/space_ninja))
	owner.current.mind.special_role = ROLE_NINJA
	return ..()

/datum/antagonist/ninja/admin_add(datum/mind/new_owner,mob/admin)
	new_owner.set_assigned_role(SSjob.GetJobType(/datum/job/space_ninja))
	new_owner.special_role = ROLE_NINJA
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has ninja'ed [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has ninja'ed [key_name(new_owner)].")

/datum/antagonist/ninja/antag_token(datum/mind/hosts_mind, mob/spender)
	if(isliving(spender) && hosts_mind)
		hosts_mind.current.unequip_everything()
		new /obj/effect/holy(hosts_mind.current.loc)
		QDEL_IN(hosts_mind.current, 20)

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
		if(!isturf(carp_spawn.loc))
			stack_trace("Carp spawn found not on a turf: [carp_spawn.type] on [isnull(carp_spawn.loc) ? "null" : carp_spawn.loc.type]")
			continue
		spawn_locs += carp_spawn.loc
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/key = spender.ckey

	//spawn the ninja and assign the candidate
	var/mob/living/carbon/human/ninja = create_space_ninja(pick(spawn_locs))
	ninja.PossessByPlayer(key)
	ninja.mind.add_antag_datum(/datum/antagonist/ninja)

