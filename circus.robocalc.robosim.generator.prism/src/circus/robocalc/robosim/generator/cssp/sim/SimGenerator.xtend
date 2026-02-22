/********************************************************************************
 * Copyright (c) 2019 University of York and others
 * 
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 * 
 * SPDX-License-Identifier: EPL-2.0
 * 
 * Contributors:
 *   Alvaro Miyazawa - initial definition
 *
 ********************************************************************************/

package circus.robocalc.robosim.generator.cssp.sim

import circus.robocalc.robochart.RCPackage
import circus.robocalc.robosim.textual.generator.AbstractRoboSimGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.Diagnostician
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import circus.robocalc.robosim.ExecTrigger
import circus.robocalc.robochart.Variable
import circus.robocalc.robochart.VariableList
import circus.robocalc.robochart.VariableModifier
import circus.robocalc.robosim.SimMachineDef
import circus.robocalc.robochart.IntegerExp
import circus.robocalc.robochart.Type
import circus.robocalc.robochart.TypeRef
import circus.robocalc.robochart.PrimitiveType
import circus.robocalc.robochart.StateMachineDef
import circus.robocalc.robochart.Expression
import circus.robocalc.robochart.Equals
import circus.robocalc.robochart.Interface
import circus.robocalc.robochart.Context
import circus.robocalc.robochart.Statement
import circus.robocalc.robochart.OperationDef
import circus.robocalc.robochart.Node
import circus.robocalc.robochart.Transition
import circus.robocalc.robochart.State
import circus.robocalc.robochart.EntryAction
import org.eclipse.emf.ecore.EObject
import circus.robocalc.robosim.SimCall
import circus.robocalc.robochart.BooleanExp
import circus.robocalc.robochart.RefExp
import circus.robocalc.robochart.Parameter

class SimGenerator extends AbstractRoboSimGenerator {

	override getID() {
		"ROBOSIM_PRISM_GENERATOR"
	}

	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		System.out.println("[RoboSim] Generating CSSP model for " + resource.URI.toString)

		var diagnostic = Diagnostician.INSTANCE.validate(resource.getContents().get(0));

		// TODO: define a predicate for warningIsRelevant (see GeneratorUtils in the other generator plugins)
		//if (diagnostic.children.filter[d|gu.warningIsRelevant(d)].size() > 0) {
		//if (diagnostic.children.size() > 0) {
			// if there are relevant warning, do not generate
		//	return;
		//}
		
		val UserCtx = resource.allContents.head as RCPackage;
 		   if (UserCtx !== null){
 				var pathUserCtx = "generated/" + resource.getURI().lastSegment + "/"
 				fsa.generateFile(pathUserCtx+"user_ctx.mch", generateUserCtx(UserCtx))
 		   }
		
		val UserCtxi = resource.allContents.head as RCPackage;
 		   if (UserCtxi !== null) {
 				var pathUserCtxi = "generated/" + resource.getURI().lastSegment + "/"
 				fsa.generateFile(pathUserCtxi+"user_ctx_i.imp", generateUserCtxi(UserCtxi))
 		   }
		
		val Logici = resource.allContents.head as RCPackage;
			if (Logici !== null){
				var pathLogici = "generated/" + resource.getURI().lastSegment + "/"
				fsa.generateFile(pathLogici+"logic_i.imp", generateLogici(Logici))
			} 
		
