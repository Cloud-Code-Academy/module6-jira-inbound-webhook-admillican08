/**
 * Service class for making callouts to the Jira API
 */
public with sharing class JiraAPIService {
    /**
     * Creates a project in Jira
     * @param projectWrapper The project wrapper object containing all necessary data
     * @return String The Jira project ID
     *
     * Reminder: Extract and return the project ID from the response
     */
    public static String createProject(JiraWrapper.ProjectWrapper projectWrapper) {
        try {
            Map<String, Object> payload = new Map<String, Object>{
                'name' => projectWrapper.name,
                'key' => projectWrapper.key,
                'description' => projectWrapper.description,
                'leadAccountId' => projectWrapper.leadAccountId,
                'projectTemplateKey' => projectWrapper.projectTemplateKey,
                'projectTypeKey' => 'software',
                'assigneeType' => 'PROJECT_LEAD'
            };
            
            // Make the HTTP callout
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:JiraNamedCredential' + '/project');
            request.setMethod('POST');
            request.setBody(JSON.serialize(payload));
            HttpResponse resp = http.send(request);
            ApiResponse apiResponse = new ApiResponse(resp);
            if(apiResponse.isSuccess){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.body);
                return String.valueOf(responseMap.get('id'));
            } else {
                Logger.debug('Error returned in API response: ' + apiResponse.responseMsg);
                Logger.saveLog();
                return null;
            }
        } catch (Exception ex) {
            Logger.debug('Error in JiraAPIService.createProject(): ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new JiraProcessingException('Error creating Jira project: ' + ex.getMessage());
        }
    }
    
    /**
     * Creates an issue in Jira
     * @param issueWrapper The issue wrapper object containing all necessary data
     * @return String The Jira issue key
     *
     * Reminder: Extract and return the issue key from the response
     */
    public static String createIssue(JiraWrapper.IssueWrapper issueWrapper) {
        try {
            Map<String, Object> payload = issueWrapper.generateIssuePayloadMap();
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:JiraNamedCredential' + '/issue');
            request.setMethod('POST');
            request.setBody(JSON.serialize(payload));
            HttpResponse resp = http.send(request);
            ApiResponse apiResponse = new ApiResponse(resp);
            if(apiResponse.isSuccess){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.body);
                return (String) responseMap.get('key');
            } else {
                Logger.debug('Error returned in API response: ' + apiResponse.responseMsg);
                Logger.saveLog();
                return null;
            }
        } catch (Exception ex) {
            Logger.debug('Error in JiraAPIService.createIssue(): ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            throw new JiraProcessingException('Error creating Jira issue: ' + ex.getMessage());
        }
    }
}