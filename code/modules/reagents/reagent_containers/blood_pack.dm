/obj/item/reagent_containers/blood
	name = "blood pack"
	desc = "Contains blood used for transfusion. Must be attached to an IV drip."
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "bloodpack"
	volume = 1000
	w_class = WEIGHT_CLASS_SMALL
	reagent_flags = DRAINABLE
	var/blood_type = null
	var/labelled = 0
	var/color_to_apply = "#FFFFFF"
	var/mutable_appearance/fill_overlay

/obj/item/reagent_containers/blood/Initialize()
	. = ..()
	if(blood_type != null)
		reagents.add_reagent(/datum/reagent/blood, volume, list("donor"=null,"viruses"=null,"blood_DNA"=null,"bloodcolor"=bloodtype_to_color(blood_type), "blood_type"=blood_type,"resistances"=null,"trace_chem"=null))
		update_icon()

/obj/item/reagent_containers/blood/on_reagent_change(changetype)
	if(reagents)
		var/datum/reagent/blood/B = reagents.has_reagent(/datum/reagent/blood)
		if(B && B.data && B.data["blood_type"])
			blood_type = B.data["blood_type"]
			color_to_apply = bloodtype_to_color(blood_type)
		else
			blood_type = null
	update_pack_name()
	update_icon()

/obj/item/reagent_containers/blood/proc/update_pack_name()
	if(!labelled)
		if(blood_type)
			name = "blood pack - [blood_type]"
		else
			name = "blood pack"

/obj/item/reagent_containers/blood/update_overlays()
	. = ..()
	var/v = min(round(reagents.total_volume / volume * 10), 10)
	if(v > 0)
		. += mutable_appearance('icons/obj/reagentfillings.dmi', "bloodpack[v]", color = mix_color_from_reagents(reagents.reagent_list))

/obj/item/reagent_containers/blood/random
	icon_state = "random_bloodpack"

/obj/item/reagent_containers/blood/random/Initialize()
	icon_state = "bloodpack"
	blood_type = pick("A+", "A-", "B+", "B-", "O+", "O-")
	return ..()

/obj/item/reagent_containers/blood/APlus
	blood_type = "A+"

/obj/item/reagent_containers/blood/AMinus
	blood_type = "A-"

/obj/item/reagent_containers/blood/BPlus
	blood_type = "B+"

/obj/item/reagent_containers/blood/BMinus
	blood_type = "B-"

/obj/item/reagent_containers/blood/OPlus
	blood_type = "O+"

/obj/item/reagent_containers/blood/OMinus
	blood_type = "O-"

/obj/item/reagent_containers/blood/lizard
	blood_type = "L"

/obj/item/reagent_containers/blood/universal
	blood_type = "U"

/obj/item/reagent_containers/blood/synthetics
	blood_type = "SY"

/obj/item/reagent_containers/blood/oilblood
	blood_type = "HF"

/obj/item/reagent_containers/blood/jellyblood
	blood_type = "GEL"

/obj/item/reagent_containers/blood/insect
	blood_type = "BUG"

/obj/item/reagent_containers/blood/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/pen) || istype(I, /obj/item/toy/crayon))
		if(!user.is_literate())
			to_chat(user, span_notice("You scribble illegibly on the label of [src]!"))
			return
		var/t = stripped_input(user, "What would you like to label the blood pack?", name, null, 53)
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(user.get_active_held_item() != I)
			return
		if(t)
			labelled = 1
			name = "blood pack - [t]"
		else
			labelled = 0
			update_pack_name()
	else
		return ..()

/obj/item/reagent_containers/blood/attack(mob/living/carbon/C, mob/user, def_zone)
	if(user.a_intent == INTENT_HELP && reagents.total_volume > 0 && iscarbon(C) && user.a_intent == INTENT_HELP)
		if(C.is_mouth_covered())
			to_chat(user, span_notice("You cant drink from the [src] while your mouth is covered."))
			return
		if(user != C)
			user.visible_message(span_danger("[user] forces [C] to drink from the [src]."), \
			span_notice("You force [C] to drink from the [src]"))
			if(!do_mob(user, C, 5 SECONDS, allow_incap = TRUE, allow_lying = TRUE, public_progbar = TRUE))
				return
		else
			if(!do_mob(user, C, 5 SECONDS, allow_incap = TRUE, allow_lying = TRUE, public_progbar = TRUE))
				return

			to_chat(user, span_notice("You take a sip from the [src]."))
			user.visible_message(span_notice("[user] puts the [src] up to their mouth."))
		if(reagents.total_volume <= 0) // Safety: In case you spam clicked the blood bag on yourself, and it is now empty (below will divide by zero)
			return
		var/gulp_size = 3
		var/fraction = min(gulp_size / reagents.total_volume, 1)
		reagents.reaction(C, INGEST, fraction) 	//checkLiked(fraction, M) // Blood isn't food, sorry.
		reagents.trans_to(C, gulp_size)
		reagents.remove_reagent(src, 2) //Inneficency, so hey, IVs are usefull.
		playsound(C.loc,'sound/items/drink.ogg', rand(10, 50), TRUE)
		return
	..()

/obj/item/reagent_containers/blood/bluespace
	name = "bluespace blood pack"
	desc = "Contains blood used for transfusion, this one has been made with bluespace technology to hold much more blood. Must be attached to an IV drip."
	icon_state = "bsbloodpack"
	volume = 2000 //its a blood bath!

/obj/item/reagent_containers/blood/bluespace/attack(mob/living/carbon/C, mob/user, def_zone)
	if(user.a_intent == INTENT_HELP)
		if(user != C)
			to_chat(user, span_notice("You can't force people to drink from the [src]. Nothing comes out from it."))
			return
		else
			to_chat(user, span_notice("You try to suck on the [src], but nothing comes out."))
			return
	else
		..()

/obj/item/reagent_containers/blood/radaway
	name = "RadAway"
	icon_state = "bloodpack_radaway"
	desc = "RadAway is an intravenous chemical solution that bonds with radiation and toxin particles and passes them through the body's system. It takes some time to work and is a potent diuretic."
	labelled = 1
	blood_type = null
	volume = 200
	list_reagents = list(/datum/reagent/medicine/radaway = 200)


/obj/item/reagent_containers/blood/small
	name = "small blood pack"
	volume = 400 //same as plasbucket
	w_class = WEIGHT_CLASS_SMALL
	reagent_flags = INJECTABLE | DRAINABLE | AMOUNT_VISIBLE
