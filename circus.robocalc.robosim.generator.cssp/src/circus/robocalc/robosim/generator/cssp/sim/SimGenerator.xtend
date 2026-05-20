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

import circus.robocalc.robochart.And
import circus.robocalc.robochart.Assignable
import circus.robocalc.robochart.Assignment
import circus.robocalc.robochart.BooleanExp
import circus.robocalc.robochart.Clock
import circus.robocalc.robochart.ClockExp
import circus.robocalc.robochart.ClockReset
import circus.robocalc.robochart.ConnectionNode
import circus.robocalc.robochart.ControllerDef
import circus.robocalc.robochart.EntryAction
import circus.robocalc.robochart.Equals
import circus.robocalc.robochart.Expression
import circus.robocalc.robochart.Final
import circus.robocalc.robochart.GreaterOrEqual
import circus.robocalc.robochart.GreaterThan
import circus.robocalc.robochart.Initial
import circus.robocalc.robochart.IntegerExp
import circus.robocalc.robochart.Junction
import circus.robocalc.robochart.LessOrEqual
import circus.robocalc.robochart.LessThan
import circus.robocalc.robochart.Minus
import circus.robocalc.robochart.NamedExpression
import circus.robocalc.robochart.Node
import circus.robocalc.robochart.Not
import circus.robocalc.robochart.OperationSig
import circus.robocalc.robochart.ParExp
import circus.robocalc.robochart.Parameter
import circus.robocalc.robochart.Plus
import circus.robocalc.robochart.PrimitiveType
import circus.robocalc.robochart.RCPackage
import circus.robocalc.robochart.RefExp
import circus.robocalc.robochart.SeqStatement
import circus.robocalc.robochart.State
import circus.robocalc.robochart.StateMachineRef
import circus.robocalc.robochart.Statement
import circus.robocalc.robochart.Transition
import circus.robocalc.robochart.Type
import circus.robocalc.robochart.TypeRef
import circus.robocalc.robochart.VarRef
import circus.robocalc.robochart.VarSelection
import circus.robocalc.robochart.Variable
import circus.robocalc.robochart.VariableModifier
import circus.robocalc.robosim.ExecTrigger
import circus.robocalc.robosim.OutputCommunication
import circus.robocalc.robosim.SimCall
import circus.robocalc.robosim.SimMachineDef
import circus.robocalc.robosim.SimModule
import circus.robocalc.robosim.SimRefExp
import circus.robocalc.robosim.textual.generator.AbstractRoboSimGenerator
import java.util.ArrayList
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class SimGenerator extends AbstractRoboSimGenerator {

	override getID() {
		"ROBOSIM_PRISM_GENERATOR"
	}

	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		System.out.println("[RoboSim] Generating CSSP model for " + resource.URI.toString)

		//var diagnostic = Diagnostician.INSTANCE.validate(resource.getContents().get(0));

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
		val modules = collectAllSimModules(Logici) 
		val machines = collectAllSimMachines(Logici)
		val machine = getSimMachine(Logici)
		
		val allOutputNames = (machine.getOutputOperationParamNames
                           + machine.getOutputVariables.map[ "o_" + it.name ])
                           .toList
        //val outputs = machine.collectOutputEntries
                           
        //Valida se a quantidade de saída é compativel antes de gerar falha
        validateOutputCount(allOutputNames)
                           
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
		«generateStateVarDeclarations(machines)»
		cycle_timer,
		cycle_state,
		«generateConcreteVariables(machines, Logici)»
		
		INVARIANT 
		board_0_O1 : uint8_t &
		board_0_O2 : uint8_t &
		first_time: BOOL &
		«generateStateVarInvariant(machines)»
		cycle_timer: uint32_t &
		cycle_state: uint8_t &
		cycle_state: {st_READ_INPUTS, st_STATE_MACHINE, st_WRITE_OUTPUTS, st_TIME} &
		«generateInvariant(machines, Logici)»
		
		INITIALISATION
		    
		board_0_O1 := IO_OFF;
		board_0_O2 := IO_OFF;
		first_time:= TRUE;
		cycle_timer := 0;
		cycle_state := st_READ_INPUTS;
		«generateStateVarInitialisation(machines)»
		«generateInitialisation(machines, Logici)»
		
		LOCAL_OPERATIONS
		
		«generateExecuteModelCycleSpec(machines, Logici)»
		
		«generateStateMachineLocalSpecs(machines, Logici)»
		«generateReadModelInputs(machines, Logici)»
		
		«generateIndividualReadOperations(machines, Logici)»
		write_model_outputs =
		PRE cycle_state = st_WRITE_OUTPUTS
		THEN
		board_0_O1      :: uint8_t ||
		board_0_O2      :: uint8_t ||
		cycle_state     :: uint8_t
		END;
		
		«generateAggregateWriteLocalOperations(machine)»
		
		«generateLocalOperations(machines, Logici)»
		«generateAllOperationLocalSpecs(machine)»
		«generateSyncMachinesSpec(machines, Logici)»
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
		 		    «FOR mods : modules SEPARATOR "; \n"»cycle_duration := mul_uint32(«mods.name»_cycleDef,cycle_unit)«ENDFOR»«IF !modules.empty»;«ENDIF»
		 		    
		 		    IF (cycle_duration <= time_elapsed) THEN
		 		        cycle_timer <-- get_ms_tick;«"\n"»
		 		        execute_model_cycle;«"\n"»
		 		        cycle_state:= st_READ_INPUTS;«"\n"»
		 		        tock
		 		    END
		 		END
		 	END
		END;
		
		«generateAllStateMachineOperations(machines, Logici)»
		execute_model_cycle =
		BEGIN
		read_model_inputs;
		«FOR stm : machines SEPARATOR ";\n"»SM_«stm.name»«ENDFOR»;
		«IF machines.size > 1»controller_«getControllerName(Logici)»;«ENDIF»
		write_model_outputs
		END;
		
		«generateOperationReadModelInputs(machine)»
		
		«generateIndividualReadImplementations(machine)»
		«generateWriteModelOutputs(machines, Logici)»
		
		«generateAggregateWriteOperations(machine)»
		
		«generateOperations(machines, Logici)»
		
		«generateAllOperationImplementations(machine)»
		«generateSyncMachinesImpl(machines, Logici)»
		
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
	
	// =========================================================
	// Gera a implementação da operação sync_machines na
	// cláusula OPERATIONS.
	//
	// Propaga o valor das variáveis da máquina fonte para
	// a máquina alvo de cada conexão interna do controller.
	//
	// connection stm_ref0 on arrived to stm_ref1 on arrived
	//   → Delivery_arrived := Movement_arrived
	//
	// Regra: só gerada quando há 2 ou mais máquinas no modelo.
	//        Com uma única máquina, retorna vazio.
	// =========================================================
	def generateSyncMachinesImpl(List<SimMachineDef> machines, RCPackage pkg) {
	
	    // Apenas para modelos com múltiplas máquinas
	    if (machines.size <= 1)
	        return ''
	
	    val connEvents = collectConnectedEvents(pkg)
	
	    // Nenhuma conexão interna entre máquinas
	    if (connEvents.empty)
	        return ''
	        
		val ctrlName   = getControllerName(pkg)
	    '''
	    controller_«ctrlName» =
	    BEGIN
	        «FOR conn : connEvents SEPARATOR ";"»
	            «conn.targetVarName» := «conn.sourceVarName»
	        «ENDFOR»
	    END;
	    '''
	}
	
	// Recupera o nome do primeiro ControllerDef do modelo
	def String getControllerName(RCPackage pkg) {
	    val ctrl = pkg.controllers.filter(ControllerDef).head
	    if (ctrl === null) return "controller"
	    return ctrl.name
	}
	
	// =========================================================
	// Gera a operação sync_machines na cláusula LOCAL_OPERATIONS.
	// Reúne as variáveis compartilhadas entre máquinas via
	// connections internas do controller.
	//
	// Regra: só gerada quando há 2 ou mais máquinas no modelo.
	//        Com uma única máquina, retorna vazio.
	//
	// PoliteDelivery:
	//   connection stm_ref0 on arrived to stm_ref1 on arrived
	//     Movement_arrived :: uint8_t ||
	//     Delivery_arrived :: uint8_t
	// =========================================================
	def generateSyncMachinesSpec(List<SimMachineDef> machines, RCPackage pkg) {
	
	    // Apenas para modelos com múltiplas máquinas
	    if (machines.size <= 1)
	        return ''
	
	    val connEvents = collectConnectedEvents(pkg)
	
	    // Nenhuma conexão interna entre máquinas
	    if (connEvents.empty)
	        return ''
	
	    // Coleta todos os pares de variáveis compartilhadas
	    val ctrlName   = getControllerName(pkg)
	    val sharedVars = connEvents.flatMap[ #[
	        sourceVarName + " :: uint8_t",
	        targetVarName + " :: uint8_t"
	    ]].toList
	
	    '''
	    controller_«ctrlName» =
	    PRE cycle_state = st_STATE_MACHINE
	    THEN
	        «FOR v : sharedVars SEPARATOR " ||"»
	            «v»
	        «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Constrói o mapa de substituição de nomes de eventos
	// conectados para uma máquina específica.
	//
	// Para Movement (source de arrived):
	//   "arrived" → "Movement_arrived"
	//
	// Para Delivery (target de arrived):
	//   "arrived" → "Delivery_arrived"
	// =========================================================
	def buildConnectedEventMap(SimMachineDef stm,
	                            List<ConnectedEventEntry> connEvents) {
	    val map = new LinkedHashMap<String, String>
	
	    // Eventos onde esta máquina é a FONTE (output context)
	    connEvents.filter[ sourceMachineName == stm.name ]
	              .forEach[ map.put(eventName, sourceVarName) ]
	
	    // Eventos onde esta máquina é o ALVO (input context)
	    connEvents.filter[ targetMachineName == stm.name ]
	              .forEach[ map.put(eventName, targetVarName) ]
	
	    return map
	}
	
	// =========================================================
	// Gera a assinatura LOCAL_OPERATIONS de execute_model_cycle.
	// Abrange variáveis de TODAS as máquinas:
	//   - SM_<nome>_state de cada máquina
	//   - clocks de cada máquina
	//   - inputs de cada máquina (filtrados por connEvents)
	//   - outputs de cada máquina (filtrados por connEvents)
	//   - eventos conectados entre máquinas
	//   - variáveis fixas: first_time, cycle_timer, cycle_state
	// =========================================================
	def generateExecuteModelCycleSpec(List<SimMachineDef> machines,
	                                   RCPackage pkg) {
	
	    val connEvents     = collectConnectedEvents(pkg)
	    val connEventNames = connEvents.map[ eventName ].toSet
	
	    // Agrega clocks de todas as máquinas com índice por máquina
	    val allClocks = machines.flatMap[ stm |
	        stm.clocks.indexed.map[ pair |
	            "var_" + pair.value.name + "_" + (pair.key + 1) + " :: uint32_t"
	        ]
	    ].toList
	
	    // Agrega inputs de todas as máquinas via collectInputEntries
	    val allInputs = machines
                    .flatMap[ collectInputEntries ]
                    .filter[ !connEventNames.contains(
                        bVarName.replace("i_", "")) ]
                    .map[ bVarName + " :: uint8_t" ]
                    .toList
	
	    // Agrega outputs de todas as máquinas, excluindo eventos conectados
	    val allOutputs = machines
	                        .flatMap[ collectOutputEntries ]
	                        .filter[ !connEventNames.contains(
	                            bVarName.replace("o_", "")) ]
	                        .map[ bVarName + " :: uint8_t" ]
	                        .toList
	
	    // Eventos conectados — ambos os lados (source e target)
	    val connVars = connEvents
	                        .flatMap[ #[
	                            sourceVarName + " :: uint8_t",
	                            targetVarName + " :: uint8_t"
	                        ]]
	                        .toList
	
	    // Monta lista completa de linhas com tipo
	    val allLines = new ArrayList<String>
	    machines.forEach[ stm |
	        allLines.add("SM_" + stm.name + "_state :: uint32_t")
	    ]
	    allLines.addAll(allClocks)
	    allLines.addAll(allInputs)
	    allLines.addAll(allOutputs)
	    allLines.addAll(connVars)
	
	    '''
	    execute_model_cycle =
	    PRE cycle_state = st_TIME
	    THEN
	    first_time :: BOOL ||
	    cycle_timer :: uint32_t ||
	    cycle_state :: uint32_t«IF !allLines.empty» ||«ENDIF»
	    «FOR line : allLines SEPARATOR " ||"»
	         «line»
	    «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Gera a assinatura LOCAL_OPERATIONS para cada máquina.
	// Itera sobre todas as máquinas e produz uma especificação
	// SM_<nome> por máquina.
	def generateStateMachineLocalSpecs(List<SimMachineDef> machines, RCPackage pkg) {
	    val connEvents     = collectConnectedEvents(pkg)
	    val connEventNames = connEvents.map[ eventName ].toSet
	
	    '''
	    «FOR stm : machines»
	    «generateSingleStateMachineLocalSpec(stm, connEvents, connEventNames)»
	    «ENDFOR»
	    '''
	}
	
	def generateSingleStateMachineLocalSpec(SimMachineDef stm,
	                                         List<ConnectedEventEntry> connEvents,
	                                         Set<String> connEventNames) {
	
	    // Vars locais da máquina (sem constantes, com clocks)
	    val machineVars = stm.collectMachineVarEntries
	
	    // Outputs normais — exclui eventos que têm nome conectado
	    val filteredOutputs = stm.collectOutputEntries
	                             .filter[ !connEventNames.contains(
	                                 bVarName.replace("o_", "")) ]
	                             .toList
	
	    // Eventos conectados onde esta máquina é a fonte (source)
	    val sourceEvents = connEvents.filter[ sourceMachineName == stm.name ].toList
	
	    // Eventos conectados onde esta máquina é o alvo (target)
	    val targetEvents = connEvents.filter[ targetMachineName == stm.name ].toList
	
	    '''
	    SM_«stm.name» =
	    PRE cycle_state = st_STATE_MACHINE
	    THEN
	    cycle_state :: uint32_t«IF !machineVars.empty || !filteredOutputs.empty || !sourceEvents.empty || !targetEvents.empty» ||«ENDIF»
	    SM_«stm.name»_state :: uint32_t«IF !machineVars.empty || !filteredOutputs.empty || !sourceEvents.empty || !targetEvents.empty» ||«ENDIF»
	    «FOR v : machineVars SEPARATOR " ||"»«v.bVarName» :: «v.bType»«ENDFOR»«IF !machineVars.empty && (!filteredOutputs.empty || !sourceEvents.empty || !targetEvents.empty)» ||«ENDIF»
	    «FOR e : sourceEvents SEPARATOR " ||"»«e.sourceVarName» :: uint8_t«ENDFOR»«IF !sourceEvents.empty && (!filteredOutputs.empty || !targetEvents.empty)» ||«ENDIF»
	    «FOR e : targetEvents SEPARATOR " ||"»«e.targetVarName» :: uint8_t«ENDFOR»«IF !targetEvents.empty && !filteredOutputs.empty» ||«ENDIF»
	    «FOR o : filteredOutputs SEPARATOR " ||"»«o.bVarName» :: uint8_t«ENDFOR»
	    END;
	    «"\n"»
	    '''
	}
	
	
	// =========================================================
	// Gera a declaração SM_<nome>_state para cada máquina
	// na cláusula CONCRETE_VARIABLES
	// =========================================================
	def generateStateVarDeclarations(List<SimMachineDef> machines) '''
	    «FOR stm : machines »
	        SM_«stm.name»_state,
	    «ENDFOR»
	'''
	
	// =========================================================
	// Gera a tipagem SM_<nome>_state para cada máquina
	// na cláusula INVARIANT
	// =========================================================
	def generateStateVarInvariant(List<SimMachineDef> machines) '''
	    «FOR stm : machines»
	        «val execCount = countExecTriggersForMachine(stm)»
	        SM_«stm.name»_state : uint32_t &
	        SM_«stm.name»_state : {INIT, FINAL, «FOR i : 0 ..< execCount SEPARATOR ", "»EXEC_«i + 1»«ENDFOR»} &
	    «ENDFOR»
	'''
	
	/*// =========================================================
	// Gera na especifição Execute Model Cycle
	// as variaveis de controle de fluxo das
	// máquinas de estados
	def generateStateVarInstantiate(List<SimMachineDef> machines) '''
	    «FOR stm : machines»
	        SM_«stm.name»_state :: uint32_t ||
	    «ENDFOR»
	''' */
	
	// =========================================================
	// Gera a inicialização SM_<nome>_state := INIT para cada máquina
	// na cláusula INITIALISATION
	// =========================================================
	def generateStateVarInitialisation(List<SimMachineDef> machines) '''
	    «FOR stm : machines »
	        SM_«stm.name»_state := INIT;
	    «ENDFOR»
	'''
	
	// =========================================================
	// Conta os ExecTriggers de uma única SimMachineDef.
	// Necessário para gerar o conjunto correto de EXEC_N
	// para cada máquina individualmente.
	// =========================================================
	def int countExecTriggersForMachine(SimMachineDef stm) {
	    stm.eAllContents
	       .toIterable
	       .filter(ExecTrigger)
	       .size
	}
	
	// =========================================================
	// Coleta eventos conectados entre máquinas via Connection
	// no Controller, resolvendo as referências para os nomes
	// reais das SimMachineDef.
	//
	// connection stm_ref0 on arrived to stm_ref1 on arrived
	//   stm_ref0 -> resolve -> Movement
	//   stm_ref1 -> resolve -> Delivery
	//   -> ConnectedEventEntry("Movement", "Delivery", "arrived")

	def collectConnectedEvents(RCPackage pkg) {
	    val result = new ArrayList<ConnectedEventEntry>

	    // usa pkg.controllers (nível do pacote)
	    // em vez de pkg.modules -> nodes -> filter(ControllerDef)
	    pkg.controllers
	       .filter(ControllerDef)
	       .forEach[ ctrl |
	           ctrl.connections.forEach[ conn |
	
	               val fromNode = conn.from
	               val toNode   = conn.to
	
	               val fromMachine = resolveMachineName(fromNode)
	               val toMachine   = resolveMachineName(toNode)
	
	               if (fromMachine !== null && toMachine !== null) {
	                   result.add(new ConnectedEventEntry(
	                       fromMachine,
	                       toMachine,
	                       conn.efrom.name
	                   ))
	               }
	           ]
	       ]
	
	    return result
	}

	// Resolve o nome da máquina a partir de um ConnectionNode.
	// Retorna null se o nó não for uma máquina (ex: platform ou controller).
	def String resolveMachineName(ConnectionNode node) {
	    switch node {
	        SimMachineDef:
	            node.name
	        StateMachineRef:
	            if (node.ref instanceof SimMachineDef)
	                (node.ref as SimMachineDef).name
	            else null
	        default: null
	    }
	}
	
	// =========================================================
	// Coleta todas as SimMachineDef do modelo, cobrindo
	// três origens possíveis:
	//
	// ORIGEM 1: máquinas definidas diretamente em controllers
	//   controller CPD { stm Movement { ... } }
	//
	// ORIGEM 2: referências a máquinas em controllers
	//   controller CPD { sref stm_ref0 = Movement }
	//   → resolve para a SimMachineDef referenciada
	//
	// ORIGEM 3: máquinas definidas no nível do pacote
	//   stm Movement { ... }  (fora de qualquer controller)
	// =========================================================
	def collectAllSimMachines(RCPackage pkg) {
	    val machines = new ArrayList<SimMachineDef>
	
	    // Possivel origem dentro de controllers nos modulos
	    pkg.modules
	       .flatMap[ nodes ]
	       .filter(ControllerDef)
	       .forEach[ ctrl |
	           ctrl.machines.forEach[ stm |
	               switch stm {
	                   // Definição direta
	                   SimMachineDef:
	                       machines.add(stm)
	
	                   // Referência → resolve para a definição real
	                   StateMachineRef:
	                       if (stm.ref instanceof SimMachineDef)
	                           machines.add(stm.ref as SimMachineDef)
	               }
	           ]
	       ]
	
	    // Outra origem das máquinas no nível do pacote (sem controller)
	    pkg.machines
	       .filter(SimMachineDef)
	       .forEach[ machines.add(it) ]
	
	    // Remove a mesma máquina referenciada por mais de um controller
	    return machines.toSet.toList
	}
	
	// =========================================================
	// Coleta os módulos roboticos do modelo e produz uma lista
	def collectAllSimModules(RCPackage pkg) {
	    val modules = new ArrayList<SimModule>
	
	    // Módulos declarados diretamente no pacote
	    pkg.modules
	       .filter(SimModule)
	       .forEach[ modules.add(it) ]
	
	    return modules.toSet.toList
	}
	
	// =========================================================
	// CONCRETE_VARIABLES
	// Apenas os nomes das variáveis
	// =========================================================
	def generateConcreteVariables(List<SimMachineDef> machines, RCPackage pkg) {
	    val allVars      = machines.flatMap[ collectMachineVarEntries ].toList
	    val allOutputs   = machines.flatMap[ collectOutputEntries     ].toList
	    val allInputs    = machines.flatMap[ collectInputEntries      ].toList
	    val connEvents   = collectConnectedEvents(pkg)
	    
	    // Coleta os nomes dos eventos conectados para excluir
	    // o_ e i_ correspondentes (evita valores duplicados)
	    val connEventNames = connEvents.map[ eventName ].toSet
	
	    // Filtra outputs e inputs que já estão cobertos pelos ConnectedEvents
	    val filteredOutputs = allOutputs.filter[ !connEventNames.contains(it.bVarName.replace("o_", "")) ].toList
	    val filteredInputs  = allInputs.filter[  !connEventNames.contains(it.bVarName.replace("i_", "")) ].toList
	    
	'''    
	«FOR entry : allVars SEPARATOR ", \n"»
		«entry.bVarName»«ENDFOR»«IF !allVars.empty»,«ENDIF»
	«FOR entry : filteredOutputs SEPARATOR ", \n"»
        «entry.bVarName»«ENDFOR»«IF !filteredOutputs.empty && (!filteredInputs.empty || !connEvents.empty)»,«ENDIF»
	«FOR entry : filteredInputs SEPARATOR ", \n"»
        «entry.bVarName»«ENDFOR»«IF !filteredInputs.empty && !connEvents.empty»,«ENDIF»
	«FOR entry : connEvents SEPARATOR ","»
        «entry.sourceVarName»,
        «entry.targetVarName»
    «ENDFOR»
	'''
	}
	
	// =========================================================
	// INVARIANT
	// Tipagem de cada variável: nome : tipo
	// =========================================================
	def generateInvariant (List<SimMachineDef> machines, RCPackage pkg) {
	    val allVars      = machines.flatMap[ collectMachineVarEntries ].toList
    	val allOutputs   = machines.flatMap[ collectOutputEntries     ].toList
    	val allInputs    = machines.flatMap[ collectInputEntries      ].toList
    	val connEvents   = collectConnectedEvents(pkg)

	    val connEventNames = connEvents.map[ eventName ].toSet

	    val filteredOutputs = allOutputs.filter[ !connEventNames.contains(it.bVarName.replace("o_", "")) ].toList
	    val filteredInputs  = allInputs.filter[  !connEventNames.contains(it.bVarName.replace("i_", "")) ].toList
	'''    
	«FOR entry : allVars SEPARATOR " &\n"»
	     «entry.bVarName» : «entry.bType»«ENDFOR»«IF !allVars.empty» &«ENDIF»
	«FOR entry : filteredOutputs SEPARATOR " &\n"»
	     «entry.bVarName» : uint8_t«ENDFOR»«IF !filteredOutputs.empty && (!filteredInputs.empty || !connEvents.empty)» &«ENDIF»
	«FOR entry : filteredInputs SEPARATOR " &\n"»
	     «entry.bVarName» : uint8_t«ENDFOR»«IF !filteredInputs.empty && !connEvents.empty» &«ENDIF»
	«FOR entry : connEvents SEPARATOR " &\n"»
	     «entry.sourceVarName» : uint8_t &
	     «entry.targetVarName» : uint8_t
	«ENDFOR»
	'''
	}
	
	
	// INITIALIZATION
	// var x : nat = 0  -> Movement_x := 0
	// output/input     -> o_move_lv :: uint8_t
	// =========================================================
	def generateInitialisation(List<SimMachineDef> machines, RCPackage pkg) {
	    val allVars      = machines.flatMap[ collectMachineVarEntries ].toList
    	val allOutputs   = machines.flatMap[ collectOutputEntries     ].toList
    	val allInputs    = machines.flatMap[ collectInputEntries      ].toList
    	val connEvents   = collectConnectedEvents(pkg)

	   	val connEventNames = connEvents.map[ eventName ].toSet
	
	    val filteredOutputs = allOutputs.filter[ !connEventNames.contains(it.bVarName.replace("o_", "")) ].toList
	    val filteredInputs  = allInputs.filter[  !connEventNames.contains(it.bVarName.replace("i_", "")) ].toList
	'''
	«FOR entry : allVars SEPARATOR "; \n"»«IF entry.isDeterministic»«entry.bVarName» := «entry.initialValue»«ELSE»«entry.bVarName» :: «entry.bType»«ENDIF»«ENDFOR»«IF !allVars.empty»;«ENDIF»
	«FOR entry : filteredOutputs SEPARATOR "; \n"»«entry.bVarName» := IO_OFF«ENDFOR»«IF !filteredOutputs.empty && (!filteredInputs.empty || !connEvents.empty)»;«ENDIF»
	«FOR entry : filteredInputs SEPARATOR "; \n"»«IF entry.kind == InputKind.EVENT_VALUE»«entry.bVarName» := IO_OFF
	    «ELSE»
	    «entry.bVarName» := IO_OFF«ENDIF»«ENDFOR»«IF !filteredInputs.empty && !connEvents.empty»;«ENDIF»
	«FOR entry : connEvents SEPARATOR ";"»
		«entry.sourceVarName» := IO_OFF;
		«entry.targetVarName» := IO_OFF
	«ENDFOR»
	'''
	}
	
	// =========================================================
	// Coleta todas as variáveis da máquina de estados como
	// MachineVarEntry, cobrindo:
	//   1. Variáveis locais (var)
	//   2. Constantes (const)
	//   3. Clocks
	// =========================================================
	def collectMachineVarEntries(SimMachineDef stm) {
	    val entries = new ArrayList<MachineVarEntry>
	
		// FONTE 1: apenas variáveis (VAR) — constantes ignoradas
	    for (vl : stm.variableList.filter[ modifier == VariableModifier.VAR ]) {
	        for (v : vl.vars) {
	            val bName   = stm.name + "_" + v.name
	            val bType   = translateVarType(v.type)
	            val initVal = translateInitialValue(v.initial)
	
	            if (initVal !== null) {
	                // Variável com valor inicial: inicialização determinística
	                entries.add(new MachineVarEntry(bName, bType, initVal, true))
	                
	            } else if (bType == "BOOL") {
				    // Booleano sem valor inicial → default FALSE
				    entries.add(new MachineVarEntry(bName, bType, "FALSE", true))
	            
	            } else {
	                // Variável sem valor inicial: inicialização não determinística
	                entries.add(new MachineVarEntry(bName, bType, null, false))
	            }
	        }
	    }
	
	    // FONTE 2: clocks -> sempre uint32_t, inicial = 0
	    for (clock : stm.clocks) {
	        val bName = getClockBName(clock, stm)
	        entries.add(new MachineVarEntry(bName, "uint32_t", "0", true))
	    }
	
	    return entries
	}
		
	// =========================================================
	// Traduz o tipo RoboSim para o tipo B/CSSP correspondente
	// =========================================================
	def String translateVarType(Type type) {
	    if (type instanceof TypeRef) {
	        val decl = (type as TypeRef).ref
	        if (decl instanceof PrimitiveType) {
	            switch decl.name {
	                case "boolean": return "BOOL"
	                case "nat":     return "uint32_t"
	                case "int":     return "uint32_t"
	                case "real":    return "uint32_t"
	            }
	        }
	    }
    	return "uint32_t"
	}

	// Traduz o valor inicial de uma variável
	def String translateInitialValue(Expression expr) {
	    if (expr === null) return null
	    switch expr {
	        BooleanExp: if (expr.value == "true") "TRUE" else "FALSE"
	        IntegerExp: expr.value.toString
	        default:    null
	    }
	}
	
	
	// =========================================================
	// Coleta todos os predicados necessários para uma lista de
	// branches, retornando:
	//   key   -> List<PredicateEntry> (predicados extraídos)
	//   value -> List<String> (condições reescritas com predicados)
	// =========================================================
	def GuardContext collectPredicatesAndConditions(
			        List<Transition> branches,
			        SimMachineDef stm,
			        boolean needsClock,
			        Map<String, String> connEventMap) {
	
	    val predicates       = new ArrayList<PredicateEntry>
    	val subCondBoolExprs = new ArrayList<String>
    	val subCondNeedsLnot = new ArrayList<Boolean>
	
	    for (branch : branches) {
        val subConds = flattenAnd(branch.condition)
        for (subCond : subConds) {

            // Not complexo: extrai o interior e sinaliza lnot
            // not(MOVINGTIME <= X) → inner = "MOVINGTIME <= predicate_1"
            //                        needsLnot = true
            if (subCond instanceof Not &&
                !((subCond as Not).exp instanceof SimRefExp)) {

                val innerExpr = extractPredicates(
                    (subCond as Not).exp, stm, predicates, needsClock, connEventMap)
                subCondBoolExprs.add(innerExpr)
                subCondNeedsLnot.add(true)

            } else {
                // Normal (incluindo Not simples: not $obstacle → IO_OFF)
                val rewritten = extractPredicates(
                    subCond, stm, predicates, needsClock, connEventMap)
                subCondBoolExprs.add(rewritten)
                subCondNeedsLnot.add(false)
            }
        }
    }

    	return new GuardContext(predicates, subCondBoolExprs, subCondNeedsLnot)
	}
	
	// =========================================================
	// Analisa uma condição e extrai os operandos compostos
	// como PredicateEntry, retornando a condição reescrita.
	//
	// sub_uint32(A,B) <= X  ->  predicate_N := sub_uint32(A,B)
	//                           bool(predicate_N <= X)
	//   Adicionei tratamento de Not com três casos:
	//   Not(SimRefExp) -> predicate direto com condição negada
	//   Not(complex)   -> lnot entry
	//   outros         -> comportamento anterior
	// =========================================================
	def String extractPredicates(Expression condition,
	                      		 SimMachineDef stm,
	                      		 List<PredicateEntry> predicates,
	                      		 boolean usesSinceLocal,
								 Map<String, String> connEventMap){
	    switch condition {
	
	        LessThan: {
	            val left  = resolveOperandWithPredicate(condition.left, stm, predicates, usesSinceLocal)
            	val right = resolveOperandWithPredicate(condition.right, stm, predicates, usesSinceLocal)
            	left + " < " + right
	        }
	
	        GreaterOrEqual: {
	            // B0: reescreve >= como <=  com operandos trocados
	            val left  = resolveOperandWithPredicate(condition.left, stm, predicates, usesSinceLocal)
            	val right = resolveOperandWithPredicate(condition.right, stm, predicates, usesSinceLocal)
            	right + " <= " + left
	        }
			
			// Menor ou igual com extração de predicados aritméticos
	        // MOVINGTIME <= (TravelTime - StopTime)
	        //  predicate_1 := sub_uint32(TravelTime, StopTime)
	        //  Movement_MOVINGTIME <= predicate_1
	        LessOrEqual: {
	            val left  = resolveOperandWithPredicate(condition.left, stm, predicates, usesSinceLocal)
	            val right = resolveOperandWithPredicate(condition.right, stm, predicates, usesSinceLocal)
	            left + " <= " + right
	        }
	
	        // Maior que com extração de predicados aritméticos
	        GreaterThan: {
	            val left  = resolveOperandWithPredicate(condition.left, stm, predicates, usesSinceLocal)
	            val right = resolveOperandWithPredicate(condition.right, stm, predicates, usesSinceLocal)
	            right + " < " + left
	        }
			
	        // Condições simples: não precisam de predicado
	        SimRefExp:{
	           val eventName = condition.element.name
	           val bName     = connEventMap.getOrDefault(eventName, "i_" + eventName)
	           bName + " = IO_ON"
			}
			
	        Not:
	            if (condition.exp instanceof SimRefExp) {
	                val eventName = (condition.exp as SimRefExp).element.name
	                val bName     = connEventMap.getOrDefault(eventName, "i_" + eventName)
	                bName + " = IO_OFF"
            	} else
                	extractPredicates(condition.exp, stm, predicates, usesSinceLocal, connEventMap)
	
	        ParExp:
	            extractPredicates(condition.exp, stm, predicates, usesSinceLocal, connEventMap)
			
			// Referência a variável booleana: obst -> "SimSMovement_obst = TRUE"
			RefExp:
		    	stm.name + "_" + resolveRefName(condition.ref) + " = TRUE"
	        
	        default:
	            translateCondition(condition, stm, usesSinceLocal, connEventMap)
	    }
	}
	
	// Versão original chama o novo método com mapa vazio
	def String extractPredicates(Expression condition,
	                              SimMachineDef stm,
	                              List<PredicateEntry> predicates,
	                              boolean usesSinceLocal) {
	    extractPredicates(condition, stm, predicates, usesSinceLocal, #{})
	}
	
	// =========================================================
	// Resolve um operando: se for composto, cria um PredicateEntry
	// e retorna o nome do predicado; se simples, traduz diretamente.
	// =========================================================
	def String resolveOperandWithPredicate(Expression operand,
	                                        SimMachineDef stm,
	                                        List<PredicateEntry> predicates,
	                                        boolean usesSinceLocal) {
	    if (isCompoundOperand(operand)) {
	        // Verifica se já foi extraído (evita duplicatas)
	        val translated = translateOperand(operand, stm)
	        val existing   = predicates.findFirst[ expression == translated ]
	
	        if (existing !== null)
	            return existing.name
	
	        // Cria novo predicado
	        val predName = "predicate_" + (predicates.size + 1)
	        val predType = inferPredicateType(operand)
	        predicates.add(new PredicateEntry(predName, translated, predType))
	        return predName
	    }
	
	    // Operando simples: usa since_local para clock, nome direto para outros
	    return translateOperand(operand, stm)
	}
	
	// Infere o tipo B do predicado conforme o operando
	def String inferPredicateType(Expression expr) {
	    switch expr {
	        Plus:  "uint32_t"
	        Minus: "uint32_t"
	        default: "uint32_t"
	    }
	}
	
	// =========================================================
	// Verifica se um operando é composto (não é termo simples B0)
	// Termos simples: RefExp, ClockExp, IntegerExp, BooleanExp
	// Compostos: Plus, Minus, ParExp com aritmética interna
	// =========================================================
	def boolean isCompoundOperand(Expression expr) {
	    switch expr {
	        Plus:    true
	        Minus:   true
	        ParExp:  isCompoundOperand(expr.exp)
	        default: false
	    }
	}
	
	// =========================================================
	// Gera um bloco IF-ELSIF completo para uma junção aninhada.
	// O bloco VAR...END cria escopo próprio: guard_1, guard_2...
	// internos não conflitam com os do bloco pai.
	// =========================================================
	def String generateNestedJunctionBlock(
	    Junction junction,
	    SimMachineDef stm,
	    LinkedHashMap<State, Integer> execMap,
	    Map<String, String> connEventMap) {
	
	    val branches   = stm.transitions.filter[ source == junction ].toList
	    val needsClock = branches.exists[ t | conditionUsesClock(t.condition) ]
	    val clockVar   = if (needsClock) findClockVarName(branches, stm) else ""
	    val guardCtx   = collectPredicatesAndConditions(branches, stm, needsClock, connEventMap)
	    val infos      = buildBranchGuardInfos(branches, stm, needsClock, guardCtx)
	
	    // Reutiliza generateGuardBlock — o -1 é ignorado (execNum não aparece no template do bloco)
	    generateGuardBlock(stm, -1, branches, infos, needsClock, clockVar,
	        guardCtx, [b, s, m | collectBranchPath(b, s, m, connEventMap)], execMap)
	        .toString
	}
	
	// =========================================================
	// Método auxiliar compartilhado que gera o corpo completo
	// de guards + land + IF para qualquer lista de branches
	def generateGuardBlock(SimMachineDef stm,
                       int execNum,
                       List<Transition> branches,
                       List<BranchGuardInfo> infos,
                       boolean needsClock,
                       String clockVar,
                       GuardContext guardCtx,
                       (Transition, SimMachineDef, LinkedHashMap<State,Integer>)=> Pair<List<String>, String> collectAction,
                       LinkedHashMap<State, Integer> execMap) {
	
	 val predicates      = guardCtx.predicates
     val landInfos       = infos.filter[ needsLand ].toList
     val totalSlots      = guardCtx.totalGuardSlots
     val guardAssignments = guardCtx.computeGuardAssignments()
	
    '''
    VAR «FOR i : 1..totalSlots SEPARATOR ", "»guard_«i»«ENDFOR»«IF !landInfos.empty»,
    «FOR info : landInfos SEPARATOR ", "»«info.ifGuardName»«ENDFOR»«ENDIF»«IF !predicates.empty»,
    «FOR p : predicates SEPARATOR ", "»«p.name»«ENDFOR»«ENDIF»«IF needsClock»,
    since_local«ENDIF»
    IN
    «FOR i : 1..totalSlots»
    guard_«i»:(guard_«i»:BOOL);
    «ENDFOR»
    «FOR info : landInfos»
    «info.ifGuardName»:(«info.ifGuardName»:BOOL);
    «ENDFOR»
    «FOR p : predicates»
    «p.name»:(«p.name»:«p.bType»);
    «ENDFOR»
    «IF needsClock»since_local:(since_local:uint32_t);
    since_local <-- since(«clockVar»);
    «ENDIF»
    «FOR p : predicates»
        «p.name» := «p.expression»;
    «ENDFOR»
    «FOR assignment : guardAssignments»
        «assignment»
    «ENDFOR»
    «generateLandCalls(infos)»
    «FOR i : 0..<branches.size»
        «val info         = infos.get(i)»
        «val branchResult = collectAction.apply(branches.get(i), stm, execMap)»
        «IF i == 0»IF«ELSE»ELSIF«ENDIF» («info.ifGuardName» = TRUE) THEN
        «FOR x : 0..<branchResult.key.size»
            «val a       = branchResult.key.get(x)»
            «val isLast  = (x == branchResult.key.size - 1)»
            «a»«IF !isLast || branchResult.value !== null»;«ENDIF»
        «ENDFOR»
        «IF branchResult.value !== null»
        SM_«stm.name»_state:= «branchResult.value»
        «ENDIF»
    «ENDFOR»
    END
    END
    '''
	}
	
	// =========================================================
	// Gera as chamadas land() para branches com AND.
	// land() é encadeado para mais de dois operandos:
	//
	// [guard_1, guard_2] -> guard_result_1 <-- land(guard_1, guard_2)
	// [guard_1, guard_2, guard_3] -> land_tmp        <-- land(guard_1, guard_2);
	//                                 guard_result_1  <-- land(land_tmp, guard_3)
	
	def generateLandCalls(List<BranchGuardInfo> infos) 
	'''
	«FOR info : infos.filter[ needsLand ]»
	     «IF info.atomicGuardNames.size == 2»
	         «info.ifGuardName» <-- land(«info.atomicGuardNames.get(0)», «info.atomicGuardNames.get(1)»);
	     «ELSE»
	         «var tmpResult = info.atomicGuardNames.get(0)»
	         «FOR idx : 1..<info.atomicGuardNames.size»
	              «val nextTmp = if (idx == info.atomicGuardNames.size - 1)
	                                  info.ifGuardName
	                             else
	                                  "predicate_" + idx»
	              «nextTmp» <-- land(«tmpResult», «info.atomicGuardNames.get(idx)»);
	              «{ tmpResult = nextTmp; "" }»
	         «ENDFOR»
	     «ENDIF»
	«ENDFOR»
	'''
	
	// =========================================================
	// Constrói BranchGuardInfo para cada branch.
	// Atribui índices de guards atômicos e de resultados land.
	//
	// t2: $obstacle /\ since>=X  -> atomics=[guard_1,guard_2]
	//                               ifGuard=guard_result_1
	//                               needsLand=true
	//
	// t4: $obstacle              -> atomics=[guard_3]
	//                               ifGuard=guard_3
	//                               needsLand=false
	// =========================================================
	// ATUALIZADO: buildBranchGuardInfos
	// Recebe os nomes dos resultados atômicos já calculados
	// pelo collectGuardContext e os agrupa por branch.
	//
	// Cada branch contribui com tantos atomicResultNames
	// quantas sub-condições seu AND tiver.
	
	def buildBranchGuardInfos(List<Transition> branches,
                          	  SimMachineDef stm,
                          	  boolean needsClock,
                              GuardContext guardCtx) {

	    val infos         = new ArrayList<BranchGuardInfo>
    	var landResultIdx = 1
    	var condIdx       = 0
		
		val resultNames = guardCtx.computeSubCondResultNames()
		
	    for (branch : branches) {
        val subCondCount      = flattenAnd(branch.condition).size
        val branchResultNames = resultNames
                                    .subList(condIdx, condIdx + subCondCount)
                                    .toList
	        condIdx += subCondCount
	
	        if (branchResultNames.size > 1) {
	            val resultName = "guard_result_" + landResultIdx
	            landResultIdx++
	            infos.add(new BranchGuardInfo(branchResultNames, resultName, true))
	        } else {
	            infos.add(new BranchGuardInfo(branchResultNames,
	                                          branchResultNames.head, false))
	        }
    	}
    	return infos
	}
	
	// =========================================================
	// Traduz o lado esquerdo de um Assignment (Assignable)
	// VarRef -> Movement_StopTime
	
	def String translateAssignable(Assignable left, SimMachineDef stm) {
	    switch left {
	        VarRef:
	            stm.name + "_" + left.name.name
	        VarSelection:
	            translateAssignable(left.receiver, stm) + "." + left.member.name
	        default:
	            left.toString
	    }
	}

	
	// =========================================================
	// Achata uma expressão AND em lista de sub-condições.
	// Necessário para B0: cada IF aceita apenas uma condição.
	//
	// $obstacle /\ since(T) >= X  →  [$obstacle, since(T) >= X]
	// A /\ B /\ C                 →  [A, B, C]
	// condição simples             →  [condição]
	// =========================================================
	def List<Expression> flattenAnd(Expression expr) {
	    switch expr {
	        And: {
	            val result = new ArrayList<Expression>
	            result.addAll(flattenAnd(expr.left))
	            result.addAll(flattenAnd(expr.right))
	            return result
	        }
	        default: return #[expr]
	    }
	}
	
	// =========================================================
	// Coleta OperationSig com parâmetros do outputContext.
	// Fonte única para os dois métodos geradores.
	// =========================================================
	def getOutputOperationsWithParams(SimMachineDef stm) {
	    val ctx = stm.outputContext
	    if (ctx === null) return #[]
	
	    val fromInterfaces = ctx.RInterfaces
	                           .flatMap[ it.operations ]
	                           .toList
	
	    val direct = ctx.operations.toList
	
	    return (fromInterfaces + direct)
	               .filter[ !parameters.isEmpty ]
	               .toList
	}
	
	// =========================================================
	// Traduz o tipo RoboSim de um parâmetro para o tipo B.
	//
	// boolean → BOOL
	// nat     → uint32_t
	// default → INT (fallback seguro)
	// =========================================================
	def translateParamType(Parameter param) {
	    val typeName = param.type?.toString ?: ""
	    switch typeName {
	        case "boolean": "BOOL"
	        case "nat":     "uint32_t"
	        default:        "BOOL"
	    }
	}
	
	// =========================================================
	// Gera a especificação local de uma operação com parâmetros.
	//
	// move(l_lv, l_av) =
	// PRE l_lv:BOOL & l_av:BOOL
	// THEN
	//     o_move_lv :: uint8_t ||
	//     o_move_av :: uint8_t
	// END
	// =========================================================
	def generateOperationLocalSpec(OperationSig op) '''
	    «op.name»(«FOR p : op.parameters SEPARATOR ","»l_«p.name»«ENDFOR») =
	    PRE «FOR p : op.parameters SEPARATOR " & "»l_«p.name»:«translateParamType(p)»«ENDFOR»
	    THEN
	        «FOR p : op.parameters SEPARATOR " ||"»
	            o_«op.name»_«p.name» :: uint8_t
	        «ENDFOR»
	    END;
	'''
	
	// Gera para todas as operações com parâmetros
	def generateAllOperationLocalSpecs(SimMachineDef stm) {
	    val ops = stm.getOutputOperationsWithParams
	    '''
	    «FOR op : ops SEPARATOR ";"»
	        «generateOperationLocalSpec(op)»
	    «ENDFOR»
	    '''
	}
	
	
	// =========================================================
	// Gera a implementação de uma operação com parâmetros.
	//
	// move(l_lv, l_av) =
	// BEGIN
	//     IF l_lv = TRUE
	//     THEN o_move_lv := IO_ON
	//     ELSE o_move_lv := IO_OFF
	//     END;
	//     IF l_av = TRUE
	//     THEN o_move_av := IO_ON
	//     ELSE o_move_av := IO_OFF
	//     END
	// END
	// =========================================================
	def generateOperationImplementation(OperationSig op) '''
	    «op.name»(«FOR p : op.parameters SEPARATOR ","»l_«p.name»«ENDFOR») =
	    BEGIN
	        «FOR p : op.parameters SEPARATOR ";"»
	            IF l_«p.name» = TRUE
	            THEN
	                o_«op.name»_«p.name» := IO_ON
	            ELSE
	                o_«op.name»_«p.name» := IO_OFF
	            END
	        «ENDFOR»
	    END;
	'''
	
	// Orquestrador: gera para todas as operações com parâmetros
	def generateAllOperationImplementations(SimMachineDef stm) {
	    val ops = stm.getOutputOperationsWithParams
	    '''
	    «FOR op : ops SEPARATOR ";"»
	        «generateOperationImplementation(op)»
	    «ENDFOR»
	    '''
	}
	
	// =========================================================
	// Gera a implementação das operações individuais de leitura
	// de input na cláusula OPERATIONS.
	// Reutilizando collectInputEntries como fonte de dados.
	//
	// read_i_obstacle =
	// BEGIN
	//     i_obstacle <-- get_board_0_I1
	// END;
	// =========================================================
	def generateIndividualReadImplementations(SimMachineDef stm) {
	    val inputs = stm.collectInputEntries
		// Capacidade máxima de inputs da placa atual
		val int BOARD_MAX_INPUTS = 3
		
	    // Valida antes de gerar — falha cedo com mensagem clara
	    if (inputs.size > BOARD_MAX_INPUTS)
	        throw new IllegalStateException(
	            "Numero de inputs do modelo (" + inputs.size + ") " +
	            "excede a capacidade da placa (" + BOARD_MAX_INPUTS + " pinos). " +
	            "Inputs declarados: " + inputs.map[ bVarName ].join(", ")
	        )
	
	    '''
	    «FOR pair : inputs.indexed»
	        read_«pair.value.bVarName» =
	        BEGIN
	            «pair.value.bVarName» <-- get_board_0_I«pair.key + 1»
	        END;
	         
	    «ENDFOR»
	    '''
	}
		
	// =========================================================
	// Gera a operação read_model_inputs que agrega todos os inputs 
	// da máquina de estados
	def generateOperationReadModelInputs(SimMachineDef stm) {
	    val inputs = stm.collectInputEntries
	    '''
	    read_model_inputs =
	    BEGIN	    
	        cycle_state := st_STATE_MACHINE«IF !inputs.empty»; «ENDIF»
	        «FOR entry : inputs SEPARATOR "; "»
	            read_«entry.bVarName» 
	        «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Gera uma operação local read_ individual por InputEntry.
	// Reutiliza collectInputEntries como única fonte de dados.
	//
	// read_i_obstacle =
	// PRE cycle_state = st_READ_INPUTS
	// THEN
	//     i_obstacle :: uint8_t
	// END;
	// =========================================================
	def generateIndividualReadOperations(SimMachineDef stm) {
	    val inputs = stm.collectInputEntries
	    '''
	    «FOR entry : inputs»
	        read_«entry.bVarName» =
	        PRE cycle_state = st_READ_INPUTS
	        THEN
	            «entry.bVarName» :: «entry.bType»
	        END;
	         
	    «ENDFOR»
	    '''
	}
	
	// =========================================================
	// VERSÃO ESTENDIDA — múltiplas máquinas
	// Filtra inputs que são eventos conectados internamente
	// entre máquinas (não vêm da plataforma).
	//
	// Delivery.inputContext tem "event arrived" ->
	//   arrived ∈ connEventNames -> filtrado -> sem read_i_arrived
	def generateIndividualReadOperations(List<SimMachineDef> machines,
	                                      RCPackage pkg) {
	    // Uma máquina: comportamento original preservado
	    if (machines.size == 1)
	        return generateIndividualReadOperations(machines.head)
	
	    val connEventNames = collectConnectedEvents(pkg).map[ eventName ].toSet
	
	    '''
	    «FOR stm : machines»
	        «val filteredInputs = stm.collectInputEntries
	                                 .filter[ !connEventNames.contains(
	                                     bVarName.replace("i_", "")) ]
	                                 .toList»
	        «FOR entry : filteredInputs»
	            read_«entry.bVarName» =
	            PRE cycle_state = st_READ_INPUTS
	            THEN
	                «entry.bVarName» :: «entry.bType»
	            END
	        «ENDFOR»
	    «ENDFOR»
	    '''
	}
	
	// =========================================================
	// Coleta os inputs que vêm da plataforma/controller,
	// identificados por conexões onde o SOURCE é o controller
	// (não uma máquina).
	//
	// connection CPD on obstacle to stm_ref0 on obstacle
	//   from = CPD (ControllerDef) -> é input da plataforma
	//   -> InputEntry("i_obstacle", EVENT)
	//
	// connection stm_ref0 on arrived to stm_ref1 on arrived
	//   from = stm_ref0 (máquina) -> é conexão interna -> ignorado
	def collectPlatformInputEntries(RCPackage pkg) {
	    val result  = new ArrayList<InputEntry>
	    val seen    = new HashSet<String>   // evita duplicatas
	
	    pkg.controllers
	       .filter(ControllerDef)
	       .forEach[ ctrl |
	           ctrl.connections.forEach[ conn |
	
	               val fromNode = conn.from
	
	               // Só nos interessa quando o SOURCE é o controller
	               // (significa que o evento vem de fora, da plataforma)
	               val isFromController = resolveMachineName(fromNode) === null
	
	               if (isFromController) {
	                   val eventName = conn.efrom.name
	                   if (seen.add(eventName))   // add retorna false se já existia
	                       result.add(new InputEntry("i_" + eventName, InputKind.EVENT))
	               }
	           ]
	       ]
	
	    return result
	}
	
	// =========================================================
	// Coleta todos os inputs do inputContext e os descreve
	// como InputEntry, cobrindo todas as fontes possíveis:
	//
	//   1. Eventos via interfaces (uses)
	//   2. Eventos via pInterfaces (provides)
	//   3. Variáveis via rInterfaces (requires)
	//   4. Eventos declarados diretamente no contexto
	//   5. Variáveis declaradas diretamente no contexto
	// =========================================================
	def collectInputEntries(SimMachineDef stm) {
	    val ctx = stm.inputContext
	    if (ctx === null) return #[]
	
	    val entries = new ArrayList<InputEntry>
	
	    // FONTE 1: Eventos via interfaces
		ctx.interfaces
   			.flatMap[ it.events ]
   			.forEach[ e |
       		   // Flag — sempre gerado, comportamento antigo intocado
       		   entries.add(new InputEntry("i_" + e.name, InputKind.EVENT))

	       	   // Valor — só quando o evento for tipado
		       if (e.type !== null) {
		           entries.add(new InputEntry(
		               "i_" + e.name + "_value",
		               InputKind.EVENT_VALUE,
		               "uint8_t" ))
		       }
   			]
		
		
	    // FONTE 2: Eventos via pInterfaces (provides X)
		ctx.PInterfaces
			.flatMap[ it.events ]
   			.forEach[ e |
		    // Flag — sempre gerado, comportamento antigo intocado
       		   entries.add(new InputEntry("i_" + e.name, InputKind.EVENT)) 
			   
			   // Valor — só quando o evento for tipado
		       if (e.type !== null) {
		           entries.add(new InputEntry(
		               "i_" + e.name + "_value",
		               InputKind.EVENT_VALUE,
		               "uint8_t" ))
		       }
   			]
   	
	    // FONTE 3: Variáveis via rInterfaces (requires X)
	    ctx.RInterfaces
	       .flatMap[ it.variableList ]
	       .flatMap[ it.vars ]
	       .forEach[ v |
	           entries.add(new InputEntry("i_" + v.name, InputKind.VARIABLE))
	       ]
	
	    // FONTE 4: Eventos declarados diretamente no contexto
	    ctx.events
	       .forEach[ e |
		    // Flag — sempre gerado, comportamento antigo intocado
       		   entries.add(new InputEntry("i_" + e.name, InputKind.EVENT))
       		   
			// Valor — só quando o evento for tipado
		       if (e.type !== null) {
		           entries.add(new InputEntry(
		               "i_" + e.name + "_value",
		               InputKind.EVENT_VALUE,
		               "uint8_t" ))
		       }
   			]	
	
	    // FONTE 5: Variáveis declaradas diretamente no contexto
	    ctx.variableList
	       .flatMap[ it.vars ]
	       .forEach[ v |
	           entries.add(new InputEntry("i_" + v.name, InputKind.VARIABLE))
	       ]
	
	    return entries
	}
	
	// =========================================================
	// Gera a operação local read_model_inputs na cláusula
	// LOCAL_OPERATIONS usando os InputEntry coletados.
	//
	// Todos os tipos geram :: uint8_t por agora a distinção
	// por InputKind permite especializar no futuro.
	def generateReadModelInputs(SimMachineDef stm) {
	    val inputs = stm.collectInputEntries
	    '''
	    read_model_inputs =
	    PRE cycle_state = st_READ_INPUTS
	    THEN
	        cycle_state :: uint32_t«IF !inputs.empty» ||«ENDIF»
	        «FOR entry : inputs SEPARATOR " ||"»
	            «entry.bVarName» :: «entry.bType»
	        «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// VERSÃO ESTENDIDA — múltiplas máquinas
	// Usa collectPlatformInputEntries para buscar inputs
	// da plataforma via connections do controller.
	//
	// Regra de seleção automática:
	//   1 máquina  → usa collectInputEntries da máquina
	//   2+ máquinas → usa collectPlatformInputEntries
	def generateReadModelInputs(List<SimMachineDef> machines, RCPackage pkg) {
	    // Uma única máquina: comportamento original preservado
	    if (machines.size == 1)
	        return generateReadModelInputs(machines.head)
	
	    // Múltiplas máquinas: busca inputs do controller
	    val inputs = collectPlatformInputEntries(pkg)
	
	    '''
	    read_model_inputs =
	    PRE cycle_state = st_READ_INPUTS
	    THEN
	    cycle_state :: uint32_t«IF !inputs.empty» ||«ENDIF»
	    «FOR entry : inputs SEPARATOR " ||"»
	        «entry.bVarName» :: «entry.bType»
	    «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Versão para múltiplas máquinas filtra eventos conectados 
	// internamente antes de resolver as chamadas, usando a mesma 
	// lógica de generateLocalOperations.
	// Regra de seleção automática:
	//   1 máquina  -> comportamento original preservado
	//   2+ máquinas -> filtra connEvents e resolve chamadas
	// =========================================================
	def generateWriteModelOutputs(List<SimMachineDef> machines, RCPackage pkg) {
	
	    if (machines.size == 1)
	        return generateWriteModelOutputs(machines.head.collectOutputEntries)
	
	    val connEvents     = collectConnectedEvents(pkg)
	    val connEventNames = connEvents.map[ eventName ].toSet
	
	    // Filtra outputs que são eventos conectados internamente
	    val platformOutputs = machines
	                            .flatMap[ collectOutputEntries ]
	                            .filter[ !connEventNames.contains(
	                                bVarName.replace("o_", "")) ]
	                            .toList
	
	    val calls = resolveWriteCalls(platformOutputs)
	
	    '''
	    write_model_outputs =
	    BEGIN
	    cycle_state := st_TIME;
	    «FOR call : calls SEPARATOR ";"»
	        «call»
	    «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Gera a operação write_model_outputs
	// Sempre começa com cycle_state := st_TIME
	// e chama as operações de escrita na ordem dos outputs
	// =========================================================
	def generateWriteModelOutputs(List<OutputEntry> outputs) {
	    val calls = resolveWriteCalls(outputs)
	    '''
	    write_model_outputs =
	    BEGIN
	    cycle_state := st_TIME;
	    «FOR call : calls SEPARATOR ";"»
	        «call»
	    «ENDFOR»
	    END;
	    '''
	}
	
	// =========================================================
	// Resolve a lista de chamadas únicas para write_model_outputs
	// a partir dos OutputEntry coletados.
	//
	// Regras:
	//   OPERATION_PARAM  -> agrupa por parentOperationNamechamada: write_o_<parentOp>
	//   OPERATION_ATOMIC -> chamada direta: write_o_<opName>
	//   VARIABLE         -> chamada direta: write_o_<varName>
	//   EVENT            -> chamada direta: write_o_<eventName>
	// =========================================================
	def resolveWriteCalls(List<OutputEntry> outputs) {
	    val calls     = new ArrayList<String>
	    val seenOps   = new HashSet<String>   // evita duplicatas de OPERATION_PARAM
	
	    for (entry : outputs) {
	        switch entry.kind {
	
	            // Agrupa parâmetros da mesma operação em uma chamada
	            case OPERATION_PARAM: {
	                val callName = "write_o_" + entry.parentOperationName
	                if (seenOps.add(callName))   // add retorna false se já existia
	                    calls.add(callName)
	            }
	
	            // Operação atômica, variável ou evento: chamada direta
	            case OPERATION_ATOMIC,
	            case VARIABLE,
	            case EVENT:
	                calls.add("write_" + entry.bVarName)
	        }
	    }
	    return calls
	}
		
	// =========================================================
	// Adiciona caso OutputCommunication ($arrived)
	// $arrived       -> o_arrived := IO_ON
	// $arrived!value -> o_arrived := IO_ON; o_arrived_value := value
	// =========================================================
    def List<String> translateStatement(Statement stmt, 
    									SimMachineDef stm,
    									Map<String, String> connEventMap) {
        val result = new ArrayList<String>
        switch stmt {
            // Sequência: #MBC; $move(false, false)
            SeqStatement:
                for (s : stmt.statements)
                    result.addAll(translateStatement(s, stm, connEventMap))

            // #MBC -> var_MBC_1 <-- get_ms_tick
            ClockReset:
                result.add(getClockBName(stmt.clock, stm) + " <-- get_ms_tick")

            // $move(lv, false) -> move(SimSMovement_lv, FALSE)
            SimCall: {
                val args = stmt.args.map[ translateArg(it, stm) ].join(", ")
                result.add(stmt.operation.name + "(" + args + ")")
            }
			
			// OutputCommunication -> seta flag do evento de output
	        // $arrived         -> o_arrived := IO_ON  (sem valor = ocorrência)
	        // $arrived!true    -> o_arrived := IO_ON
	        // $arrived!false   -> o_arrived := IO_OFF
	        // =========================================================
	        OutputCommunication: {
	            val ioValue  = resolveOutputCommunicationValue(stmt)
            	val eventName = stmt.event.name
            	// Usa nome prefixado da máquina se for evento conectado
	            val bName = connEventMap.getOrDefault(eventName, "o_" + eventName)
	            result.add(bName + " := " + ioValue)
	        }
						
			// Assignment traduz '=' para ':='
	        // StopTime = delta -> Movement_StopTime := Movement_delta
	        // StopTime = StopTime - delta -> Movement_StopTime := sub_uint32(...)
			Assignment: {
	            val left  = translateAssignable(stmt.left, stm)
	            val right = translateOperand(stmt.right, stm)
	            result.add(left + " := " + right)
        	}
			
            default:
                result.add("// TODO: traduzir statement: " + stmt.class.simpleName)
        }
        return result
    }
	
	// Versão original mantida para compatibilidade com casos sem eventos conectados (SRanger)
	def List<String> translateStatement(Statement stmt, SimMachineDef stm) {
	    translateStatement(stmt, stm, #{})
	}
	
	// =========================================================
	// Resolve o valor IO_ON / IO_OFF de um OutputCommunication.
	//
	// Regras:
	//   sem valor ($arrived)       → IO_ON  (ocorrência implica verdadeiro)
	//   valor true  ($arrived!true)  → IO_ON
	//   valor false ($arrived!false) → IO_OFF
	// =========================================================
	def String resolveOutputCommunicationValue(OutputCommunication stmt) {
	    if (stmt.value === null)
	        return "IO_ON"
	
	    switch stmt.value {
	        BooleanExp:
	            if ((stmt.value as BooleanExp).value == "true") "IO_ON" else "IO_OFF"
	        default:
	            "IO_ON"
	    }
	}
	
	// Substitui o acesso direto a expr.ref.name
	def dispatch String resolveRefName(Variable ref) {
	    ref.name
	}
	
	def dispatch String resolveRefName(Parameter ref) {
	    ref.name
	}
	
	def dispatch String resolveRefName(NamedExpression ref) {
	    // fallback para tipos não mapeados
	    ref.toString
	}
	
    // Traduz um argumento de operação
    def String translateArg(Expression expr, SimMachineDef stm) {
        switch expr {
            BooleanExp: if (expr.value == "true") "TRUE" else "FALSE"
            
            RefExp:     stm.name + "_" + resolveRefName(expr.ref)
            
            // literal inteiro como argumento
        	IntegerExp: expr.value.toString
            
            default:    expr.toString            
        }
    }
	
	// Traduz operando de comparação (left ou right de LessThan, GreaterOrEqual)
    def String translateOperand(Expression expr, SimMachineDef stm) {
              
        switch expr {
	        ClockExp:   "since_local"
	        RefExp:     stm.name + "_" + resolveRefName(expr.ref)
	        BooleanExp: if (expr.value == "true") "TRUE" else "FALSE"
			
			// literal inteiro -> valor diretamente
	        // 1 → "1", 100 → "100"
	        IntegerExp: expr.value.toString
			
	        // aritmética -> operadores B0 seguros contra overflow
	        // MOVINGTIME + StopTime -> add_uint32(Movement_MOVINGTIME, Movement_StopTime)
	        Plus:
	            "add_uint32(" +
	            translateOperand(expr.left, stm) + ", " +
	            translateOperand(expr.right, stm) + ")"
	
	        // StopTime - delta -> sub_uint32(Movement_StopTime, Movement_delta)
	        Minus:
	            "sub_uint32(" +
	            translateOperand(expr.left, stm) + ", " +
	            translateOperand(expr.right, stm) + ")"
			
			// ParExp -> tira do parenteses e traduz o conteúdo interno
	        // (StopTime - delta) -> sub_uint32(Movement_StopTime, Movement_delta)
	        ParExp:
            	translateOperand(expr.exp, stm)
			
	        default: expr.toString
	    }
    }
	
	// verifica se um operando aritmético contém clock
	def boolean operandUsesClock(Expression expr) {
	    switch expr {
	        ClockExp: true
	        Plus:     operandUsesClock(expr.left) || operandUsesClock(expr.right)
	        Minus:    operandUsesClock(expr.left) || operandUsesClock(expr.right)
	        default:  false
	    }
	}
		
    // Verifica se uma condição usa expressão de clock
    def boolean conditionUsesClock(Expression expr) {
        switch expr {
            LessThan:       expr.left instanceof ClockExp || expr.right instanceof ClockExp ||
            				operandUsesClock(expr.left)   || operandUsesClock(expr.right)
            GreaterOrEqual: expr.left instanceof ClockExp || expr.right instanceof ClockExp ||
            				operandUsesClock(expr.left)   || operandUsesClock(expr.right)
            LessOrEqual:    expr.left instanceof ClockExp || expr.right instanceof ClockExp ||
            				operandUsesClock(expr.left)   || operandUsesClock(expr.right)
            GreaterThan:    expr.left instanceof ClockExp || expr.right instanceof ClockExp ||
            				operandUsesClock(expr.left)   || operandUsesClock(expr.right)
            Not:            conditionUsesClock(expr.exp)
            And:            conditionUsesClock(expr.left) || conditionUsesClock(expr.right)
            ParExp:         conditionUsesClock(expr.exp)
            default:        false
        }
    }

    // Encontra o nome B do clock usado nas condições das branches
    def findClockVarName(List<Transition> branches, SimMachineDef stm) {
        for (b : branches) {
            val clock = findClockInCondition(b.condition)
            if (clock !== null) return getClockBName(clock, stm)
        }
        return ""
    }

    def Clock findClockInCondition(Expression expr) {
        switch expr {
            LessThan:       if (expr.left instanceof ClockExp) (expr.left as ClockExp).clock else null
            GreaterOrEqual: if (expr.left instanceof ClockExp) (expr.left as ClockExp).clock else null
            default: null
        }
    }

    // Nome B de um clock: MBC (1º da máquina) → var_MBC_1
    def getClockBName(Clock clock, SimMachineDef stm) {
        "var_" + clock.name + "_" + (stm.clocks.indexOf(clock) + 1)
    }
	
	// =========================================================
    // Tradução de condições
    // =========================================================

    def String translateCondition(Expression expr,
                               SimMachineDef stm,
                               boolean usesSinceLocal,
                               Map<String, String> connEventMap) {
        switch expr {
            // $obstacle -> i_obstacle = IO_ON
            SimRefExp: {
                val eventName = expr.element.name
            	val bName     = connEventMap.getOrDefault(eventName, "i_" + eventName)
            	bName + " = IO_ON"
			}
            // not $obstacle -> i_obstacle = IO_OFF
            Not:
            if (expr.exp instanceof SimRefExp) {
                val eventName = (expr.exp as SimRefExp).element.name
                val bName     = connEventMap.getOrDefault(eventName, "i_" + eventName)
                bName + " = IO_OFF"
            } else
                "not (" + translateCondition(expr.exp, stm, usesSinceLocal, connEventMap) + ")"

            // since(MBC) < Pi -> since_local < SimSMovement_Pi
            LessThan:
                translateOperand(expr.left, stm) + " < " + translateOperand(expr.right, stm)

            // since(MBC) >= Pi -> SimSMovement_Pi <= since_local
            // (B0: reescreve >= como <= com operandos trocados)
            GreaterOrEqual:
                translateOperand(expr.right, stm) + " <= " + translateOperand(expr.left, stm)
            
            // LessOrEqual -> tradução direta
            LessOrEqual:
            	translateOperand(expr.left, stm) + " <= " + translateOperand(expr.right, stm)

	        // GreaterThan -> reescreve como LessOrEqual invertido (B0 check)
	        GreaterThan:
            	translateOperand(expr.right, stm) + " < " + translateOperand(expr.left, stm)
                
            // ParExp -> tira dos parenteses e traduz o conteúdo interno
	        // not (since(TIMER) < MOVINGTIME + StopTime)
	        //      ParExp envolve o LessThan interno
	        ParExp:
	            translateCondition(expr.exp, stm, usesSinceLocal, connEventMap)
			
			// Referência a variável booleana: obst -> "SimSMovement_obst = TRUE"
			RefExp:
			    stm.name + "_" + resolveRefName(expr.ref) + " = TRUE"
			
            default: expr.toString
        }
    }
    
    // Versão original sem o mapa, passa para a estendida com mapa vazio.
	def String translateCondition(Expression expr,
	                               SimMachineDef stm,
	                               boolean usesSinceLocal) {
	    translateCondition(expr, stm, usesSinceLocal, #{})
	}
	
	// Coleta ações de uma branch saindo de junction + próximo EXEC
    //
    // transition t5: ação #MBC; $move(false,false) -> target Waiting (EXEC_2)
    // transition t10: sem ação -> target SMoving (não exec) -> segue até DMoving (EXEC_1)
    def Pair<List<String>, String> collectBranchPath(Transition branch, 
    												 SimMachineDef stm,
                                                     LinkedHashMap<State, Integer> execMap,
                                                     Map<String, String> connEventMap) {
        val actions = new ArrayList<String>

        // Traduz a ação da própria transição (ex: #MBC; $move(false, false))
        if (branch.action !== null)
            actions.addAll(translateStatement(branch.action, stm, connEventMap))
		
		// Para nova versao SRanger: emite binding de valor quando condição é $evento?variavel
	    // $obstacle?obst -> SimSMovement_obst := bool(i_obstacle_value = IO_ON)
	    if (branch.condition instanceof SimRefExp) {
	        val simRef = branch.condition as SimRefExp
	        if (simRef.variable !== null) {
	            val eventName = simRef.element.name
	            val varName   = stm.name + "_" + simRef.variable.name
	            actions.add(varName + " := bool(i_" + eventName + "_value = IO_ON)")
	        }
	    }
		
        val target = branch.target

        // Alvo é diretamente um exec state
        if (target instanceof State && execMap.containsKey(target as State))
             // converte Integer para String com prefixo "EXEC_"
        	return actions -> ("EXEC_" + execMap.get(target as State))
		
		// Direct exec state
	    if (target instanceof State && execMap.containsKey(target as State))
	        return actions -> ("EXEC_" + execMap.get(target as State))
	
	    // Para nova versao SRanger: alvo é uma junção aninhada 
	    if (target instanceof Junction) {
	        val nestedBlock = generateNestedJunctionBlock(
	            target as Junction, stm, execMap, connEventMap)
	        actions.add(nestedBlock)
	        return actions -> null  // null = nested block já emite SM_X_state :=
	    }
		
        // Senão, continua coletando a partir do alvo
        val pathResult = collectPathUntilExec(target, stm, execMap, connEventMap)
    	actions.addAll(pathResult.key)
        //converte Integer para String com prefixo "EXEC_"
    		return actions -> ("EXEC_" + pathResult.value)
    }

    // Coleta a entry action de um State e adiciona na lista de ações
    def collectEntryAction(State state, 
    					   SimMachineDef stm, 
    					   List<String> actions,
    					   Map<String, String> connEventMap) {
        val entryAction = state.actions.filter(EntryAction).head
        if (entryAction !== null)
            actions.addAll(translateStatement(entryAction.action, stm, connEventMap))
    }
	
	// =========================================================
    // Percorrendo o grafo
    // Coleta ações seguindo o grafo a partir de startNode até atingir um exec state
    // Retorna: Pair<lista de ações traduzidas, número do próximo EXEC>
    // =========================================================
    def Pair<List<String>, Integer> collectPathUntilExec(Node startNode,
                                                      SimMachineDef stm,
                                                      LinkedHashMap<State, Integer> execMap,
                                                      Map<String, String> connEventMap) {
        val actions = new ArrayList<String>
	    var Node current = startNode
	
	    if (current instanceof State) {
	        collectEntryAction(current as State, stm, actions, connEventMap)
	        if (execMap.containsKey(current as State))
	            return actions -> execMap.get(current as State)
	    }
	
	    // NOVO: se começa em Final, retorna -1 como sinal
	    if (current instanceof Final)
	        return actions -> -1
	
	    var found = false
	    while (!found) {
	        val node = current
	        val outgoing = stm.transitions.findFirst[ t |
	            t.source == node && !(t.trigger instanceof ExecTrigger)
	        ]
	        if (outgoing === null)
	            throw new IllegalStateException(
	                "Nenhuma transição não-exec encontrada a partir de: " + node)
	
	        if (outgoing.action !== null)
	            actions.addAll(translateStatement(outgoing.action, stm, connEventMap))
	
	        current = outgoing.target
	
	        // NOVO: se chegou em Final, encerra a travessia
	        if (current instanceof Final) {
	            found = true
	        } else if (current instanceof State) {
	            collectEntryAction(current as State, stm, actions, connEventMap)
	            if (execMap.containsKey(current as State))
	                found = true
	        }
	    }
	
	    // NOVO: retorna -1 se o caminho termina em Final
	    if (current instanceof Final)
	        return actions -> -1
	
	    return actions -> execMap.get(current as State)
    }
	
	
	// =========================================================
	// Bloco com junction: avalia guards e branches
    //
    // EXEC_1: DMoving ->(exec)-> J1 ->(guard_1: $obstacle)-> Waiting (EXEC_2)
    //                               ->(guard_2: not $obstacle)-> DMoving (EXEC_1)
    def generateBranchingBlock(SimMachineDef stm, 
    						   int execNum,
	                           Junction junction,
	                           LinkedHashMap<State, Integer> execMap,
	                           Map<String, String> connEventMap) {

     	val branches   = stm.transitions.filter[ source == junction ].toList
	    val needsClock = branches.exists[ t | conditionUsesClock(t.condition) ]
	    val clockVar   = if (needsClock) findClockVarName(branches, stm) else ""
	
	    val guardCtx = collectPredicatesAndConditions(branches, stm, needsClock, connEventMap)
	    val infos    = buildBranchGuardInfos(branches, stm, needsClock, guardCtx)
	
	/*// Extrai predicados e reescreve condições
    val result         = collectPredicatesAndConditions(branches, stm, needsClock)
    val predicates     = result.key
    val rewrittenConds = result.value */
	

    '''
    ELSIF SM_«stm.name»_state = EXEC_«execNum» THEN
    «generateGuardBlock(stm, execNum, branches, infos, needsClock, clockVar,
            guardCtx, [b, s, m | collectBranchPath(b, s, m, connEventMap)], execMap)»
    '''
    }
    
	// =========================================================
	// Bloco linear: sem junction após exec
    //
    // EXEC_2: Waiting →(exec)→ STurning (entry $move(false,av)) → DTurning (EXEC_3)
    def generateLinearBlock(SimMachineDef stm, 
    						int execNum, 
    						Node startNode,
                            LinkedHashMap<State, Integer> execMap,
                            Map<String, String> connEventMap) {
                            	
        val result = collectPathUntilExec(startNode, stm, execMap, connEventMap)
        '''

        ELSIF SM_«stm.name»_state = EXEC_«execNum» THEN
        «FOR a : result.key»
        «a»;
        «ENDFOR»
        SM_«stm.name»_state:= EXEC_«result.value»
        '''
    }
	
	// =========================================================
	// No PoliteDelivery o estado com exec condicional e com outras transições mais condições
	// Going:
	//   t4 (exec, since<MOVINGTIME) → Going (EXEC_2)
	//   t2 (since>=MOVINGTIME)      → f0
	//   t3 ($obstacle)              → f0
	// =========================================================
	def generateMultiBranchFromState(SimMachineDef stm, 
									 int execNum,
                                  	 State state,
                                     LinkedHashMap<State, Integer> execMap,
                                     Map<String, String> connEventMap) {

	    val allBranches = stm.transitions.filter[ source == state ].toList
	    val needsClock  = allBranches.exists[ t | conditionUsesClock(t.condition) ]
	    val clockVar    = if (needsClock) findClockVarName(allBranches, stm) else ""
	
	    val guardCtx = collectPredicatesAndConditions(allBranches, stm, needsClock, connEventMap)
	    val infos    = buildBranchGuardInfos(allBranches, stm, needsClock, guardCtx)
    
	
	/*// Extrai predicados e reescreve condições
    val result         = collectPredicatesAndConditions(allBranches, stm, needsClock)
    val predicates     = result.key
    val rewrittenConds = result.value*/
	
    '''
    ELSIF SM_«stm.name»_state = EXEC_«execNum» THEN
    «generateGuardBlock(stm, execNum, allBranches, infos, needsClock, clockVar,
            guardCtx, [b, s, m | collectFinalAction(b, s, m, connEventMap)], execMap)»
    '''
	}
	
	// =========================================================
	// Coleta ações de uma transição que pode ir para Final
	// Retorna: Pair<ações, nome do próximo estado B>
	//   → Final    : "FINAL"
	//   → EXEC_N   : "EXEC_N"
	// =========================================================
	def Pair<List<String>, String> collectFinalAction(Transition t,
	                                                   SimMachineDef stm,
	                                                   LinkedHashMap<State, Integer> execMap,
	                                                   Map<String, String> connEventMap) {
	    val actions = new ArrayList<String>
	
	    // Traduz a ação da transição (ex: $arrived; $moving(false))
	    if (t.action !== null)
	        actions.addAll(translateStatement(t.action, stm, connEventMap))
	
	    val target = t.target
	
	    // Transição vai para Final
	    if (target instanceof Final)
	        return actions -> "FINAL"
	
	    // Transição vai para exec state diretamente
	    if (target instanceof State && execMap.containsKey(target as State))
	        return actions -> ("EXEC_" + execMap.get(target as State))
	
	    // Senão, continua coletando o caminho
	    val pathResult = collectPathUntilExec(target, stm, execMap, connEventMap)
	    actions.addAll(pathResult.key)
	    
	    // -1 significa que o caminho terminou em Final
	    return actions -> (if (pathResult.value == -1) "FINAL"
	                       else "EXEC_" + pathResult.value)
	}
	
	// =========================================================
    //Gera bloco EXEC_N (delega para linear ou branching)
    //MODIFICAÇÃO! em generateExecBlock
	// Agora detecta três padrões:
	//   A) exec sem condição → Junction     (SRanger)
	//   B) exec sem condição → State linear (SRanger)
	//   C) exec com condição → State com múltiplas saídas (PoliteDelivery)
    // =========================================================
    def generateExecBlock(SimMachineDef stm, 
    					  State execState, 
    					  int execNum,
                          LinkedHashMap<State, Integer> execMap,
                          Map<String, String> connEventMap) {
                          	
        val execTransition = stm.transitions.findFirst[ t | t.source == execState && t.trigger instanceof ExecTrigger ]
        
        val nextNode = execTransition.target

        // PADRÃO C: exec com condição -> state com múltiplas saídas diretas
	    if (execTransition.condition !== null)
	        return generateMultiBranchFromState(stm, execNum, execState, execMap, connEventMap)
	
	    // PADRÃO A: exec sem condição -> Junction
	    if (nextNode instanceof Junction)
	        return generateBranchingBlock(stm, execNum, nextNode as Junction, execMap, connEventMap)
	
	    // PADRÃO B: exec sem condição -> State linear
	    return generateLinearBlock(stm, execNum, nextNode, execMap, connEventMap)
    }
	
	// =========================================================
    // Gera bloco INIT
    // Percorre do initial até o primeiro exec state
    // =========================================================
    def generateInitBlock(SimMachineDef stm, 
    	                  LinkedHashMap<State, Integer> execMap, 
    	                  Map<String, String> connEventMap) {
    	                  	
        val initial = stm.nodes.filter(Initial).head
        val result = collectPathUntilExec(initial, stm, execMap, connEventMap)
        '''
        «FOR a : result.key»
        «a»;
        «ENDFOR»
        SM_«stm.name»_state:= EXEC_«result.value»
        '''
    }
	
	// =========================================================
    // Identifica estados com exec saindo → EXEC_N
    // Percorre transições em ordem de declaração
    // =========================================================
    def findExecStates(SimMachineDef stm) {
        val execMap = new LinkedHashMap<State, Integer>
        var counter = 1
        for (t : stm.transitions) {
            if (t.trigger instanceof ExecTrigger) {
                val src = t.source
                if (src instanceof State && !execMap.containsKey(src as State)) {
                    execMap.put(src as State, counter)
                    counter++
                }
            }
        }
        return execMap
    }
	
	// =========================================================
	// Gera a operação SM_<nome> para TODAS as máquinas do modelo.
	// Versão estendida — mantém o método original intacto para
	// compatibilidade e delega para ele por máquina.
	// =========================================================
	def generateAllStateMachineOperations(List<SimMachineDef> machines, RCPackage pkg){
		val connEvents = collectConnectedEvents(pkg) 
	'''
	«FOR mch : machines»
		 «val connEventMap = buildConnectedEventMap(mch, connEvents)»
		 «generateStateMachineOperation(mch, connEventMap)»
	«ENDFOR»
	'''
	}
	// =========================================================
    // Gera a operação completa SM_<nome>
    // =========================================================
    def generateStateMachineOperation(SimMachineDef stm,
                                   	  Map<String, String> connEventMap) {
        val execMap = findExecStates(stm)
        '''
        SM_«stm.name» =
        BEGIN
        IF SM_«stm.name»_state = INIT THEN
         «generateInitBlock(stm, execMap, connEventMap)»
        «FOR entry : execMap.entrySet»
        «generateExecBlock(stm, entry.key, entry.value, execMap, connEventMap)»
        «ENDFOR»
        END;
        cycle_state := st_WRITE_OUTPUTS
        END;
        
        '''
    }
	
	// Versão original sem mapa para compatibilidade com o caso SRanger
	def generateStateMachineOperation(SimMachineDef stm) {
	    generateStateMachineOperation(stm, #{})
	}
	
	// =========================================================
	// Gera operações locais para cada OperationSig com parametros
	def generateAggregateWriteLocalOperations(SimMachineDef stm) {
		val ctx = stm.outputContext
    	if (ctx === null) return ''

    	val fromInterfaces = ctx.RInterfaces
                           .flatMap[ it.operations ]
                           .toList

    	val direct = ctx.operations.toList

	    // Filtra apenas operações COM parâmetros
	    val opsWithParams = (fromInterfaces + direct)
	                            .filter[ !parameters.isEmpty ]
	                            .toList
	    '''
	    «FOR op : opsWithParams»
	    write_o_«op.name» =
	    PRE cycle_state = st_WRITE_OUTPUTS
	    THEN  
	    board_0_O1  :: uint8_t ||
	    board_0_O2  :: uint8_t ||
	    cycle_state :: uint8_t
	    END;
	    «ENDFOR»
	    '''                        
	}
	
	// =========================================================
	// Gera operações agregadas para cada OperationSig
	// com parâmetros do outputContext.
	// A operação agregada chama as operações individuais de cada parâmetro.
	// move(lv, av) -> write_o_move chama write_o_move_lv e write_o_move_av
	// stop()       -> ignorada (sem parâmetros, já é atômica)
	// =========================================================
	def generateAggregateWriteOperations(SimMachineDef stm) {
    	val ctx = stm.outputContext
    	if (ctx === null) return ''

    	val fromInterfaces = ctx.RInterfaces
                           .flatMap[ it.operations ]
                           .toList

    	val direct = ctx.operations.toList

	    // Filtra apenas operações COM parâmetros
	    val opsWithParams = (fromInterfaces + direct)
	                            .filter[ !parameters.isEmpty ]
	                            .toList
    	'''
	    «FOR op : opsWithParams SEPARATOR ";"»
	        write_o_«op.name» =
	        BEGIN
	        «FOR param : op.parameters SEPARATOR ";"»
	        write_o_«op.name»_«param.name»
	        «ENDFOR»
	        END;
	    «ENDFOR»
	    '''
	}
	
	// =========================================================
	// Gera em OPERATIONS a implementação da operação write_ por variável de output,
	// mapeando cada uma saída da placa sequencialmente.
	// =========================================================
	def generateOperations(List<OutputEntry> outputs) '''
        «FOR pair : outputs.indexed»
            write_«pair.value.bVarName» =
            BEGIN
                board_0_O«pair.key + 1» := «pair.value.bVarName»
            END;
            «"\n"»
        «ENDFOR»
	'''
	
	// =========================================================
	// VERSÃO ESTENDIDA — múltiplas máquinas
	// Filtra eventos conectados internamente antes de mapear
	// para pinos da placa, usando a mesma lógica de
	// generateLocalOperations e generateWriteModelOutputs.
	//
	// Regra de seleção automática:
	//   1 máquina  → comportamento original preservado
	//   2+ máquinas → filtra connEvents e gera apenas platform outputs
	// =========================================================
	def generateOperations(List<SimMachineDef> machines, RCPackage pkg) {
	
	    if (machines.size == 1)
	        return generateOperations(machines.head.collectOutputEntries)
	
	    val connEvents     = collectConnectedEvents(pkg)
	    val connEventNames = connEvents.map[ eventName ].toSet
	
	    // Apenas outputs que vão para pinos físicos da placa
	    val platformOutputs = machines
	                            .flatMap[ collectOutputEntries ]
	                            .filter[ !connEventNames.contains(
	                                bVarName.replace("o_", "")) ]
	                            .toList
	
	    '''
	    «FOR pair : platformOutputs.indexed»
	        write_«pair.value.bVarName» =
	        BEGIN
	            board_0_O«pair.key + 1» := «pair.value.bVarName»
	        END;
	        «"\n"»
	    «ENDFOR»
	    '''
	}
	
	// =========================================================
    // Valida se o número de outputs do modelo
    // não excede a capacidade de saídas da placa.
    // Lança uma exceção descritiva antes de gerar código inválido.
    // =========================================================
    def validateOutputCount(List<String> allOutputNames) {
        // Capacidade máxima da placa atual — altere aqui ao trocar de versão
    	val int BOARD_MAX_OUTPUTS = 2
        val outputCount = allOutputNames.size
		
        if (outputCount > BOARD_MAX_OUTPUTS)
            throw new IllegalStateException(
                "Numero de outputs do modelo (" + outputCount + ") " +
                "excede a capacidade da placa (" + BOARD_MAX_OUTPUTS + " pinos). " +
                "Outputs declarados: " + allOutputNames.join(", ")
            )
    }
	
	// =========================================================
	// Gera em LOCAL_OPERATIONS
	// Uma operação write_ por variável de output,
	// mapeando cada uma saída da placa sequencialmente.
	//
	// o_move_lv (índice 0) -> write_o_move_lv / board_0_O1
	// o_move_av (índice 1) -> write_o_move_av / board_0_O2
	// o_stop    (índice 2) -> write_o_stop    / board_0_O3
	// etc...
	// =========================================================
	def generateLocalOperations(List<OutputEntry> outputs) '''
        «FOR pair : outputs.indexed »
            write_«pair.value.bVarName» =
            PRE cycle_state = st_WRITE_OUTPUTS
            THEN
                «generateThenClause(pair.value, pair.key + 1)»
            END;
            «"\n"»
        «ENDFOR»
	'''
	
	// Gera o conteúdo do THEN conforme o tipo do output
	def generateThenClause(OutputEntry entry, int pinIndex) {
	    switch entry.kind {
	
	        // Operação com parâmetro: escreve no pino da placa
	        case OPERATION_PARAM:
	            '''board_0_O«pinIndex» :: uint8_t'''
	
	        // Operação atômica: escreve no pino da placa
	        case OPERATION_ATOMIC:
	            '''board_0_O«pinIndex» :: uint8_t'''
	
	        // Variável required: escreve no pino da placa
	        case VARIABLE:
	            '''board_0_O«pinIndex» :: uint8_t'''
	
	        // Evento: escreve no pino E reseta o flag após a escrita
	        case EVENT:
	            '''board_0_O«pinIndex» :: uint8_t'''
	            
	    }
	}
	
	// =========================================================
	// Versao estendida do metodo generateLocalOperations para múltiplas máquinas
	// Distingue:
	//   - outputs para plataforma -> board_0_ON :: uint8_t
	//   - eventos conectados (source ou internos) -> MachineName_event :: uint8_t
	def generateLocalOperations(List<SimMachineDef> machines, RCPackage pkg) {
	
	    // Uma máquina: comportamento original preservado
	    if (machines.size == 1)
	        return generateLocalOperations(machines.head.collectOutputEntries)
	
	    val connEvents     = collectConnectedEvents(pkg)
    	val connEventNames = connEvents.map[ eventName ].toSet
	
		// Outputs normais para a placa (exclui eventos internos)
	    val platformOutputs = machines
	                            .flatMap[ collectOutputEntries ]
	                            .filter[ !connEventNames.contains(
	                                bVarName.replace("o_", "")) ]
	                            .toList	
	    '''
	    «FOR pair : platformOutputs.indexed»
	    write_«pair.value.bVarName» =
	    PRE cycle_state = st_WRITE_OUTPUTS
	    THEN
	       «generateThenClause(pair.value, pair.key + 1)»
	    END;
	    «ENDFOR»
	    '''
	}

	/*/ =========================================================
	// Verifica se um evento de output de uma máquina está direcionado
	// para fora do módulo controlador e portanto se torna output do modelo.
	//
	// connection stm_ref1 on drop to CPD on drop
	//   drop é output do sistema via controller
	def boolean isControllerOutput(SimMachineDef stm, String eventName, RCPackage pkg) {
	    pkg.controllers
	       .filter(ControllerDef)
	       .exists[ ctrl |
	           ctrl.connections.exists[ conn |
	               resolveMachineName(conn.from) == stm.name &&
	               conn.efrom.name == eventName &&
	               resolveMachineName(conn.to) === null   // destino é controller/plataforma
	           ]
	       ]
	}*/
		
	// =========================================================
    // Coleta Required Variables do outputContext
    // Regra SM3/SM4: required variables devem ser input OU output
    // =========================================================
    def getOutputVariables(SimMachineDef stm) {
        val ctx = stm.outputContext
        if (ctx === null) return #[]

        val fromInterfaces = ctx.RInterfaces
                               .flatMap[ it.variableList ]
                               .flatMap[ it.vars ]
                               .toList

        val direct = ctx.variableList
                        .flatMap[ it.vars ]
                        .toList

        return (fromInterfaces + direct)
    }
	
	// =========================================================
    // Expande cada OperationSig do outputContext
    // gerando uma variavel B por parâmetro, ou variavel com nome 
    // da operação caso ela não tenha parâmetros.
    //
    // move(lv: boolean, av: boolean) -> "o_move_lv", "o_move_av"
    // stop()                         -> "o_stop"
    // =========================================================
    def getOutputOperationParamNames(SimMachineDef stm) {
        val ctx = stm.outputContext
        if (ctx === null) return #[]

        val fromInterfaces = ctx.RInterfaces
                               .flatMap[ it.operations ]
                               .toList

        val direct = ctx.operations.toList

        return (fromInterfaces + direct)
            .flatMap[ op |
                if (op.parameters.isEmpty)
                    // Operação sem parâmetros -> o_<nomeOp>
                    #["o_" + op.name]
                else
                    // Operação com parâmetros -> o_<nomeOp>_<nomeParam> por parâmetro
                    op.parameters.map[ param |
                        "o_" + op.name + "_" + param.name
                    ]
            ]
            .toList
    }
	    
    // =========================================================
	// Coleta todos os outputs do outputContext
	// e os descreve semanticamente como OutputEntry.
	//
	// Ordem de coleta:
	//   1. OperationSig via rInterfaces
	//   2. OperationSig diretas no contexto
	//   3. Variables via rInterfaces
	//   4. Variables diretas no contexto
	//   5. Eventos diretos no contexto
	// =========================================================
	def collectOutputEntries(SimMachineDef stm) {
	    val ctx = stm.outputContext
	    if (ctx === null) return #[]
	
	    val entries = new ArrayList<OutputEntry>
	
	    // Operações via interfaces requeridas 
	    val opsFromInterfaces = ctx.RInterfaces
	                              .flatMap[ it.operations ]
	                              .toList
	
	    // Operações declaradas diretamente 
	    val opsDirect = ctx.operations.toList
	
	    // Processa cada operação
	    for (op : opsFromInterfaces + opsDirect) {
	        if (op.parameters.isEmpty) {
	            // stop() -> o_stop (OPERATION_ATOMIC)
	            entries.add(new OutputEntry(
	                "o_" + op.name,
	                OutputKind.OPERATION_ATOMIC
	            ))
	        } else {
	            // move(lv, av) -> o_move_lv, o_move_av (OPERATION_PARAM)
	            for (param : op.parameters) {
	                entries.add(new OutputEntry(
	                    "o_" + op.name + "_" + param.name,
	                    OutputKind.OPERATION_PARAM,
	                    op.name   // guarda a operação de origem
	                ))
	            }
	        }
	    }
	
	    // Variaveis via interfaces requeridas
	    ctx.RInterfaces
	       .flatMap[ it.variableList ]
	       .flatMap[ it.vars ]
	       .forEach[ v |
	           entries.add(new OutputEntry(
	               "o_" + v.name,
	               OutputKind.VARIABLE
	           ))
	       ]
	
	    // --- Variáveis declaradas diretamente ---
	    ctx.variableList
	       .flatMap[ it.vars ]
	       .forEach[ v |
	           entries.add(new OutputEntry(
	               "o_" + v.name,
	               OutputKind.VARIABLE
	           ))
	       ]
	
	    // --- Eventos declarados diretamente ---
	    ctx.events.forEach[ e |
	        entries.add(new OutputEntry(
	            "o_" + e.name,
	            OutputKind.EVENT
	        ))
	    ]
	
	    return entries
	}
    
    def SimMachineDef getSimMachine(RCPackage pkg) {
    	pkg.machines.head as SimMachineDef
	}
	
	
	def generateUserCtxi(RCPackage UserCtxi){
		val modules = collectAllSimModules(UserCtxi)
		val machines  = collectAllSimMachines(UserCtxi)
    	val constants = collectAllMachineConstants(UserCtxi)
    	val execCounti = countExecTriggers(UserCtxi)
	'''
		IMPLEMENTATION
		    user_ctx_i
		REFINES
		    user_ctx
		SEES
		  	    g_types
		VALUES
		INIT = 0;
		«FOR i : 0 ..< execCounti»
		    EXEC_«i + 1» = «i + 1»;
		«ENDFOR»
		FINAL = «execCounti + 1»;
		st_READ_INPUTS = 0;
		st_STATE_MACHINE = 1;
		st_WRITE_OUTPUTS = 2;
		st_TIME = 3;
		cycle_unit = 1000;
		«FOR mods : modules SEPARATOR "; \n"»«mods.name»_cycleDef = «getCycleDefValueForModule(mods)»«ENDFOR»«IF !modules.empty»;«ENDIF»
		«FOR stm : machines SEPARATOR "; \n"»«stm.name»_cycleDef = «getCycleDefValueForMachine(stm)»«ENDFOR»«IF !machines.empty»;«ENDIF»
		«FOR c : constants SEPARATOR "; \n"»«c.bName» = «mapImpl(c.constant.type)»«ENDFOR»
		END
	'''
	}
	
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
	
	// Versão por módulo — lê o cycleDef do SimModule
	def int getCycleDefValueForModule(SimModule module) {
	    val expr = module.cycleDef
	
	    if (expr instanceof IntegerExp)
	        return expr.value
	
	    if (expr instanceof Equals) {
	        val right = expr.right
	        if (right instanceof IntegerExp)
	            return right.value
	    }
	
	    return 0
	}
		
	// Versão por máquina — usada por generateUserCtxi atualizado
	def int getCycleDefValueForMachine(SimMachineDef stm) {
	    val expr = stm.cycleDef
	
	    if (expr instanceof IntegerExp)
	        return expr.value
	
	    if (expr instanceof Equals) {
	        val right = expr.right
	        if (right instanceof IntegerExp)
	            return right.value
	    }
	
	    return 0
	}
	
	/*/ Versão original mantida para compatibilidade
	def int getCycleDefValue(RCPackage pkg) {
	    getCycleDefValueForMachine(pkg.machines.head as SimMachineDef)
	}*/
							
	def generateUserCtx(RCPackage UserCtx){
		val modules = collectAllSimModules(UserCtx) 
		val machines  = collectAllSimMachines(UserCtx)
    	val constants = collectAllMachineConstants(UserCtx)
    	val execCount = countExecTriggers(UserCtx)
	'''
		MACHINE
		    user_ctx
		SEES
		    g_types
		
		CONCRETE_CONSTANTS
				
		INIT,
		«FOR i : 0 ..< execCount»
		    EXEC_«i + 1»,
		«ENDFOR»
		FINAL,
		st_READ_INPUTS,
		st_STATE_MACHINE,
		st_WRITE_OUTPUTS,
		st_TIME,
		cycle_unit,
		«FOR mods : modules SEPARATOR ", \n"»«mods.name»_cycleDef«ENDFOR»«IF !modules.empty»,«ENDIF»
		«FOR stm : machines SEPARATOR ", \n"»«stm.name»_cycleDef«ENDFOR»«IF !machines.empty»,«ENDIF»
		«FOR c : constants SEPARATOR ", \n"»«c.bName»«ENDFOR»
		
		PROPERTIES
		INIT: uint8_t &
		«FOR i : 0 ..< execCount»
			EXEC_«i + 1»: uint8_t &
		«ENDFOR»
		FINAL: uint8_t &
		st_READ_INPUTS: uint8_t &
		st_STATE_MACHINE: uint8_t &
		st_WRITE_OUTPUTS: uint8_t &
		st_TIME: uint8_t &
		cycle_unit:uint32_t &
		«FOR mods : modules SEPARATOR " &\n"»«mods.name»_cycleDef : uint32_t«ENDFOR»«IF !modules.empty»&«ENDIF»
		«FOR stm : machines SEPARATOR " &\n"»«stm.name»_cycleDef : uint32_t«ENDFOR»«IF !machines.empty» &«ENDIF»
		«FOR c : constants SEPARATOR " &\n"»«c.bName» : «mapType(c.constant.type)»«ENDFOR»
		END
	'''
	}
	
	// =========================================================
	// Coleta todas as constantes do modelo agrupadas por máquina.
	// Cada constante carrega o nome da máquina de origem para
	// geração correta do prefixo B.
	//
	// MachineA: const PI: nat    -> MachineConstEntry("MachineA", PI)
	// MachineB: const MAX: nat   -> MachineConstEntry("MachineB", MAX)
	// =========================================================
	def collectAllMachineConstants(RCPackage pkg) {
	    val result = new ArrayList<MachineConstEntry>
	
	    val machines = collectAllSimMachines(pkg)
	
	    for (stm : machines) {
	        // Filtra apenas VariableList com modifier CONST
	        for (vl : stm.variableList.filter[ modifier == VariableModifier.CONST ]) {
	            for (v : vl.vars) {
	                result.add(new MachineConstEntry(stm.name, v))
	            }
	        }
	    }
	
	    return result
	}
	
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
		    
}

// Representa uma constante com o nome da sua máquina de origem
class MachineConstEntry {
    public val String machineName   // "Movement", "SimSmovement"
    public val Variable constant    // constantes definidas

    // Nome B completo: "Movement_MOVINGTIME"
    def String bName() { machineName + "_" + constant.name }

    new(String machineName, Variable constant) {
        this.machineName = machineName
        this.constant    = constant
    }
}

// 	 Agrega todos os dados necessários para geração de guardas:
//   predicates     -> predicados aritméticos (predicate_N)
//   subCondBoolExprs -> expressão dentro do bool() por sub-condição
//   subCondNeedsLnot -> true se a sub-condição é Not complexo
class GuardContext {
    public val List<PredicateEntry> predicates
    public val List<String>  subCondBoolExprs
    public val List<Boolean> subCondNeedsLnot

    new(List<PredicateEntry> predicates,
        List<String>  subCondBoolExprs,
        List<Boolean> subCondNeedsLnot) {
        this.predicates        = predicates
        this.subCondBoolExprs  = subCondBoolExprs
        this.subCondNeedsLnot  = subCondNeedsLnot
    }

    // Total de slots de guard (lnot usa 2: inner + resultado)
    def int totalGuardSlots() {
        subCondNeedsLnot.map[ if (it) 2 else 1 ]
                        .reduce[ a, b | a + b ] ?: 0
    }

    // Pré-computa os nomes de resultado por sub-condição
    // Normal -> "guard_N"
    // LNot   -> "guard_N+1" (resultado do lnot)
    def List<String> computeSubCondResultNames() {
        val result = new ArrayList<String>
        var gc = 1
        for (var i = 0; i < subCondBoolExprs.size; i++) {
            if (subCondNeedsLnot.get(i)) {
                result.add("guard_" + (gc + 1))  // lnot result
                gc = gc + 2
            } else {
                result.add("guard_" + gc)
                gc = gc + 1
            }
        }
        return result
    }

    // Pré-computa as linhas de atribuição dos guards
    // Normal -> "guard_N := bool(expr)"
    // LNot   -> "guard_N := bool(expr)" + "guard_N+1 <-- lnot(guard_N)"
    def List<String> computeGuardAssignments() {
        val result = new ArrayList<String>
        var gc = 1
        for (var i = 0; i < subCondBoolExprs.size; i++) {
            val expr = subCondBoolExprs.get(i)
            if (subCondNeedsLnot.get(i)) {
                result.add("guard_" + gc + " := bool(" + expr + ");")
                result.add("guard_" + (gc + 1) + " <-- lnot(guard_" + gc + ");")
                gc = gc + 2
            } else {
                result.add("guard_" + gc + " := bool(" + expr + ");")
                gc = gc + 1
            }
        }
        return result
    }
}

// Representa um evento que flui de uma máquina para outra
// via Connection no Controller.
//
// connection stm_ref0 on arrived to stm_ref1 on arrived
// ConnectedEventEntry("Movement", "Delivery", "arrived")
// gera: Movement_arrived e Delivery_arrived
class ConnectedEventEntry {
    public val String sourceMachineName   // "Movement"
    public val String targetMachineName   // "Delivery"
    public val String eventName           // "arrived"

    // Nome B da variável no lado fonte
    def String sourceVarName() { sourceMachineName + "_" + eventName }

    // Nome B da variável no lado alvo
    def String targetVarName() { targetMachineName + "_" + eventName }

    new(String sourceMachineName, String targetMachineName, String eventName) {
        this.sourceMachineName = sourceMachineName
        this.targetMachineName = targetMachineName
        this.eventName         = eventName
    }
}

// Representa uma variável da máquina de estados
// com todos os dados necessários para as três cláusulas
class MachineVarEntry {

    // Nome B da variável: "Movement_x", "var_MBC_1"
    public val String bVarName

    // Tipo B: "uint32_t", "BOOL", "int"
    public val String bType

    // Valor inicial traduzido:
    //   var com initial -> "0", "TRUE", etc.
    //   var sem initial -> null (usa nondeterministic :: tipo)
    //   const          -> null (usa nondeterministic :: tipo)
    //   clock          -> "0"
    public val String initialValue

    // Indica se a inicialização é determinística (:=) ou não (:)
    public val boolean isDeterministic

    new(String bVarName, String bType,
        String initialValue, boolean isDeterministic) {
        this.bVarName        = bVarName
        this.bType           = bType
        this.initialValue    = initialValue
        this.isDeterministic = isDeterministic
    }
}

// Representa uma expressão aritmética extraída de uma condição
class PredicateEntry {

    // Nome do predicado: "predicate_n"
    public val String name

    // Expressão aritmética traduzida: "sub_uint32(...)"
    public val String expression

    // Tipo B da expressão
    public val String bType

    new(String name, String expression, String bType) {
        this.name       = name
        this.expression = expression
        this.bType      = bType
    }
}

// Descreve os guards de uma branch
class BranchGuardInfo {
    // Nomes dos guards atômicos: ["guard_1", "guard_2"]
    public val List<String> atomicGuardNames

    // Guard usado no IF:
    //   AND  -> "guard_result_1"
    //   simples -> "guard_1"
    public val String ifGuardName

    // Indica se precisa de land()
    public val boolean needsLand

    new(List<String> atomicGuardNames, String ifGuardName, boolean needsLand) {
        this.atomicGuardNames = atomicGuardNames
        this.ifGuardName      = ifGuardName
        this.needsLand        = needsLand
    }
}

// Representa um input do modelo com sua origem semântica
class InputEntry {

    public val String bVarName   // ex: i_obstacle, i_MissionStart
    public val InputKind kind
	public val String bType      // "uint8_t" (flag), "BOOL", "uint32_t" (valor)
	
    // Construtor antigo continua existindo — default uint8_t
    new(String bVarName, InputKind kind) {
        this(bVarName, kind, "uint8_t")
    }
    
    new(String bVarName, InputKind kind, String bType) {
        this.bVarName = bVarName
        this.kind     = kind
        this.bType    = bType
    }
}

enum InputKind {
    EVENT,    // i_obstacle  — evento de input
    EVENT_VALUE,   // valor associado a um evento tipado
    VARIABLE  // i_speed     — required variable de input
}

// Representa um output do modelo com sua origem semântica
class OutputEntry {

    // Nome da variável B gerada (ex: o_move_lv, o_arrived)
    public val String bVarName

    // Origem semântica — facilita geração de código específico por tipo
    public val OutputKind kind

    // Nome da operação de origem, se aplicável (ex: "move" para o_move_lv)
    public val String parentOperationName

    new(String bVarName, OutputKind kind) {
        this.bVarName            = bVarName
        this.kind                = kind
        this.parentOperationName = null
    }

    new(String bVarName, OutputKind kind, String parentOperationName) {
        this.bVarName            = bVarName
        this.kind                = kind
        this.parentOperationName = parentOperationName
    }
}

// Tipos possíveis de output
enum OutputKind {
    OPERATION_PARAM,   // o_move_lv — parâmetro de operação
    OPERATION_ATOMIC,  // o_stop    — operação sem parâmetros
    VARIABLE,          // o_speed   — required variable
    EVENT              // o_arrived — evento de output
}
