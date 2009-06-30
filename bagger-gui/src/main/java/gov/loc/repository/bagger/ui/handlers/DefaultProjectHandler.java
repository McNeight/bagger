
package gov.loc.repository.bagger.ui.handlers;

import gov.loc.repository.bagger.Project;
import gov.loc.repository.bagger.bag.impl.DefaultBag;
import gov.loc.repository.bagger.ui.BagView;

import java.awt.event.ActionEvent;

import javax.swing.AbstractAction;
import javax.swing.JCheckBox;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.richclient.application.Application;
import org.springframework.richclient.application.ApplicationPage;
import org.springframework.richclient.application.PageComponent;

public class DefaultProjectHandler extends AbstractAction {
	private static final Log log = LogFactory.getLog(DefaultProjectHandler.class);
   	private static final long serialVersionUID = 1L;
	BagView bagView;
	DefaultBag bag;

	public DefaultProjectHandler(BagView bagView) {
		super();
		this.bagView = bagView;
	}

	public void actionPerformed(ActionEvent e) {
		this.bag = bagView.getBag();

		JCheckBox cb = (JCheckBox)e.getSource();

		// Determine status
		boolean isSelected = cb.isSelected();
   		Object[] projectArray = bagView.userProjects.toArray();
   		for (int i=0; i < projectArray.length; i++) {
   			Project project = (Project) projectArray[i];
   			project.setIsDefault(false);
    	}

   		Project bagProject = bag.getProject();
   		if (isSelected) bagProject.setIsDefault(true);
   		else bagProject.setIsDefault(false);
   		bag.setProject(bagProject);
   		bagView.setBag(bag);
	}
}