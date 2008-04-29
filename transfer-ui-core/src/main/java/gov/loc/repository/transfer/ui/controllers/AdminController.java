package gov.loc.repository.transfer.ui.controllers;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
public class AdminController {

	protected static final Log log = LogFactory.getLog(AdminController.class);

	@RequestMapping("index.html")
	public ModelAndView handleIndex() 
	{
		ModelAndView mav = new ModelAndView("admin");
		log.debug("Handling request at /admin/index.html");
		
		Runtime runtime = Runtime.getRuntime();
		mav.addObject("totalMemory", runtime.totalMemory()/1024);
		mav.addObject("maxMemory", runtime.maxMemory()/1024);
		mav.addObject("freeMemory", runtime.freeMemory()/1024);
		
		Map<String, String> systemInfoMap = new HashMap<String, String>();
		Properties systemProps = System.getProperties();
		for(Object prop:systemProps.keySet()){
		    String key = prop.toString();
		    //splits up long classpaths so wrapping isnt a hassle
		    String value = ((String)systemProps.get(prop)).replace(":",": ");
		    systemInfoMap.put(key, value);
		}
		mav.addObject("systemInfo", systemInfoMap);
		return mav;
	}
	
}