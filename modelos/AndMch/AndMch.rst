interface Inputs_1 {
	event input_mch_1
}

interface Outputs_1 {
	output_mch_1 ( oo : boolean )
}

interface Inputs_2 {
	event input_mch_2
}

interface Outputs_2 {
	output_mch_2 ( oo : boolean )
}

controller CPD {
	uses Inputs_1 uses Inputs_2 requires Outputs_1 requires Outputs_2 sref stm_ref0 = Machine_1
	sref stm_ref1 = Machine_2
	connection CPD on input_mch_1 to stm_ref0 on input_mch_1
	connection stm_ref0 on com_var to stm_ref1 on com_var ( _async )
	connection CPD on input_mch_2 to stm_ref1 on input_mch_2
	cycleDef cycle == 1
}

stm Machine_1 {
	const OUT : boolean
	input context { uses Inputs_1 }
	output context { requires Outputs_1 event com_var : boolean }
	cycleDef cycle == 1
	initial i0
	state Off {
	}
	state On {
	}
	transition t0 {
		from i0
		to Off
	}
	transition t1 {
		from Off
		to On
		exec
		condition $ input_mch_1
		action $ output_mch_1 ( OUT ) ; $ com_var ! true
	}
	transition t2 {
		from On
		to Off
		exec
		condition not ( $ input_mch_1 )
		action $ output_mch_1 ( false ) ; $ com_var ! false
	}
}

stm Machine_2 {
	const OUT : boolean
	input context { uses Inputs_2 event com_var : boolean }
	output context { requires Outputs_2 }
	cycleDef cycle == 1
	initial i0
	state Off {
	}
	state On {
	}
	transition t0 {
		from i0
		to Off
	}
	transition t1 {
		from Off
		to On
		exec
		condition $ com_var /\ $ input_mch_2
		action $ output_mch_2 ( OUT )
	}
	transition t2 {
		from On
		to Off
		exec
		condition not ( $ com_var ) /\ $ input_mch_2
		action $ output_mch_2 ( false )
	}
	transition t3 {
		from On
		to Off
		exec
		condition $ com_var /\ not ( $ input_mch_2 )
		action $ output_mch_2 ( false )
	}
}

module AndMachine {
	connection Robot on input_mch_2 to ctrl_ref0 on input_mch_2 ( _async )
	connection Robot on input_mch_1 to ctrl_ref0 on input_mch_1 ( _async )
	robotic platform Robot {
		uses Inputs_1 uses Inputs_2 provides Outputs_1 provides Outputs_2 }

	cref ctrl_ref0 = CPD
	cycleDef cycle == 1
}