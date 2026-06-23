interface Movementl {
	move ( lv : boolean , av : boolean )
}

interface Sensorsl {
	event obstacle
}

robotic platform MyPlatform {
	uses Sensorsl provides Movementl }

controller SimMovement {
	uses Sensorsl requires Movementl sref stm_ref0 = SimSMovement
	connection SimMovement on obstacle to stm_ref0 on obstacle
	cycleDef cycle == 1
}

stm SimSMovement {
	const lv : boolean
	const av : boolean
	const Pi : nat
	clock MBC
	input context { uses Sensorsl }
	output context { requires Movementl }
	cycleDef cycle == 1
	initial i0
	state SMoving {
		entry $ move ( lv , false )
	}
	state DMoving {
	}
	state Waiting {
	}
	state STurning {
		entry $ move ( false , av )
	}
	state DTurning {
	}
	junction j0
	junction j1
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
		condition not $ obstacle
	}
	transition t4 {
		from j0
		to Waiting
		condition $ obstacle
		action # MBC ; $ move ( false , false )
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
	transition t9 {
		from j1
		to DTurning
		condition since ( MBC ) < Pi
	}
	transition t10 {
		from j1
		to SMoving
		condition since ( MBC ) >= Pi
	}
}

module SimCMovement {
	connection Vehicle on obstacle to ctrl_ref0 on obstacle ( _async )
	robotic platform Vehicle {
		uses Sensorsl provides Movementl }

	cref ctrl_ref0 = SimMovement
	cycleDef cycle == 1
}