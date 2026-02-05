/********************************************************************************
 * Copyright (c) 2019 University of York and others
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 ********************************************************************************/

package circus.robocalc.robosim.generator.prism;

import org.eclipse.core.runtime.Platform;
import org.eclipse.xtext.ui.guice.AbstractGuiceAwareExecutableExtensionFactory;
import org.osgi.framework.Bundle;

import com.google.inject.Injector;

public class PRISMGeneratorExecutableExtensionFactory  extends AbstractGuiceAwareExecutableExtensionFactory {

	@Override
	protected Bundle getBundle() {
		return Platform.getBundle(Activator.PLUGIN_ID);
	}
	
	@Override
	protected Injector getInjector() {
		Activator activator = Activator.getInstance();
		return activator != null ? activator.getInjector(Activator.CIRCUS_ROBOCALC_ROBOSIM_TEXTUAL_ROBOSIM) : null;
	}

}
