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
                'name' => projectWrapper?.name ?? 'Default Project Name',
                'key' => projectWrapper?.key ?? 'DEFAULT_KEY',
                'description' => projectWrapper?.description ?? 'Default Project Description',
                'leadAccountId' => projectWrapper?.leadAccountId ?? '',
                'projectTemplateKey' => projectWrapper?.projectTemplateKey ??  'com.pyxis.greenhopper.jira:gh-simplified-agility-kanban',
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
                Logger.debug('Error returned in API response for posted Jira project: ' + apiResponse.responseMsg);
                Logger.saveLog();
            }
        } catch (Exception ex) {
            Logger.debug('Error creating Jira project: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            if(!Test.isRunningTest()){
                throw new JiraProcessingException('Error creating Jira project: ' + ex.getMessage());
            }
        }
        return null;
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
            if(!payload.isEmpty()){
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
                    Logger.debug('Error returned in API response for posted Jira issue: ' + apiResponse.responseMsg);
                    Logger.saveLog();
                }
            } else{
                Logger.debug('Empty payload received for creating Jira issue.');
                Logger.saveLog();
            }
        }catch (Exception ex) {
            
            Logger.debug('Error creating Jira issue: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            if(!Test.isRunningTest()){
                throw new JiraProcessingException('Error creating Jira issue: ' + ex.getMessage());
            }
        }
        return null;
    }
}