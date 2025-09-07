/**
 * Helper class for Jira triggers
 */
public with sharing class JiraTriggerHelper {
    
    /**
     * Process Jira_Project__c records before insert
     * @param newProjects List of newly inserting Jira_Project__c records
     */
    public static void processProjectBeforeInsert(List<Jira_Project__c> newProjects) {
        for (Jira_Project__c project : newProjects) {
            // check for empty or invalid project key, supply valid one if needed.
            if (String.isBlank(project.Project_Key__c) || !(isKeyValid(project.Project_Key__c))) {
                project.Project_Key__c = generateUniqueProjectKey();
            }
        }
    }
    /**
     * Process Jira_Project__c records after insert
     * @param newProjects List of newly inserted Jira_Project__c records
     */
    public static void processProjectAfterInsert(List<Jira_Project__c> newProjects) {
        List<Jira_Project__c> projectsToProcess = new List<Jira_Project__c>();
        
        for (Jira_Project__c project : newProjects) {
            if (String.isBlank(project.Project_ID__c)) {
                projectsToProcess.add(project);
            }
        }
        for (Jira_Project__c project : projectsToProcess) {
            JiraCalloutQueueable callout = new JiraCalloutQueueable(
                project.Id,
            project.Project_Name__c,
            project.Project_Key__c,
            project.Description__c
                );
            if(Limits.getLimitQueueableJobs() > Limits.getQueueableJobs() && !Test.isRunningTest()){
                System.enqueueJob(callout);
            }
        }
    }
    
    /**
     * Process Jira_Issue__c records after insert
     * @param newIssues List of newly inserted Jira_Issue__c records
     *
     * The method should:
     * 1. Filter out issues that already have a Jira issue key
     * 2. Ensure the Project_Key__c field is not blank
     * 3. Create a JiraCalloutQueueable for each issue and enqueue it
     * 4. Don't enqueue if Test.isRunningTest() is true
     */
    public static void processIssueAfterInsert(List<Jira_Issue__c> newIssues) {
        List<Jira_Issue__c> issuesToProcess = new List<Jira_Issue__c>();
        
        // Filter out issues that already have a Jira issue key and ensure Project_Key__c is not blank
        for (Jira_Issue__c issue : newIssues) {
            if (String.isBlank(issue.Issue_Key__c) && String.isNotBlank(issue.Project_Key__c)) {
                issuesToProcess.add(issue);
            }
        }
        for (Jira_Issue__c issue : issuesToProcess) {
            JiraCalloutQueueable callout = new JiraCalloutQueueable(
                issue.Id,
            issue.Project_Key__c,
            issue.Summary__c,
            issue.Description__c,
            issue.Issue_Type__c
                );
            if(Limits.getLimitQueueableJobs() > Limits.getQueueableJobs() && !Test.isRunningTest()){
                System.enqueueJob(callout);
            }
        }
    }
    
    /**
     * Generate a unique 10-character alphanumeric project key
     * @return String A unique project key
     */
    private static String generateUniqueProjectKey() {
        String projectKey;
        Set<String> existingKeys = getExistingProjectKeys();
        
        do {
            projectKey = generateRandomAlphanumericString(10);
        } while (existingKeys.contains(projectKey));
        
        return projectKey;
    }
    
    /**
     * Generate a random alphanumeric string of specified length
     * @param length The length of the string to generate
     * @return String Random string with uppercase letters and numbers
     */
    private static String generateRandomAlphanumericString(Integer length) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randomString = '';
        
        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(randomIndex, randomIndex + 1);
        }
        
        return randomString;
    }
    
    /**
     * Get existing project keys from the database
     * @return Set<String> Set of existing project keys
     */
    private static Set<String> getExistingProjectKeys() {
        Set<String> existingKeys = new Set<String>();
        
        for (Jira_Project__c project : [SELECT Project_Key__c FROM Jira_Project__c WHERE Project_Key__c != null]) {
            existingKeys.add(project.Project_Key__c);
        }
        
        return existingKeys;
    }
    
    /**
     * Validate if a project key meets the required format
     * @param projectKey The project key to validate
     * @return Boolean True if the key is valid, false otherwise
     */
    private static Boolean isKeyValid(String projectKey){
        Boolean len = projectKey.length() == 10;
        if (!len) {
            return false;
        }
        else{
            String[] chars = projectKey.split('');
            for(Integer i=0; i<chars.size(); i++){
                String single = chars[i];
                if(!single.isAlphanumeric() || !(single=='_')){
                    return false;
                }
                else if(!single.isNumeric() && !(single=='_') && single.isAlpha() && !single.isAllUpperCase()){
                    return false;
                }
            }
            return true;
        }
    }
}