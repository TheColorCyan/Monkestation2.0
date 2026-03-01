/*

Difficulty: Medium

This is a monkestation override for wendigo

*/

/mob/living/simple_animal/hostile/megafauna/wendigo/monkestation_override
	name = "malnurished wendigo"
	desc = "A mythological man-eating legendary creature, the sockets of it's eyes track you with an unsatiated hunger. \
			This one seems highly malnurished, it will probably be easier to fight"

	stomp_range = 0
	scream_cooldown_time = 5 SECONDS

/mob/living/simple_animal/hostile/megafauna/wendigo/monkestation_override/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	teleport = new(src)
	shotgun_blast = new(src)
	ground_slam = new(src)
	alternating_circle = new(src)
	spiral = new(src)
	teleport.Grant(src)
	shotgun_blast.Grant(src)
	ground_slam.Grant(src)
	alternating_circle.Grant(src)
	spiral.Grant(src)