		/*val fileExtension = resource.URI.fileExtension
		if ("rsa".equals(fileExtension)) {
			// TODO: generator assertions
		} else if ("rst".equals(fileExtension)){
			// TODO: generate robosim
		}*/
		
	}
	
	def generateLogici(RCPackage Logici){
		val machine = getSimMachine(Logici)
	'''
		IMPLEMENTATION
			logic_i
		 		
		REFINES
		 	logic
		SEES
		 	g_types,
		 	g_operators,
		 	io_constants,
		 	lchip_interface,
		 	user_ctx,
		 	inputs
		CONCRETE_VARIABLES
		board_0_O1,
		board_0_O2,
		first_time,
		SM_«getSimMachine(Logici).name»_state,
		cycle_timer,
		cycle_state,
		«FOR clk : Logici.machines.head.clocks.indexed SEPARATOR " , " AFTER ", "»var_«clk.value.name»_«clk.key + 1»«ENDFOR»
		«generateInputEvents(machine)»
		«FOR iface : machine.outputContext.RInterfaces»
		   «FOR op : iface.operations»
		   o_«op.name»_lv,
		   o_«op.name»_av
		   «ENDFOR»
		«ENDFOR»
				
		INVARIANT 
		board_0_O1 : uint8_t &
		board_0_O2 : uint8_t &
		first_time: BOOL &
		SM_«getSimMachine(Logici).name»_state: uint32_t &
		cycle_timer: uint32_t &
		cycle_state: uint8_t &
		cycle_state: {st_READ_INPUTS, st_STATE_MACHINE, st_WRITE_OUTPUTS, st_TIME} &
		«FOR clk : Logici.machines.head.clocks.indexed SEPARATOR " & " AFTER " & "»var_«clk.value.name»_«clk.key + 1» : uint32_t«ENDFOR»
		«FOR iface : machine.inputContext.interfaces»
		    «FOR ev : iface.events.indexed»i_«ev.value.name»: uint8_t &«ENDFOR»
 	    «ENDFOR»
		«FOR iface : machine.outputContext.RInterfaces»
		   «FOR op : iface.operations»
		   o_«op.name»_lv: uint8_t &
		   o_«op.name»_av: uint8_t
		   «ENDFOR»
		«ENDFOR»
		
		INITIALISATION
		    
		board_0_O1 := IO_OFF;
		board_0_O2 := IO_OFF;
		first_time:= TRUE;
		cycle_timer := 0;
		cycle_state := st_READ_INPUTS;
		SM_«getSimMachine(Logici).name»_state := INIT;
		«FOR clk : Logici.machines.head.clocks.indexed SEPARATOR " ; " AFTER "; "»var_«clk.value.name»_«clk.key + 1»:= 0«ENDFOR»
		«FOR iface : machine.inputContext.interfaces»
		    «FOR ev : iface.events.indexed SEPARATOR "; " AFTER "; "»i_«ev.value.name»:= IO_OFF«ENDFOR»
		«ENDFOR»
		«FOR iface : machine.outputContext.RInterfaces»
		   «FOR op : iface.operations»
		   o_«op.name»_lv:= IO_OFF;
		   o_«op.name»_av:= IO_OFF
		   «ENDFOR»
		«ENDFOR»
		
		LOCAL_OPERATIONS
		
		execute_model_cycle =
		PRE cycle_state = st_TIME
		THEN
		SM_«getSimMachine(Logici).name»_state :: uint32_t ||
		first_time:: BOOL ||
		cycle_timer::uint32_t ||
		cycle_state ::uint32_t ||
		«FOR clk : Logici.machines.head.clocks.indexed SEPARATOR " || " AFTER " || "»var_«clk.value.name»_«clk.key + 1» :: uint32_t«ENDFOR»
		«FOR iface : machine.inputContext.interfaces»
		    «FOR ev : iface.events.indexed SEPARATOR " || " AFTER " || "»i_«ev.value.name»:: uint8_t«ENDFOR»
		«ENDFOR»
		«FOR iface : machine.outputContext.RInterfaces»
		   «FOR op : iface.operations»
		   o_«op.name»_lv:: uint8_t ||
		   o_«op.name»_av:: uint8_t
		   «ENDFOR»
		«ENDFOR»
		END; 
		
		SM_«getSimMachine(Logici).name»=
		PRE cycle_state = st_STATE_MACHINE
		THEN
		SM_«getSimMachine(Logici).name»_state :: uint32_t ||
		first_time:: BOOL ||
		cycle_timer::uint32_t ||
		cycle_state ::uint32_t ||
		«FOR clk : Logici.machines.head.clocks.indexed SEPARATOR " || " AFTER " || "»var_«clk.value.name»_«clk.key + 1» :: uint32_t«ENDFOR»
		«FOR iface : machine.inputContext.interfaces»
		    «FOR ev : iface.events.indexed SEPARATOR " || " AFTER " || "»i_«ev.value.name»:: uint8_t«ENDFOR»
		«ENDFOR»
		«FOR iface : machine.outputContext.RInterfaces»
		   «FOR op : iface.operations»
		   o_«op.name»_lv:: uint8_t ||
		   o_«op.name»_av:: uint8_t
		   «ENDFOR»
		«ENDFOR»
		END;
		
		read_model_inputs =
		PRE cycle_state = st_READ_INPUTS
		THEN
		cycle_state ::uint32_t ||
		«FOR iface : machine.inputContext.interfaces»
		«FOR ev : iface.events.indexed SEPARATOR " || "»i_«ev.value.name»:: uint8_t«ENDFOR»
		«ENDFOR»
		END;
		
		«FOR iface : machine.inputContext.interfaces»
		«FOR ev : iface.events.indexed SEPARATOR " \n "»
		read_i_«ev.value.name» =
		PRE cycle_state = st_READ_INPUTS
		THEN
		i_«ev.value.name»:: uint8_t
		END;
		«ENDFOR»
		«ENDFOR»
		
		write_model_outputs =
		PRE cycle_state = st_WRITE_OUTPUTS
		THEN
		board_0_O1      :: uint8_t ||
		board_0_O2      :: uint8_t ||
		cycle_state     :: uint8_t
		END;
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name» =
		PRE cycle_state = st_WRITE_OUTPUTS
		THEN     
		board_0_O1      :: uint8_t ||
		board_0_O2      :: uint8_t ||
		cycle_state     :: uint8_t
		END;   		  
		«ENDFOR»
		«ENDFOR»
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name»_lv =
		PRE cycle_state = st_WRITE_OUTPUTS
		THEN     
		board_0_O1 :: uint8_t
		END;
		«ENDFOR»
		«ENDFOR»
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name»_av =
		PRE cycle_state = st_WRITE_OUTPUTS
		THEN     
		board_0_O2 :: uint8_t
		END;
		«ENDFOR»
		«ENDFOR»
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		«op.name»(l_lv,l_av) =
		PRE l_lv:BOOL & l_av:BOOL
		THEN
		o_«op.name»_lv:: uint8_t ||
		o_«op.name»_av:: uint8_t
		END;
		«ENDFOR»
		«ENDFOR»
		
		elapsed <-- since(timer) =
		PRE timer:uint32_t & elapsed:uint32_t
		THEN
			elapsed::uint32_t
		END;
		
		result <-- land(pp,qq) =
		PRE pp:BOOL & qq:BOOL & result:BOOL
		THEN
		    result::BOOL
		END;
		
		result <-- lor(pp,qq) = 
		PRE pp:BOOL & qq:BOOL & result:BOOL
		THEN
		 	result::BOOL
		END;
		
		result <-- lnot(pp) = 
		PRE pp:BOOL & result:BOOL
		THEN
		 	result::BOOL
		END;
		
		tock =
		BEGIN
		 	skip
		END
		
		OPERATIONS
		
		user_logic = 
		BEGIN
		    IF first_time = TRUE THEN 
		       cycle_timer <-- get_ms_tick; 
		       execute_model_cycle;
		       cycle_state:= st_READ_INPUTS;
		       first_time := FALSE
		
		    ELSE
		 	    VAR time_elapsed, cycle_duration IN 
		
		            time_elapsed:(time_elapsed:uint32_t);
		 	        cycle_duration:(cycle_duration:uint32_t);
		 		    time_elapsed <-- since(cycle_timer);
		 		    cycle_duration := mul_uint32(SimSMovement_cycleDef,cycle_unit);
		 		    
		 		    IF (cycle_duration <= time_elapsed) THEN
		 		        cycle_timer <-- get_ms_tick;«"\n"»
		 		        execute_model_cycle;«"\n"»
		 		        cycle_state:= st_READ_INPUTS;«"\n"»
		 		        tock
		 		    END
		 		END
		 	END
		END;
		
		SM_«getSimMachine(Logici).name» =
		BEGIN            
		IF SM_SimSMovement_state = INIT THEN
		   move(SimSMovement_lv,FALSE);
		   SM_SimSMovement_state:= EXEC_1
		ELSIF SM_SimSMovement_state = EXEC_1 THEN
		    VAR guard_1, guard_2
		    IN 
			    guard_1:(guard_1:BOOL);
		        guard_2:(guard_2:BOOL);
		                       
		        guard_1:= bool(i_obstacle = IO_ON);
		        guard_2:= bool(i_obstacle = IO_OFF);
		                       
		        IF (guard_1 = TRUE) THEN
		            var_MBC_1 <-- get_ms_tick;
		            move(FALSE,FALSE);
		            SM_SimSMovement_state:= EXEC_2
		        ELSIF (guard_2 = TRUE) THEN
		            SM_SimSMovement_state:= EXEC_1 
		        END
		     END                 
		ELSIF SM_SimSMovement_state= EXEC_2 THEN 
		       move(FALSE,SimSMovement_av);
		       SM_SimSMovement_state:= EXEC_3
		                         
		ELSIF SM_SimSMovement_state = EXEC_3 THEN 
		     VAR guard_1, guard_2, since_local
		     IN 
		         guard_1:(guard_1:BOOL);
		         guard_2:(guard_2:BOOL);
		         since_local:(since_local:uint32_t);
		                   
		         since_local <-- since(var_MBC_1);
		                    
		         guard_1 := bool(since_local < SimSMovement_Pi);         
		         guard_2 := bool(SimSMovement_Pi <= since_local);
		                   
		         IF (guard_1 = TRUE) THEN
		             SM_SimSMovement_state:= EXEC_3
		         ELSIF (guard_2 = TRUE) THEN
		             move(SimSMovement_lv,FALSE);
		             SM_SimSMovement_state:= EXEC_1  
		         END
		     END             
		END;
		    cycle_state := st_WRITE_OUTPUTS        
		END;
		
		execute_model_cycle =
		BEGIN
		read_model_inputs;
		SM_«getSimMachine(Logici).name»;
		write_model_outputs
		END;
		
		read_model_inputs =
		BEGIN
		cycle_state := st_STATE_MACHINE;
		«FOR iface : machine.inputContext.interfaces»
		«FOR ev : iface.events.indexed»read_i_«ev.value.name»«ENDFOR»
		«ENDFOR»
		END;
		
		«FOR iface : machine.inputContext.interfaces»
		«FOR ev : iface.events.indexed SEPARATOR " \n "»
		read_i_«ev.value.name» =
		BEGIN
		i_«ev.value.name» <-- get_board_0_I1
		END;
		«ENDFOR»
		«ENDFOR»
		
		write_model_outputs =
		BEGIN
		cycle_state:= st_TIME;
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name»
		«ENDFOR»
		«ENDFOR»
		END;
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name» =
		BEGIN     
			write_o_«op.name»_lv;
			write_o_«op.name»_av
		END;   		  
		«ENDFOR»
		«ENDFOR»
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name»_lv =
		BEGIN     
		board_0_O1 := o_«op.name»_lv
		END;
		«ENDFOR»
		«ENDFOR»
		
		«FOR iface : machine.outputContext.RInterfaces»
		«FOR op : iface.operations»
		write_o_«op.name»_av =
		BEGIN
		board_0_O2 := o_«op.name»_av
		END;
		«ENDFOR»
		«ENDFOR»
		
		move(l_lv,l_av) = 
		BEGIN
		IF l_lv = TRUE 
		THEN
		o_move_lv := IO_ON  
		ELSE    
		o_move_lv := IO_OFF
		END;
		IF l_av = TRUE
		THEN
		o_move_av := IO_ON
		ELSE
		o_move_av := IO_OFF
		END
		END;
		
		elapsed <-- since(timer) =
		BEGIN
		     elapsed:(elapsed:uint32_t);
		     VAR local_time IN 
		         local_time:(local_time:uint32_t);
		         local_time <-- get_ms_tick;
		        elapsed := sub_uint32(local_time, timer)
		     END
		END;
		
		result <-- land(pp,qq) =
		BEGIN
		    result := FALSE;
		    IF (pp = TRUE) THEN
		        IF (qq = TRUE) THEN
		            result := TRUE
		        END
		    END
		END;
		
		result <-- lor(pp,qq) =
		BEGIN
		    result := TRUE;
		    IF (pp = FALSE) THEN 
		        IF (qq = FALSE) THEN
		            result := FALSE
		        END
		    END
		END;
		
		result <-- lnot(pp) =
		BEGIN
		result := FALSE;
		    IF (pp = FALSE) THEN
		        result := TRUE
		    END
		END;
		
		tock =
		BEGIN
		    skip
		END;
		
		po <-- get_board_0_O1 =
		BEGIN
		   po := board_0_O1
		END;
		
		po <-- get_board_0_O2 =
		BEGIN
			po := board_0_O2
		END
		
		END
	'''
	}
	
	def CharSequence generateInitToFirstExecBlock(SimMachineDef machine) '''

		«val execTransition = machine.transitions.findFirst[t | t.trigger !== null]»
		
		«IF execTransition !== null»
		IF SM_«machine.name»_state = INIT THEN
		/* First EXEC: «execTransition.name» */
		«ENDIF»

	'''
		
	def CharSequence generateOperationCallsForBlock(
    SimMachineDef machine,
    Node startNode, 
    Iterable<Transition> blockTransitions
	) {
    val untilExec = 
        blockTransitions.takeWhile[t | t.trigger === null] + 
        blockTransitions.filter[t | t.trigger !== null].take(1)

    val guarded = untilExec.filter[t | t.condition !== null].toList
    val unguarded = untilExec.filter[t | t.condition === null].toList

    '''
    «generateEntryOperationCalls(startNode)»
    
    «IF !guarded.empty»
       
    «ELSE»
        «FOR t : unguarded»
            «IF t.action !== null»
                «extractOperationCalls(t.action)»
            «ENDIF»
            
            «generateEntryOperationCalls(t.target)»
        «ENDFOR»
        
        «IF !unguarded.empty»
            «val last = unguarded.last»
            
            «ENDIF»
        «ENDIF»
    '''
	}
	
	def CharSequence generateEntryOperationCalls(Node node) {
    	switch node {
        	State: 
            	node.actions
                	.filter(EntryAction)
                	.map[a | extractOperationCalls(a.action)]
                	.join("\n")
        	default:
            ""
    	}
	}
	
	def CharSequence extractOperationCalls(Statement stmt) '''
	«FOR call : stmt.eAllContents.toIterable.filter(SimCall)»
		«call.operation.name»
	«ENDFOR»
	'''
	
	def Iterable<OperationDef> collectOperationCalls(EObject obj) {
    	obj.eAllContents.filter(OperationDef).toList
	}
	
	def CharSequence translateOperationCall(SimCall call) '''
	«call.operation.name»(«FOR arg : call.args SEPARATOR ", "»«translateExpression(arg)»«ENDFOR»);
	'''
	
	def dispatch CharSequence translateExpression(Expression e) {
    	""
	}
	
	def dispatch CharSequence translateExpression(IntegerExp e) '''
		«e.value»
	'''
	
	def dispatch CharSequence translateExpression(BooleanExp e) '''
		«IF e.value == "true"»TRUE«ELSE»FALSE«ENDIF»
	'''
	
	def dispatch CharSequence translateExpression(RefExp e) {
		val target = e.ref
		    switch target {
		        Parameter: target.name
		        Variable: target.name
		        default: target.toString
		    }
	}
	
	def SimMachineDef getSimMachine(RCPackage pkg) {
    	pkg.machines.head as SimMachineDef
	}
	
	def CharSequence generateContextEvents(
	    Context context,
	    String prefix )'''
		«IF context !== null»
		  «FOR iface : context.interfaces»
		    «FOR ev : iface.events.indexed SEPARATOR ", " AFTER ", " »«prefix»«ev.value.name»«ENDFOR»
		  «ENDFOR»
		«ENDIF»
	'''
	
	def CharSequence generateInputEvents(SimMachineDef machine) '''
		«generateContextEvents(machine.inputContext, "i_")»
	'''
	
	def CharSequence generateOutputEvents(SimMachineDef machine) '''
		«IF machine.outputContext !== null»
		  «FOR iface : machine.outputContext.RInterfaces»
		    «FOR ev : iface.events.indexed»
		      o_«ev.value.name»_«ev.key + 1»
		    «ENDFOR»
		  «ENDFOR»
		«ENDIF»
	'''
	
	def generateUserCtxi(RCPackage UserCtxi) '''
		IMPLEMENTATION
		    user_ctx_i
		REFINES
		    user_ctx
		SEES
		  	    g_types
		VALUES
		INIT = 0;
		«val execCounti = countExecTriggers(UserCtxi)»
		«FOR i : 0 ..< execCounti»
		    EXEC_«i + 1» = «i + 1»;
		«ENDFOR»
		st_READ_INPUTS = 0;
		st_STATE_MACHINE = 1;
		st_WRITE_OUTPUTS = 2;
		st_TIME = 3;
		cycle_unit = 1000;
		«UserCtxi.machines.head.name»_cycleDef = «getCycleDefValue(UserCtxi)»;
		«val constants3 = getConstants(UserCtxi)»
		«FOR c : constants3 SEPARATOR "; "»
			«UserCtxi.machines.head.name»_«c.name» = «mapImpl(c.type)»
		«ENDFOR»
		END
	'''
	def static mapImpl(Type localValue) {
        if (localValue instanceof TypeRef) {
        	val decl = (localValue as TypeRef).ref

	        if (decl instanceof PrimitiveType) {
	            switch decl.name {
	                case "real" : return "//Set a number greater than zero"
	                case "int"  : return "//Set a number greater than zero"
	                case "nat"  : return "//Set a number greater than zero"
	                case "boolean" : return "TRUE"
	            }
	        }   
    	}
	}
	def int getCycleDefValue(RCPackage pkg) {
	    val machine = pkg.machines.head as SimMachineDef
	    val expr = machine.cycleDef
	
	    if (expr instanceof IntegerExp) {
	        return expr.value
	    }
	
	    if (expr instanceof Equals) {
	        val right = expr.right
	        if (right instanceof IntegerExp) {
	            return right.value
	        }
	    }
	
	    return 0
	}
					
	def generateUserCtx(RCPackage UserCtx) '''
		MACHINE
		    user_ctx
		SEES
		    g_types
		
		CONCRETE_CONSTANTS
				
		INIT,
		«val execCount = countExecTriggers(UserCtx)»
		«FOR i : 0 ..< execCount»
		    EXEC_«i + 1»,
		«ENDFOR»
		st_READ_INPUTS,
		st_STATE_MACHINE,
		st_WRITE_OUTPUTS,
		st_TIME,
		cycle_unit,
		«UserCtx.machines.head.name»_cycleDef,
		«val constants1 = getConstants(UserCtx)»
		«FOR c : constants1 SEPARATOR ", "»
				«UserCtx.machines.head.name»_«c.name»«"\n"»
		«ENDFOR»
		
		PROPERTIES
		INIT: uint8_t &
		«FOR i : 0 ..< execCount»
			EXEC_«i + 1»: uint8_t &
		«ENDFOR»
		st_READ_INPUTS: uint8_t &
		st_STATE_MACHINE: uint8_t &
		st_WRITE_OUTPUTS: uint8_t &
		st_TIME: uint8_t &
		cycle_unit:uint32_t &
		«UserCtx.machines.head.name»_cycleDef : uint32_t &
		«val constants2 = getConstants(UserCtx)»
		«FOR c : constants2 SEPARATOR " & "»
			«UserCtx.machines.head.name»_«c.name» :«mapType(c.type)»
		«ENDFOR»
		END
	'''
	
	def String mapType(Type t) {
	    if (t instanceof TypeRef) {
	        val decl = (t as TypeRef).ref
	        if (decl instanceof PrimitiveType) {
	            switch decl.name {
	                case "boolean": return "BOOL"
	                default: return "uint32_t"
	            }
	        }
	    }
    	return "uint32_t"
	}
    
    def int countExecTriggers(RCPackage model) {
	    model.eAllContents
	        .toIterable
	        .filter(ExecTrigger)
	        .size
	}
	
	def Iterable<Variable> getConstants(RCPackage model) {
    	model.eAllContents
        	 .toIterable
        	 .filter(Variable)
             .filter[v | v.eContainer instanceof VariableList && (v.eContainer as VariableList).modifier == VariableModifier::CONST]
	}
	    
}
