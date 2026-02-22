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

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.ui.menus.WorkbenchWindowControlContribution;

public class PRISMToolbarLabel extends WorkbenchWindowControlContribution {

	public PRISMToolbarLabel() {
	}

	public PRISMToolbarLabel(String id) {
		super(id);
	}

	@Override
	protected Control createControl(Composite parent) {
		Composite cmp = new Composite( parent, SWT.NONE );
		RowLayout rl = new RowLayout();
	    rl.wrap = false;
	    rl.pack = false;
	    rl.marginTop = 3;
	    cmp.setLayout(rl);
	    
		Label label = new Label( cmp, SWT.NONE );
		label.setText( "SimCSSP" );
		return cmp;
		
	}

}
