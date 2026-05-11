MACHINE
    user_ctx
SEES
    g_types

CONCRETE_CONSTANTS
		
INIT,
EXEC_1,
EXEC_2,
EXEC_3,
EXEC_4,
EXEC_5,
FINAL,
st_READ_INPUTS,
st_STATE_MACHINE,
st_WRITE_OUTPUTS,
st_TIME,
cycle_unit,
AndMachine_cycleDef,
Machine_1_cycleDef, 
Machine_2_cycleDef,
Machine_1_OUT, 
Machine_2_OUT

PROPERTIES
INIT: uint8_t &
EXEC_1: uint8_t &
EXEC_2: uint8_t &
EXEC_3: uint8_t &
EXEC_4: uint8_t &
EXEC_5: uint8_t &
FINAL: uint8_t &
st_READ_INPUTS: uint8_t &
st_STATE_MACHINE: uint8_t &
st_WRITE_OUTPUTS: uint8_t &
st_TIME: uint8_t &
cycle_unit:uint32_t &
AndMachine_cycleDef : uint32_t&
Machine_1_cycleDef : uint32_t &
Machine_2_cycleDef : uint32_t &
Machine_1_OUT : BOOL &
Machine_2_OUT : BOOL
END
