package gov.loc.repository.transfer.ui.controllers;

import gov.loc.repository.transfer.ui.UIConstants;
import gov.loc.repository.transfer.ui.model.UserBean;
import gov.loc.repository.transfer.ui.model.ProcessInstanceBean;
import gov.loc.repository.transfer.ui.model.WorkflowBeanFactory;
import gov.loc.repository.transfer.ui.dao.WorkflowDao;
import gov.loc.repository.transfer.ui.springframework.ModelAndView;
import gov.loc.repository.transfer.ui.utilities.PermissionsHelper;
import java.util.Map;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class ProcessInstanceController extends AbstractRestController {

	
	protected static final Log log = LogFactory.getLog(TaskInstanceController.class);
	public static final String PROCESSINSTANCEID = "processInstanceId";

	@Override
	public String getUrlParameterDescription() {
		return "processinstance/{processInstanceId}\\.{format}";
	}

	@RequestMapping
	@Override
	public ModelAndView handleRequest(
			HttpServletRequest request, 
			HttpServletResponse response) throws Exception 
	{
		return this.handleRequestInternal(request, response);
	}
		
	@Override
	protected void handleIndex(
	        HttpServletRequest request, 
	        ModelAndView mav,
			WorkflowBeanFactory factory, 
			WorkflowDao dao, 
			PermissionsHelper permissionsHelper, Map<String, String> urlParameterMap) throws Exception 
	{
		
		mav.setViewName("processinstancelist");
		mav.addObject(
		    "processInstanceBeanList", dao.getActiveProcessInstanceBeanList() 
		);
		mav.addObject(
		    "problemProcessInstanceBeanList", dao.getProblemProcessInstanceBeanList() 
		);
		if (request.getUserPrincipal() != null)
		{
			UserBean userBean = factory.createUserBean(request.getUserPrincipal().getName());		
			mav.addObject(
			    "processDefinitionBeanList", 
			    userBean.getProcessDefinitionBeanList());
		}
	}

	@Override
	protected void handleGet(
	        HttpServletRequest request, 
	        ModelAndView mav,
			WorkflowBeanFactory factory, 
			WorkflowDao dao,
			 PermissionsHelper permissionsHelper, Map<String, String> urlParameterMap) throws Exception 
	{
		ProcessInstanceBean processInstanceBean = processProcessInstance(mav, dao, urlParameterMap);
		if (processInstanceBean == null) { return; }
		
		mav.addObject("processInstanceBean", processInstanceBean);
		if (permissionsHelper.canUpdateTaskInstanceUser()) {
			mav.addObject(
			    "userBeanList", 
			    dao.getUserBeanList()
			);
		}
		if (permissionsHelper.canMoveToken()) {
			mav.addObject(
			    "nodeBeanList", 
			    processInstanceBean.getProcessDefinitionBean().getNodeBeanList()
			);
		}
		mav.setViewName("processinstance");
	}
	
	@Override
	protected void handlePut(
	        HttpServletRequest request, 
	        ModelAndView mav,
			WorkflowBeanFactory factory, 
			WorkflowDao dao, 
			PermissionsHelper permissionsHelper, Map<String, String> urlParameterMap) throws Exception 
	{
		
		ProcessInstanceBean processInstanceBean = processProcessInstance(mav, dao, urlParameterMap);		    
		if (processInstanceBean == null)
		{
			return;
		}
	
		if (UIConstants.VALUE_TRUE.equalsIgnoreCase(request.getParameter(UIConstants.PARAMETER_CANCEL)))
		{
			processInstanceBean.cancel();
			dao.save(processInstanceBean);
			request.getSession().setAttribute(UIConstants.SESSION_MESSAGE, "The workflow has entered the cancellation process.");
		}
		else if (request.getParameter(UIConstants.PARAMETER_SUSPENDED) != null) {
			if (UIConstants.VALUE_TRUE.equalsIgnoreCase(
			        request.getParameter(UIConstants.PARAMETER_SUSPENDED))) {
				if (! processInstanceBean.isSuspended()) {
					processInstanceBean.suspended(true);					
					dao.save(processInstanceBean);
					request.getSession().setAttribute(UIConstants.SESSION_MESSAGE, "The workflow was suspended.");
				}
			} else if (UIConstants.VALUE_FALSE.equalsIgnoreCase(
			            request.getParameter(UIConstants.PARAMETER_SUSPENDED))) {
				if (processInstanceBean.isSuspended()) {
					processInstanceBean.suspended(false);
					dao.save(processInstanceBean);
					request.getSession().setAttribute(UIConstants.SESSION_MESSAGE, "The workflow was resumed.");
				}
			} 
		}
		if (VariableUpdateHelper.requestUpdatesVariables(request)) {
			VariableUpdateHelper.update(request, processInstanceBean);
			dao.save(processInstanceBean);
			request.getSession().setAttribute(UIConstants.SESSION_MESSAGE, "Variables updated.");
		}
		this.handleGet(request, mav, factory, dao, permissionsHelper, urlParameterMap);
	}
	
	private ProcessInstanceBean processProcessInstance(
	        ModelAndView mav, 
	        WorkflowDao dao,
	        Map<String, String> urlParameterMap )
	{

		//If there is no processInstanceId in urlParameterMap then 404
		if (! urlParameterMap.containsKey(PROCESSINSTANCEID)) {
			mav.setError(HttpServletResponse.SC_NOT_FOUND);
			return null;
		}
		
		//Otherwise handle processinstanceid
		String processInstanceId = urlParameterMap.get(PROCESSINSTANCEID);
		log.debug("ProcessInstanceId is " + processInstanceId);

		ProcessInstanceBean processInstanceBean = dao.getProcessInstanceBean(processInstanceId);
		if (processInstanceBean == null){
			mav.setError(HttpServletResponse.SC_NOT_FOUND);
			return null;
		}
		
		return processInstanceBean;
		
	}
}