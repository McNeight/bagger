package gov.loc.repository.bagger;

import java.util.Collection;

import gov.loc.repository.bagger.Project;
import gov.loc.repository.bagger.Profile;
import gov.loc.repository.bagger.Organization;

import org.springframework.dao.DataAccessException;

public interface Bagger {

	Collection<Organization> getOrganizations() throws DataAccessException;

	Collection<Project> getProjects() throws DataAccessException;

	Collection<ContactType> getContactTypes() throws DataAccessException;
	
	Collection<Organization> findOrganizations(String name) throws DataAccessException;

	Collection<Profile> findProfiles(String name) throws DataAccessException;
	
	Collection<Project> findProjects(int personId) throws DataAccessException;

	Profile loadProfile(int id) throws DataAccessException;
	
	Contact loadContact(int id) throws DataAccessException;
	
	ContactType loadContactType(int id) throws DataAccessException;
	
	Person loadPerson(int id) throws DataAccessException;

	Organization loadOrganization(int id) throws DataAccessException;
	
	Address loadAddress(int id) throws DataAccessException;
	
	Project loadProject(int id) throws DataAccessException;

	void storeOrganization(Organization org) throws DataAccessException;

}