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
FINAL,
st_READ_INPUTS,
st_STATE_MACHINE,
st_WRITE_OUTPUTS,
st_TIME,
cycle_unit,
PoliteDelivery_cycleDef,
Movement_cycleDef, 
Delivery_cycleDef,
Movement_MOVINGTARGET, 
Movement_lv

PROPERTIES
INIT: uint8_t &
EXEC_1: uint8_t &
EXEC_2: uint8_t &
EXEC_3: uint8_t &
EXEC_4: uint8_t &
FINAL: uint8_t &
st_READ_INPUTS: uint8_t &
st_STATE_MACHINE: uint8_t &
st_WRITE_OUTPUTS: uint8_t &
st_TIME: uint8_t &
cycle_unit:uint32_t &
PoliteDelivery_cycleDef : uint32_t&
Movement_cycleDef : uint32_t &
Delivery_cycleDef : uint32_t &
Movement_MOVINGTARGET : uint32_t &
Movement_lv : BOOL
END
