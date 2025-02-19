#define MINER_DASH_RANGE 4

/*

BLOOD-DRUNK MINER

Effectively a highly aggressive miner, the blood-drunk miner has very few attacks but compensates by being highly aggressive.

The blood-drunk miner's attacks are as follows
- If not in KA range, it will rapidly dash at its targette
- If in KA range, it will fire its kinetic accelerator
- If in melee range, will rapidly attack, akin to an actual player
- After any of these attacks, may transform its cleaving saw:
	Untransformed, it attacks very rapidly for smaller amounts of damage
	Transformed, it attacks at normal speed for higher damage and cleaves enemies hit

When the blood-drunk miner dies, it leaves behind the cleaving saw it was using and its kinetic accelerator.

Difficulty: Medium

*/

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner
	name = "blood-drunk miner"
	desc = "A miner destined to wander forever, engaged in an endless hunt."
	health = 900
	maxHealth = 900
	icon_state = "miner"
	icon_living = "miner"
	icon = 'icons/mob/broadMobs.dmi'
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	light_color = "#E4C7C5"
	movement_type = GROUND
	speak_emote = list("roars")
	faction = list("raider")
	speed = 1
	move_to_delay = 2
	projectiletype = /obj/item/projectile/kinetic/miner
	projectilesound = 'sound/weapons/kenetic_accel.ogg'
	ranged = 1
	ranged_cooldown_time = 16
	pixel_x = -16
	crusher_loot = list(/obj/item/melee/transforming/cleaving_saw, /obj/item/gun/energy/kinetic_accelerator/premiumka, /obj/item/crusher_trophy/miner_eye)
	loot = list()
	wander = FALSE
	del_on_death = TRUE
	blood_volume = BLOOD_VOLUME_NORMAL
	medal_type = BOSS_MEDAL_MINER
	var/obj/item/melee/transforming/cleaving_saw/miner/miner_saw
	var/time_until_next_transform = 0
	var/dashing = FALSE
	var/dash_cooldown = 15
	var/guidance = FALSE
	deathmessage = "falls to the ground, decaying into glowing particles."
	death_sound = "bodyfall"

	footstep_type = FOOTSTEP_MOB_HEAVY

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/guidance
	guidance = TRUE

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/hunter/AttackingTarget()
	. = ..()
	if(. && prob(12))
		INVOKE_ASYNC(src,PROC_REF(dash))

/obj/item/melee/transforming/cleaving_saw/miner //nerfed saw because it is very murdery
	force = 6
	force_on = 10

/obj/item/melee/transforming/cleaving_saw/miner/attack(mob/living/target, mob/living/carbon/human/user)
	if(!target)
		return
	target.add_stun_absorption("miner", 10, INFINITY)
	. = ..()
	target.stun_absorption -= "miner"

/obj/item/projectile/kinetic/miner
	damage = 40
	pixels_per_second = TILES_TO_PIXELS(11.111)
	icon_state = "ka_tracer"
	range = MINER_DASH_RANGE

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/Initialize()
	. = ..()
	internal = new/obj/item/gps/internal/miner(src)
	miner_saw = new(src)

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/adjustment_amount = amount * 0.1
	if(world.time + adjustment_amount > next_action)
		DelayNextAction(adjustment_amount, considered_action = FALSE, flush = TRUE) //attacking it interrupts it attacking, but only briefly
	. = ..()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/death()
	if(health > 0)
		return
	new /obj/effect/temp_visual/dir_setting/miner_death(loc, dir)
	return ..()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/Move(atom/newloc)
	if(dashing || (newloc && newloc.z == z && (islava(newloc) || ischasm(newloc)))) //we're not stupid!
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/ex_act(severity, target)
	if(dash())
		return
	return ..()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/AttackingTarget()
	var/atom/my_target = get_target()
	if(QDELETED(my_target))
		return
	if(!CheckActionCooldown() || !Adjacent(my_target)) //some cheating
		INVOKE_ASYNC(src,PROC_REF(quick_attack_loop))
		return
	face_atom(my_target)
	// if(isliving(my_target))
	// 	var/mob/living/L = my_target
	// 	if(L.stat == DEAD)
	// 		visible_message(span_danger("[src] butchers [L]!"),
	// 		span_userdanger("You butcher [L], restoring your health!"))
	// 		if(!is_station_level(z) || client) //NPC monsters won't heal while on station
	// 			if(guidance)
	// 				adjustHealth(-L.maxHealth)
	// 			else
	// 				adjustHealth(-(L.maxHealth * 0.5))
	// 		L.gib()
	// 		return TRUE
	miner_saw.melee_attack_chain(src, my_target, null, ATTACK_IGNORE_CLICKDELAY)
	FlushCurrentAction()
	if(guidance)
		adjustHealth(-2)
	transform_weapon()
	INVOKE_ASYNC(src,PROC_REF(quick_attack_loop))
	return TRUE

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!used_item && !isturf(A))
		used_item = miner_saw
	..()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/GiveTarget(new_target)
	var/atom/my_target = get_target()
	var/targets_the_same = (new_target == my_target)
	. = ..()
	if(. && my_target && !targets_the_same)
		wander = TRUE
		transform_weapon()
		INVOKE_ASYNC(src,PROC_REF(quick_attack_loop))

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/OpenFire()
	var/atom/my_target = get_target()
	Goto(my_target, move_to_delay, minimum_distance)
	if(get_dist(src, my_target) > MINER_DASH_RANGE && dash_cooldown <= world.time)
		INVOKE_ASYNC(src,PROC_REF(dash), my_target)
	else
		shoot_ka()
	transform_weapon()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/proc/shoot_ka()
	var/atom/my_target = get_target()
	if(ranged_cooldown <= world.time && get_dist(src, my_target) <= MINER_DASH_RANGE && !Adjacent(my_target))
		ranged_cooldown = world.time + ranged_cooldown_time
		visible_message(span_danger("[src] fires the proto-kinetic accelerator!"))
		face_atom(my_target)
		new /obj/effect/temp_visual/dir_setting/firing_effect(loc, dir)
		Shoot(my_target)
		DelayNextAction(CLICK_CD_RANGE, flush = TRUE)

