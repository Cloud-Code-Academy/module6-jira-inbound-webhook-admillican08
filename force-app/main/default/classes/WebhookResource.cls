/**
 * @description REST resource to handle incoming webhooks from various systems
 * Current implementation supports Jira webhooks at /webhook/jira
 *
 * STUDENT TASK:
 * Complete the doPost method implementation to process incoming webhooks
 *
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 *
 * @author Student Name
 */
@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
    
    /**
     * @description Handles POST requests from webhooks
     * @return Returns a simple success response
     *
     * STUDENT TASK:
     * Implement this method to:
     * 1. Get the REST request and response objects
     * 2. Extract the webhook type from the URL path using getWebhookTypeFromPath
     * 3. Process the webhook using WebhookFactory.processWebhook
     * 4. Return an appropriate ResponseWrapper
     * 5. Add error handling using try-catch
     */
    @HttpPost
    global static ResponseWrapper doPost() {
        try {
            RestRequest request = RestContext.request;
            RestResponse response = RestContext.response;
            
            String webhookType = getWebhookTypeFromPath(request.requestURI);
            
            if (String.isBlank(webhookType)) {
                response.statusCode = 400;
                return new ResponseWrapper('error', 'Invalid webhook type');
            }
            
            WebhookFactory.processWebhook(webhookType, request);
            
            response.statusCode = 200;
            return new ResponseWrapper('success', 'Webhook processed successfully');
            
        } catch (WebhookFactory.WebhookException we) {
            RestContext.response.statusCode = 400;
            Logger.debug('Webhook processing error: ' + we.getMessage() + '; ' + we.getStackTraceString());
            Logger.saveLog();
            return new ResponseWrapper('error', 'Webhook processing failed: ' + we.getMessage());
        } catch (Exception ex) {
            RestContext.response.statusCode = 500;
            Logger.debug('Unexpected error in webhook processing: ' + ex.getMessage() + '; ' + ex.getStackTraceString());
            Logger.saveLog();
            return new ResponseWrapper('error', 'Internal server error');
        }
    }
    
    /**
     * @description Extracts the webhook type from the URL path
     * @param path The request URI
     * @return The webhook type (e.g., "jira")
     */
    private static String getWebhookTypeFromPath(String path) {
        if (path == null) {
            return '';
        }
        
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            String remaining = path.substring(webhookIndex + 9);
            
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            
            return remaining.toLowerCase();
        }
        
        return '';
    }
    
    /**
     * @description Response wrapper class for consistent response format
     */
    global class ResponseWrapper {
        public String status;
        public String message;
        
        public ResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
}