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

package circus.robocalc.robosim.generator.prism.sim

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.Diagnostician
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import java.util.Collections
import circus.robocalc.robosim.textual.generator.AbstractRoboSimGenerator

class SimGenerator extends AbstractRoboSimGenerator {

	override getID() {
		"ROBOSIM_PRISM_GENERATOR"
	}

	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		System.out.println("[RoboSim] Generating PRISM model for " + resource.URI.toString)

		var diagnostic = Diagnostician.INSTANCE.validate(resource.getContents().get(0));

		// TODO: define a predicate for warningIsRelevant (see GeneratorUtils in the other generator plugins)
		//if (diagnostic.children.filter[d|gu.warningIsRelevant(d)].size() > 0) {
		if (diagnostic.children.size() > 0) {
			// if there are relevant warning, do not generate
			return;
		}
		val fileExtension = resource.URI.fileExtension
		if ("rsa".equals(fileExtension)) {
			// TODO: generator assertions
		} else if ("rst".equals(fileExtension)){
			// TODO: generate robosim
		}
	}
}
