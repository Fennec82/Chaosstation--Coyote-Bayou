/obj/item/mop
	desc = "The world of janitalia wouldn't be complete without a mop."
	name = "mop"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 3
	throwforce = 5
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("mopped", "bashed", "bludgeoned", "whacked")
	resistance_flags = FLAMMABLE
	var/mopping = 0
	var/mopcount = 0
	var/mopcap = 5
	var/stamusage = 2
	force_string = "robust... against germs"
	var/insertable = TRUE

/obj/item/mop/New()
	..()
	create_reagents(mopcap, NONE, NO_REAGENTS_VALUE)


/obj/item/mop/proc/clean(turf/A)
	if(reagents.has_reagent(/datum/reagent/water, 1) || reagents.has_reagent(/datum/reagent/water/holywater, 1) || reagents.has_reagent(/datum/reagent/consumable/ethanol/vodka, 1) || reagents.has_reagent(/datum/reagent/abraxo_cleaner, 1))
		SEND_SIGNAL(A, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
		A.clean_blood()
		for(var/obj/effect/O in A)
			if(is_cleanable(O))
				qdel(O)
	reagents.reaction(A, TOUCH, 10)	//Needed for proper floor wetting.
	reagents.remove_any(1)			//reaction() doesn't use up the reagents


/obj/item/mop/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	var/mob/living/L = user

	if(istype(L) && IS_STAMCRIT(L))
		to_chat(user, span_danger("You're too exhausted for that."))
		return

	if(reagents.total_volume < 1)
		to_chat(user, span_warning("Your mop is dry!"))
		return

	var/turf/T = get_turf(A)

	if(istype(A, /obj/item/reagent_containers/glass/bucket) || istype(A, /obj/structure/janitorialcart))
		return

	if(T)
		user.visible_message("[user] cleans \the [T] with [src].", span_notice("You clean \the [T] with [src]."))
		clean(T)
		user.DelayNextAction(CLICK_CD_MELEE)
		user.do_attack_animation(T, used_item = src)
		if(istype(L))
			L.adjustStaminaLossBuffered(stamusage)
		playsound(T, "slosh", 50, 1)


/obj/effect/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap))
		return
	else
		return ..()


/obj/item/mop/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	if(insertable)
		J.put_in_cart(src, user)
		J.mymop=src
		J.update_icon()
	else
		to_chat(user, span_warning("You are unable to fit your [name] into the [J.name]."))
		return

/obj/item/mop/cyborg
	insertable = FALSE

/obj/item/mop/advanced
	desc = "The most advanced tool in a custodian's arsenal, complete with a condenser for self-wetting! Just think of all the viscera you will clean up with this!"
	name = "advanced mop"
	mopcap = 10
	icon_state = "advmop"
	inhand_icon_state = "mop"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 6
	throwforce = 8
	throw_range = 4
	stamusage = 1
	var/refill_enabled = TRUE //Self-refill toggle for when a janitor decides to mop with something other than water.
	var/refill_rate = 1 //Rate per process() tick mop refills itself
	var/refill_reagent = /datum/reagent/water //Determins what reagent to use for refilling, just in case someone wanted to make a HOLY MOP OF PURGING

/obj/item/mop/advanced/New()
	..()
	START_PROCESSING(SSobj, src)

/obj/item/mop/advanced/attack_self(mob/user)
	refill_enabled = !refill_enabled
	if(refill_enabled)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj,src)
	to_chat(user, span_notice("You set the condenser switch to the '[refill_enabled ? "ON" : "OFF"]' position."))
	playsound(user, 'sound/machines/click.ogg', 30, 1)

/obj/item/mop/advanced/process()

	if(reagents.total_volume < mopcap)
		reagents.add_reagent(refill_reagent, refill_rate)

/obj/item/mop/advanced/examine(mob/user)
	. = ..()
	. += span_notice("The condenser switch is set to <b>[refill_enabled ? "ON" : "OFF"]</b>.")

/obj/item/mop/advanced/Destroy()
	if(refill_enabled)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mop/advanced/cyborg
	insertable = FALSE