//I'm still of the belief that this entire proc needs to be wiped from existence.
//  do not take my touching of it to be endorsement of it. ~mso
// hi, lagg here, fuckin proc sucks, bye!
/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/proc/quick_attack_loop()
	var/atom/my_target = get_target()
	// while(!QDELETED(my_target) && !CheckActionCooldown()) //this is done this way because next_move can change to be sooner while we sleep.
	// 	stoplag(1)
	// sleep((next_action - world.time) * 1.5) //but don't ask me what the fuck this is about
	// if(QDELETED(my_target))
	// 	return
	if(dashing || !CheckActionCooldown() || !Adjacent(my_target))
		if(dashing && next_action <= world.time)
			SetNextAction(1, considered_action = FALSE, immediate = FALSE, flush = TRUE)
		INVOKE_ASYNC(src,PROC_REF(quick_attack_loop)) //lets try that again.
		return
	AttackingTarget()

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/proc/dash(atom/dash_target)
	if(world.time < dash_cooldown)
		return
	var/list/accessable_turfs = list()
	var/self_dist_to_target = 0
	var/turf/own_turf = get_turf(src)
	if(!QDELETED(dash_target))
		self_dist_to_target += get_dist(dash_target, own_turf)
	for(var/turf/open/O in RANGE_TURFS(MINER_DASH_RANGE, own_turf))
		var/turf_dist_to_target = 0
		if(!QDELETED(dash_target))
			turf_dist_to_target += get_dist(dash_target, O)
		if(get_dist(src, O) >= MINER_DASH_RANGE && turf_dist_to_target <= self_dist_to_target && !islava(O) && !ischasm(O))
			var/valid = TRUE
			for(var/turf/T in getline(own_turf, O))
				if(is_blocked_turf(T, TRUE))
					valid = FALSE
					continue
			if(valid)
				accessable_turfs[O] = turf_dist_to_target
	var/turf/target_turf
	if(!QDELETED(dash_target))
		var/closest_dist = MINER_DASH_RANGE
		for(var/t in accessable_turfs)
			if(accessable_turfs[t] < closest_dist)
				closest_dist = accessable_turfs[t]
		for(var/t in accessable_turfs)
			if(accessable_turfs[t] != closest_dist)
				accessable_turfs -= t
	if(!LAZYLEN(accessable_turfs))
		return
	dash_cooldown = world.time + initial(dash_cooldown)
	target_turf = pick(accessable_turfs)
	var/turf/step_back_turf = get_step(target_turf, get_cardinal_dir(target_turf, own_turf))
	var/turf/step_forward_turf = get_step(own_turf, get_cardinal_dir(own_turf, target_turf))
	new /obj/effect/temp_visual/small_smoke/halfsecond(step_back_turf)
	new /obj/effect/temp_visual/small_smoke/halfsecond(step_forward_turf)
	var/obj/effect/temp_visual/decoy/fading/halfsecond/D = new (own_turf, src)
	forceMove(step_back_turf)
	playsound(own_turf, 'sound/weapons/punchmiss.ogg', 40, 1, -1)
	dashing = TRUE
	alpha = 0
	animate(src, alpha = 255, time = 5)
	sleep(2)
	D.forceMove(step_forward_turf)
	forceMove(target_turf)
	playsound(target_turf, 'sound/weapons/punchmiss.ogg', 40, 1, -1)
	sleep(1)
	dashing = FALSE
	shoot_ka()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/proc/transform_weapon()
	if(time_until_next_transform <= world.time)
		miner_saw.transform_cooldown = 0
		miner_saw.transform_weapon(src, TRUE)
		icon_state = "miner[miner_saw.active ? "_transformed":""]"
		icon_living = "miner[miner_saw.active ? "_transformed":""]"
		time_until_next_transform = world.time + rand(50, 100)

/obj/effect/temp_visual/dir_setting/miner_death
	icon_state = "miner_death"
	duration = 15

/obj/effect/temp_visual/dir_setting/miner_death/Initialize(mapload, set_dir)
	. = ..()
	INVOKE_ASYNC(src,PROC_REF(fade_out))

/obj/effect/temp_visual/dir_setting/miner_death/proc/fade_out()
	var/matrix/M = new
	M.Turn(pick(90, 270))
	var/final_dir = dir
	if(dir & (EAST|WEST)) //Facing east or west
		final_dir = pick(NORTH, SOUTH) //So you fall on your side rather than your face or ass

	animate(src, transform = M, pixel_y = -6, dir = final_dir, time = 2, easing = EASE_IN|EASE_OUT)
	sleep(5)
	animate(src, color = list("#A7A19E", "#A7A19E", "#A7A19E", list(0, 0, 0)), time = 10, easing = EASE_IN, flags = ANIMATION_PARALLEL)
	sleep(4)
	animate(src, alpha = 0, time = 6, easing = EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/item/gps/internal/miner
	icon_state = null
	gpstag = "Resonant Signal"
	desc = "The sweet blood, oh, it sings to me."
	invisibility = 100

/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/doom
	name = "hostile-environment miner"
	desc = "A miner destined to hop across dimensions for all eternity, hunting anomalous creatures."
	speed = 8
	move_to_delay = 8
	ranged_cooldown_time = 8
	dash_cooldown = 8

#undef MINER_DASH_RANGE
