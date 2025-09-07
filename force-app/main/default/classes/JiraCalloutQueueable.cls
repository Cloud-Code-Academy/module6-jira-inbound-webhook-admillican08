/**
 * Queueable class to make asynchronous callouts to Jira API
 */
public class JiraCalloutQueueable implements Queueable, Database.AllowsCallouts {
    // Simple constants instead of enum
    public static final String TYPE_PROJECT = 'PROJECT';
    public static final String TYPE_ISSUE = 'ISSUE';
    
    private String calloutType;
    private Id recordId;
    private JiraWrapper.ProjectWrapper projectWrapper;
    private JiraWrapper.IssueWrapper issueWrapper;
    
    /**
     * Constructor for Jira Project callout
     * @param recordId The Salesforce Jira Project record Id
     * @param projectName The name of the project
     * @param projectKey The unique key for the project
     * @param description Project description
     */
    public JiraCalloutQueueable(
        Id recordId,
    String projectName,
    String projectKey,
    String description
    ) {
        this.calloutType = TYPE_PROJECT;
        this.recordId = recordId;
        this.projectWrapper = new JiraWrapper.ProjectWrapper(projectName, projectKey, description);
    }
    
    /**
     * Constructor for Jira Issue callout
     * @param recordId The Salesforce Jira Issue record Id
     * @param projectKey The project key where the issue should be created
     * @param summary The issue summary/title
     * @param description Issue description
     * @param issueType The type of issue
     */
    public JiraCalloutQueueable(
        Id recordId,
    String projectKey,
    String summary,
    String description,
    String issueType
    ) {
        this.calloutType = TYPE_ISSUE;
        this.recordId = recordId;
        this.issueWrapper = new JiraWrapper.IssueWrapper(
            projectKey,
        summary,
        description,
        issueType
            );
    }
    
    /**
     * Execute the callout based on the callout type
     *
     * 1. Check the callout type (TYPE_PROJECT or TYPE_ISSUE)
     * 2. Call the appropriate JiraAPIService method
     * 3. Update the corresponding Salesforce record with the Jira ID/Key
     */
    public void execute(QueueableContext context) {
        try {
            if (this.calloutType == TYPE_PROJECT) {
                // Call JiraAPIService to create project
                String jiraProjectId = JiraAPIService.createProject(this.projectWrapper);
                // Update Salesforce record with Jira project ID
                updateJiraProject(jiraProjectId);
            } else if (this.calloutType == TYPE_ISSUE) {
                // Call JiraAPIService to create issue
                String jiraIssueKey = JiraAPIService.createIssue(this.issueWrapper);
                // Update Salesforce record with Jira issue key
                updateJiraIssue(jiraIssueKey);
            }
        } catch (Exception ex) {
            Logger.debug('Error in JiraCalloutQueueable.execute(): ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new JiraProcessingException(ex.getMessage());
        }
    }
    
    /**
     * Update the Jira Project record with the Jira project Id
     *
     * Implement this method to update the Jira_Project__c record
     * with the Jira project ID returned from the API
     */
    private void updateJiraProject(String jiraProjectId) {
        if(String.isNotBlank(jiraProjectId)){
            try {
                Jira_Project__c project = new Jira_Project__c(
                    Id = this.recordId,
                Project_ID__c = jiraProjectId
                    );
                update project;
                Logger.debug('Successfully updated Jira Project: ' + jiraProjectId);
                Logger.saveLog();
            } catch (Exception ex) {
                Logger.debug('Error updating Jira Project: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
                Logger.saveLog();
                throw new JiraProcessingException(ex.getMessage());
            }
        }      else {
            
            Logger.debug('Could not update Jira Project');
            Logger.saveLog();
        }
    }
    
    /**
     * Update the Jira Issue record with the Jira issue key
     *
     * Implement this method to update the Jira_Issue__c record
     * with the Jira issue key returned from the API
     * Don't forget to update the Last_Updated__c field with the current time
     */
    private void updateJiraIssue(String jiraIssueKey) {
        if(String.isnotBlank(jiraIssueKey)){
            try {
                Jira_Issue__c issue = new Jira_Issue__c(
                    Id = this.recordId,
                Issue_Key__c = jiraIssueKey,
                Last_Updated__c = DateTime.now()
                    );
                update issue;
                Logger.debug('Successfully updated Jira Issue: ' + jiraIssueKey);
                Logger.saveLog();
            } catch (Exception ex) {
                Logger.debug('Error updating Jira Issue: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
                Logger.saveLog();
                throw ex;
            }
        } else {
            Logger.debug('Could not update Jira Issue');
            Logger.saveLog();
        }
    }
}