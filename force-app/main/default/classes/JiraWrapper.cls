/**
 * Wrapper classes for Jira entities (Project and Issue)
 */
public class JiraWrapper {
    private static final String LEAD_ACCOUNT_ID = '5de7e0c07474110e23122b6b';
    private static final String PROJECT_TEMPLATE_KEY = 'com.pyxis.greenhopper.jira:basic-software-development-template';
    
    /**
     * Wrapper for Jira Project
     */
    public class ProjectWrapper {
        public String name;
        public String key;
        public String description;
        public String leadAccountId;
        public String projectTemplateKey;
        
        /**
         * Constructor for ProjectWrapper
         */
        public ProjectWrapper(String name, String key, String description) {
            this.name = name;
            this.key = key;
            this.description = description;
            this.leadAccountId = LEAD_ACCOUNT_ID;
            this.projectTemplateKey = PROJECT_TEMPLATE_KEY;
        }
    }
    
    /**
     * Wrapper for Jira Issue
     */
    public class IssueWrapper {
        public String name;
        public String key;
        public String description;
        public String projectKey;
        public String summary;
        public String issueType;
        
        public IssueWrapper(
            String projectKey,
        String summary,
        String description,
        String issueType
        ) {
            this.projectKey = projectKey;
            this.summary = summary;
            this.description = description;
            this.issueType = (String.isNotBlank(issueType)) ? issueType : 'Task';
        }
        
        /**
         * Convert IssueWrapper to a Map for serialization
         *
         * Implement this method to create a Map that represents
         * the JSON payload needed for the Jira API. The Map should contain:
         * - fields object with project information (key)
         * - issuetype object with the issue type name
         * - summary field
         * - description field (formatted using formatDescription method)
         * - Example:
         */
        public Map<String, Object> generateIssuePayloadMap() {
            Map<String, Object> payload = new Map<String, Object>();
            Map<String, Object> fields = new Map<String, Object>();
            
            fields.put('project', new Map<String, Object>{'key' => this.projectKey});
            fields.put('issuetype', new Map<String, Object>{'name' => this.issueType});
            fields.put('summary', this.summary);
            fields.put('description', formatDescription(this.description));
            
            payload.put('fields', fields);
            
            return payload;
        }
        /**
         * Format description as per Jira Cloud API requirements
         *
         * Implement this method to format the description text
         * according to Jira Cloud API requirements.
         * - Create a Map with type="doc" and version=1
         * - Add content array with paragraph object
         * - Add text object inside paragraph content with the description
         * - Example:
         *   {
             *     "description": {
                 *       "type": "doc",
                 *       "version": 1,
                 *       "content": [
                 *         {
                     *           "type": "paragraph",
                     *           "content": [
                     *             {
                         *               "type": "text",
                         *               "text": "Order entry fails when selecting supplier."
                     *             }
                     *           ]
                 *         }
                 *       ]
             *     }
         *   }
         */
        private Map<String, Object> formatDescription(String descText) {
            Map<String, Object> description = new Map<String, Object>();
            description.put('type', 'doc');
            description.put('version', 1);
            
            Map<String, Object> textContent = new Map<String, Object>();
            textContent.put('type', 'text');
            textContent.put('text', String.isNotBlank(descText) ? descText : 'No description provided');
            Map<String, Object> paragraph = new Map<String, Object>();
            paragraph.put('type', 'paragraph');
            paragraph.put('content', new List<Object>{textContent});
            
            description.put('content', new List<Object>{paragraph});
            
            return description;
        }
    }
}