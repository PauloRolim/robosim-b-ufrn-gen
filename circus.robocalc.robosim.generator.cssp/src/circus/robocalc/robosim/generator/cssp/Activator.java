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
 ********************************************************************************/
package circus.robocalc.robosim.generator.cssp;

import java.util.Collections;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.eclipse.xtext.ui.shared.SharedStateModule;
import org.eclipse.xtext.util.Modules2;
import org.osgi.framework.BundleContext;

import com.google.common.collect.Maps;
import com.google.inject.Guice;
import com.google.inject.Injector;

import circus.robocalc.robochart.textual.RoboChartRuntimeModule;

/**
 * The activator class controls the plug-in life cycle
 */
public class Activator extends AbstractUIPlugin {
	
    // The plug-in ID
    public static final String PLUGIN_ID = "circus.robocalc.robosim.generator.cssp";
    // TODO: Do we need the RoboChart textual here for RoboSim?
    public static final String CIRCUS_ROBOCALC_ROBOCHART_TEXTUAL_ROBOCHART = "circus.robocalc.robochart.textual.RoboChart";
    public static final String CIRCUS_ROBOCALC_ROBOSIM_TEXTUAL_ROBOSIM = "circus.robocalc.robosim.textual.RoboSim";
    // The shared instance
    private static Activator plugin;
    
    private static final Logger logger = Logger.getLogger(Activator.class);

    private Map<String, Injector> injectors = Collections.synchronizedMap(Maps.<String, Injector> newHashMapWithExpectedSize(1));
    
    @Override
    public void start(BundleContext context) throws Exception {
      super.start(context);
	  plugin = this;
    }

    @Override
    public void stop(BundleContext context) throws Exception {
    	injectors.clear();
    	plugin = null;
    	super.stop(context);
    }
    
	public Injector getInjector(String language) {
		synchronized (injectors) {
			Injector injector = injectors.get(language);
			if (injector == null) {
				injectors.put(language, injector = createInjector(language));
			}
			return injector;
		}
	}

    protected Injector createInjector(String language) {
		try {
			com.google.inject.Module runtimeModule = getRuntimeModule(language);
			com.google.inject.Module sharedStateModule = getSharedStateModule();
			com.google.inject.Module mergedModule = Modules2.mixin(runtimeModule, sharedStateModule);
			return Guice.createInjector(mergedModule);
		} catch (Exception e) {
			logger.error("Failed to create injector for " + language);
			logger.error(e.getMessage(), e);
			throw new RuntimeException("Failed to create injector for " + language, e);
		}
	}
	
	protected com.google.inject.Module getRuntimeModule(String grammar) {
		if (CIRCUS_ROBOCALC_ROBOSIM_TEXTUAL_ROBOSIM.equals(grammar)) {
			return new RoboChartRuntimeModule();
		}
		throw new IllegalArgumentException(grammar);
	}
	
	protected com.google.inject.Module getSharedStateModule() {
		return new SharedStateModule();
	}
    
    /**
     * Returns the shared instance
     * 
     * @return the shared instance
     */
    public static Activator getInstance() {
    	return plugin;
    }
}
