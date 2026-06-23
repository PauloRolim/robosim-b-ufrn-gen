interface MovementI {
	move ( lv : boolean , av : boolean )
}

interface ObstacleI {
	event obstacle : boolean
}

controller SimMovement {
	uses ObstacleI requires MovementI sref stm_ref0 = SimSMovement

	connection SimMovement on obstacle to stm_ref0 on obstacle
	cycleDef cycle == 1
}

stm SimSMovement {
	const Pi : nat
	const lv : boolean , av : boolean
	clock MBC
	var obst : boolean
	input context { uses ObstacleI }
	output context { requires MovementI }
	cycleDef cycle == 1
	initial i0
	state SMoving {
		entry $ move ( lv , false )
	}
	state DMoving {
	}
	junction j0
	state Waiting {
	}
	state STurning {
	entry $ move ( false , av )
	}
	state DTurning {
	}
	junction j1
	junction j2
	transition t0 {
		from i0
		to SMoving
	}
	transition t1 {
		from SMoving
		to DMoving
	}
	transition t2 {
		from DMoving
		to j0
		exec
	}
	transition t3 {
		from j0
		to DMoving
		condition not ( $ obstacle )
	}
	transition t5 {
		from Waiting
		to STurning
	exec
	}
	transition t6 {
		from STurning
		to DTurning
	}
	transition t7 {
		from DTurning
		to j1
	exec
	}
	transition t8 {
		from j1
		to DTurning
	condition since ( MBC ) < Pi
	}
	transition t9 {
		from j1
		to SMoving
	condition since ( MBC ) >= Pi
	}
	transition t4 {
		from j0
		to j2
		condition $ obstacle ? obst
	}
	transition t10 {
		from j2
		to DMoving
		condition not ( obst )
	}
	transition t11 {
		from j2
		to Waiting
		condition obst
		action # MBC ; $ move ( false , false )
	}
}

module SimCMovement {
	connection Vehicle on obstacle to ctrl_ref0 on obstacle ( _async )
	robotic platform Vehicle {
		uses ObstacleI provides MovementI }

	cref ctrl_ref0 = SimMovement
	cycleDef cycle == 1
}