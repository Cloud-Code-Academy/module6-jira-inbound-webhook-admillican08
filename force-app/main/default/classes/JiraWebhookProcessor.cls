/**
 * @description Processor for Jira webhooks
 * Handles issue and project events from Jira
 *
 * STUDENT TASK:
 * Implement the IWebhookProcessor interface to handle Jira webhook events
 * You'll need to process various events like issue/project creation, updates, and deletions
 *
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 *
 * @author Student Name
 */
public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
    
    // Constants for webhook event types
    private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
    private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
    private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
    private static final String EVENT_PROJECT_CREATED = 'project_created';
    private static final String EVENT_PROJECT_UPDATED = 'project_updated';
    private static final String EVENT_PROJECT_DELETED = 'project_deleted';
    
    /**
     * @description Validates the incoming Jira webhook request
     * @param request The REST request containing the webhook payload
     * @return Boolean True if the request is valid, false otherwise
     *
     * STUDENT TASK:
     * Implement validation logic for Jira webhooks
     * - Check for valid JSON by deserializing the request body
     * - Verify the 'webhookEvent' field exists in the payload
     * - You can add further validation like checking for specific headers
     * - Return true if valid, false otherwise
     *
     * HINT:
     * 1. Use try-catch to handle JSON deserialization errors
     * 2. Cast the deserialized JSON to Map<String, Object>
     * 3. Check if required keys exist using containsKey()
     * 4. Example: if (!payload.containsKey('webhookEvent')) { return false; }
     */
    public Boolean validate(RestRequest request) {
        try {
            if (request.requestBody == null) {
                return false;
            }
            
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            if (!payload.containsKey('webhookEvent')) {
                return false;
            }
            
            String webhookEvent = (String) payload.get('webhookEvent');
            
            // Validate that we support this webhook event type
            if (webhookEvent != EVENT_ISSUE_CREATED &&
                webhookEvent != EVENT_ISSUE_UPDATED &&
                webhookEvent != EVENT_ISSUE_DELETED &&
                webhookEvent != EVENT_PROJECT_CREATED &&
                webhookEvent != EVENT_PROJECT_UPDATED &&
            webhookEvent != EVENT_PROJECT_DELETED) {
                return false;
            }
            
            // For issue events, validate issue data exists
            if (webhookEvent.startsWith('jira:issue_')) {
                if (!payload.containsKey('issue')) {
                    return false;
                }
                Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
                if (issueData == null || !issueData.containsKey('key')) {
                    return false;
                }
            }
            
            // For project events, validate project data exists
            if (webhookEvent.startsWith('project_')) {
                if (!payload.containsKey('project')) {
                    return false;
                }
                Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
                if (projectData == null || !projectData.containsKey('key')) {
                    return false;
                }
            }
            
            return true;
            
        } catch (Exception ex) {
            Logger.debug('Error validating webhook: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Processes the Jira webhook request
     * @param request The REST request containing the webhook payload
     *
     * STUDENT TASK:
     * Implement the main processing logic
     * - Parse the JSON payload from the request body
     * - Extract the 'webhookEvent' field to determine the event type
     * - Call the appropriate handler method based on the event type
     *
     * HINT:
     * 1. Use JSON.deserializeUntyped() to convert the request body to a Map
     * 2. Extract the event type: String webhookEvent = (String) payload.get('webhookEvent');
     * 3. Use if/else or switch statements to call the appropriate handler
     * 4. Example: if (webhookEvent == EVENT_ISSUE_CREATED) { processIssueCreated(payload); }
     */
    public void process(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String webhookEvent = (String) payload.get('webhookEvent');
            
            switch on webhookEvent {
                when 'jira:issue_created' {
                    processIssueCreated(payload);
                }
                when 'jira:issue_updated' {
                    processIssueUpdated(payload);
                }
                when 'jira:issue_deleted' {
                    processIssueDeleted(payload);
                }
                when 'project_created' {
                    processProjectCreated(payload);
                }
                when 'project_updated' {
                    processProjectUpdated(payload);
                }
                when 'project_deleted' {
                    processProjectDeleted(payload);
                }
                when else {
                    Logger.debug('Unexpected Jira webhook event received');
                    Logger.saveLog();
                    throw new WebhookProcessingException('Unexpected Jira webhook event received');
                }
            }
            
        } catch (Exception ex) {
            Logger.debug('Error processing webhook: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process an issue_created event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Use this example as a template for other event handlers
     */
    private void processIssueCreated(Map<String, Object> payload) {
        try {
            
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            
            Jira_Issue__c newIssue = createIssueRecord(issueData);
            
            insert as system newIssue;
            
        } catch (Exception ex) {
            Logger.debug('Error processing issue_created event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process an issue_updated event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Implement logic to update an existing Jira_Issue__c record
     * If the record doesn't exist, create it
     */
    private void processIssueUpdated(Map<String, Object> payload) {
        try {
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            String issueKey = (String) issueData.get('key');
            
            List<Jira_Issue__c> existingIssues = [
                SELECT Id, Issue_Key__c, Summary__c, Description__c, Status__c, 
                       Issue_Type__c, Project_Key__c, Last_Updated__c
                FROM Jira_Issue__c 
                WHERE Issue_Key__c = :issueKey WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            if (!existingIssues.isEmpty()) {
                Jira_Issue__c existingIssue = existingIssues[0];
                updateIssueRecord(existingIssue, issueData);
                update as system existingIssue;
            } else {
                Jira_Issue__c newIssue = createIssueRecord(issueData);
                insert as system newIssue;
            }
            
        } catch (Exception ex) {
            Logger.debug('Error processing issue_updated event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process an issue_deleted event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Implement logic to delete a Jira_Issue__c record
     */
    private void processIssueDeleted(Map<String, Object> payload) {
        try {
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            String issueKey = (String) issueData.get('key');
            
            // Find and delete existing issue
            List<Jira_Issue__c> existingIssues = [
                SELECT Id, Issue_Key__c
                FROM Jira_Issue__c 
                WHERE Issue_Key__c = :issueKey WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            if (!existingIssues.isEmpty()) {
                delete as system existingIssues;
            }
            
        } catch (Exception ex) {
            Logger.debug('Error processing issue_deleted event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process a project_created event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Implement logic to create a Jira_Project__c record
     */
    private void processProjectCreated(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            
            Jira_Project__c newProject = createProjectRecord(projectData);
            
            insert as system newProject;
            
        } catch (Exception ex) {
            Logger.debug('Error processing project_created event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process a project_updated event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Implement logic to update an existing Jira_Project__c record
     * If the record doesn't exist, create it
     */
    private void processProjectUpdated(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            String projectKey = (String) projectData.get('key');
            
            // Try to find existing project
            List<Jira_Project__c> existingProjects = [
                SELECT Id, Project_Key__c, Project_Name__c, Description__c, 
                       Project_ID__c
                FROM Jira_Project__c 
                WHERE Project_Key__c = :projectKey WITH SYSTEM_MODE
                LIMIT 1 
            ];
            
            if (!existingProjects.isEmpty()) {
                Jira_Project__c existingProject = existingProjects[0];
                updateProjectRecord(existingProject, projectData);
                update as system existingProject;
            } else {
                Jira_Project__c newProject = createProjectRecord(projectData);
                insert as system newProject;
            }
            
        } catch (Exception ex) {
            Logger.debug('Error processing project_updated event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Process a project_deleted event
     * @param payload The webhook payload
     *
     * STUDENT TASK:
     * Implement logic to delete a Jira_Project__c record
     */
    private void processProjectDeleted(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            String projectKey = (String) projectData.get('key');
            
            // Find and delete existing project
            List<Jira_Project__c> existingProjects = [
                SELECT Id, Project_Key__c
                FROM Jira_Project__c 
                WHERE Project_Key__c = :projectKey WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            if (!existingProjects.isEmpty()) {
                delete as system existingProjects;
            }
            
        } catch (Exception ex) {
            Logger.debug('Error processing project_deleted event: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new WebhookProcessingException(ex.getMessage());
        }
    }
    
    /**
     * @description Create a Jira_Issue__c record from issue data
     * @param issueData The issue data from the webhook
     * @return Jira_Issue__c The newly created issue record
     *
     * STUDENT TASK:
     * Implement logic to extract issue fields and create a record
     *
     * HINT:
     * 1. Extract data from the issueData map (key, summary, status, etc.)
     * 2. Map the fields to a new Jira_Issue__c record
     */
    private Jira_Issue__c createIssueRecord(Map<String, Object> issueData) {
        String issueKey = (String) issueData.get('key');
        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        
        if (fields == null) {
            fields = new Map<String, Object>();
        }
        
        String summary = (String) fields.get('summary');
        String description = (String) fields.get('description');
        
        // Extract status
        Map<String, Object> statusObj = (Map<String, Object>) fields.get('status');
        String status = statusObj != null ? (String) statusObj.get('name') : null;
        
        // Extract issue type
        Map<String, Object> issueTypeObj = (Map<String, Object>) fields.get('issuetype');
        String issueType = issueTypeObj != null ? (String) issueTypeObj.get('name') : null;
        
        // Extract project key
        Map<String, Object> projectObj = (Map<String, Object>) fields.get('project');
        String projectKey = projectObj != null ? (String) projectObj.get('key') : null;
        
        Jira_Issue__c issue = new Jira_Issue__c(
            Issue_Key__c = issueKey,
        Summary__c = summary,
        Description__c = description,
        Status__c = status,
        Issue_Type__c = issueType,
        Project_Key__c = projectKey,
        Last_Updated__c = Datetime.now()
            );
        
        return issue;
    }
    
    /**
     * @description Update a Jira_Issue__c record from issue data
     * @param existingIssue The existing issue record
     * @param issueData The updated issue data from the webhook
     * @return Jira_Issue__c The updated issue record
     *
     * STUDENT TASK:
     * Implement logic to extract issue fields and update a record
     */
    private Jira_Issue__c updateIssueRecord(Jira_Issue__c existingIssue, Map<String, Object> issueData) {
        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        
        if (fields == null) {
            fields = new Map<String, Object>();
        }
        
        String summary = (String) fields.get('summary');
        String description = (String) fields.get('description');
        
        // Extract status
        Map<String, Object> statusObj = (Map<String, Object>) fields.get('status');
        String status = statusObj != null ? (String) statusObj.get('name') : null;
        
        // Extract issue type
        Map<String, Object> issueTypeObj = (Map<String, Object>) fields.get('issuetype');
        String issueType = issueTypeObj != null ? (String) issueTypeObj.get('name') : null;
        
        // Extract project key
        Map<String, Object> projectObj = (Map<String, Object>) fields.get('project');
        String projectKey = projectObj != null ? (String) projectObj.get('key') : null;
        
        // Update fields
        if (summary != null) {
            existingIssue.Summary__c = summary;
        }
        if (description != null) {
            existingIssue.Description__c = description;
        }
        if (status != null) {
            existingIssue.Status__c = status;
        }
        if (issueType != null) {
            existingIssue.Issue_Type__c = issueType;
        }
        if (projectKey != null) {
            existingIssue.Project_Key__c = projectKey;
        }
        
        existingIssue.Last_Updated__c = Datetime.now();
        
        return existingIssue;
    }
    
    /**
     * @description Create a Jira_Project__c record from project data
     * @param projectData The project data from the webhook
     * @return Jira_Project__c The newly created project record
     *
     * STUDENT TASK:
     * Implement logic to extract project fields and create a record
     */
    private Jira_Project__c createProjectRecord(Map<String, Object> projectData) {
        String projectKey = (String) projectData.get('key');
        String projectName = (String) projectData.get('name');
        String description = (String) projectData.get('description');
        String projectId = String.valueOf(projectData.get('id'));
        
        Jira_Project__c project = new Jira_Project__c(
            Project_Key__c = projectKey,
        Project_Name__c = projectName,
        Description__c = description,
        Project_ID__c = projectId
            );
        
        return project;
    }
    
    /**
     * @description Update a Jira_Project__c record from project data
     * @param existingProject The existing project record
     * @param projectData The updated project data from the webhook
     * @return Jira_Project__c The updated project record
     *
     * STUDENT TASK:
     * Implement logic to extract project fields and update a record
     */
    private Jira_Project__c updateProjectRecord(Jira_Project__c existingProject, Map<String, Object> projectData) {
        String projectName = (String) projectData.get('name');
        String description = (String) projectData.get('description');
        String projectId = String.valueOf(projectData.get('id'));
        
        // Update fields
        if (projectName != null) {
            existingProject.Project_Name__c = projectName;
        }
        if (description != null) {
            existingProject.Description__c = description;
        }
        if (projectId != null && projectId != 'null') {
            existingProject.Project_ID__c = projectId;
        }
        
        return existingProject;
    }
}