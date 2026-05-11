MACHINE
    user_ctx
SEES
    g_types

CONCRETE_CONSTANTS
		
INIT,
EXEC_1,
EXEC_2,
EXEC_3,
FINAL,
st_READ_INPUTS,
st_STATE_MACHINE,
st_WRITE_OUTPUTS,
st_TIME,
cycle_unit,
SimCMovement_cycleDef,
SimSMovement_cycleDef,
SimSMovement_lv, 
SimSMovement_av, 
SimSMovement_Pi

PROPERTIES
INIT: uint8_t &
EXEC_1: uint8_t &
EXEC_2: uint8_t &
EXEC_3: uint8_t &
FINAL: uint8_t &
st_READ_INPUTS: uint8_t &
st_STATE_MACHINE: uint8_t &
st_WRITE_OUTPUTS: uint8_t &
st_TIME: uint8_t &
cycle_unit:uint32_t &
SimCMovement_cycleDef : uint32_t&
SimSMovement_cycleDef : uint32_t &
SimSMovement_lv : BOOL &
SimSMovement_av : BOOL &
SimSMovement_Pi : uint32_t
END
