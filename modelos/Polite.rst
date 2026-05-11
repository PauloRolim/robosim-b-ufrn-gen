interface Operations {
	move ( lv : boolean )
}

interface Services {
	event drop
	event obstacle
}

controller CPD {
	uses Services requires Operations sref stm_ref0 = Movement
	sref stm_ref1 = Delivery
	connection CPD on obstacle to stm_ref0 on obstacle
	connection stm_ref1 on drop to CPD on drop

	connection stm_ref0 on arrived to stm_ref1 on arrived ( _async )
	cycleDef cycle == 1
}

stm Movement {
	const MOVINGTARGET : nat
	const lv : boolean

	var MovingCycles : nat = 0

	input context { event obstacle }
	output context { requires Operations  event arrived : boolean }
	cycleDef cycle == 1
	initial i0
	state Starting {
		entry $ move ( lv )
	}
	state Moving {
	}
	final f0
	state Waiting {
	}
	transition t0 {
		from i0
		to Starting
	}
	transition t1 {
		from Starting
		to Moving
		exec
	}
	transition t2 {
		from Moving
		to f0
		condition MOVINGTARGET <= MovingCycles
		action $ arrived ! true ; $ move ( false )
	}
	transition t5 {
		from Moving
		to Waiting
		condition not ( MOVINGTARGET <= MovingCycles ) /\ $ obstacle
		action 	$ move ( false )
	}
	transition t6 {
		from Waiting
		to Waiting
		exec
		condition $ obstacle
	}
	transition t7 {
		from Waiting
		to Moving
		condition not $ obstacle
		action $ move ( lv )
	}
	transition t3 {
		from Moving
		to Moving
		exec
		condition not ( MOVINGTARGET <= MovingCycles ) /\ not ( $ obstacle )
		action MovingCycles = MovingCycles + 1
	}
}

stm Delivery {
	input context {  event arrived : boolean }
	output context { event drop }
	cycleDef cycle == 1
	initial i0
	state Waiting {
	}
	state Dropping {
		entry $ drop
	}
	final f0

	transition t3 {
		from Dropping
		to f0
	}
transition t0 {
		from i0
		to Waiting
	}
transition t1 {
		from Waiting
		to Waiting
		exec
		condition not $ arrived
	}
transition t2 {
		from Waiting
		to Dropping
		condition $ arrived
	}
}

module PoliteDelivery {
	connection Trolley on obstacle to ctrl_ref0 on obstacle ( _async )
	connection ctrl_ref0 on drop to Trolley on drop ( _async )
	robotic platform Trolley {
		uses Services provides Operations }

	cref ctrl_ref0 = CPD
	cycleDef cycle == 1
}