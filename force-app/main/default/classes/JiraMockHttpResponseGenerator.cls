/**
 * Mock HTTP response generator for Jira API integration tests
 */
@isTest
public class JiraMockHttpResponseGenerator implements HttpCalloutMock {
	// Mock response constants
	private static final String MOCK_PROJECT_ID = '10011';
	private static final String MOCK_ISSUE_KEY = 'ED-24';

	private Boolean isSuccess;
	private Boolean isProject;
	private String projectKey;

	/**
	 * Constructor
	 * @param isSuccess Whether to simulate a successful response
	 * @param isProject Whether to simulate a project or issue API call
	 */
	public JiraMockHttpResponseGenerator(Boolean isSuccess, Boolean isProject) {
		this(isSuccess, isProject, 'TP1');
	}

	/**
	 * Constructor with custom project key
	 * @param isSuccess Whether to simulate a successful response
	 * @param isProject Whether to simulate a project or issue API call
	 * @param projectKey Custom project key for the response
	 */
	public JiraMockHttpResponseGenerator(Boolean isSuccess, Boolean isProject, String projectKey) {
		this.isSuccess = isSuccess;
		this.isProject = isProject;
		this.projectKey = projectKey;
	}

	/**
	 * Get the standard mock project ID
	 */
	public static String getMockProjectId() {
		return MOCK_PROJECT_ID;
	}

	/**
	 * Get the standard mock issue key
	 */
	public static String getMockIssueKey() {
		return MOCK_ISSUE_KEY;
	}

	/**
	 * Implement the respond method
	 */
	public HttpResponse respond(HttpRequest req) {
		// Create a mock response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');

		if (isSuccess) {
			res.setStatusCode(201);

			if (isProject) {
				res.setBody(
					'{"self": "https://cloud-code.atlassian.net/rest/api/3/project/10011", "id": ' +
						MOCK_PROJECT_ID +
						', "key": "' +
						projectKey +
						'"}'
				);
			} else {
				res.setBody(
					'{"id": "10000", "key": "' +
						MOCK_ISSUE_KEY +
						'", "self": "https://your-domain.atlassian.net/rest/api/3/issue/10000", ' +
						'"transition": {"status": 200, "errorCollection": {"errorMessages": [], "errors": {}}}}'
				);
			}
		} else {
			res.setStatusCode(400);
			res.setBody('{"errorMessages":["Error creating the entity"],"errors":{}}');
		}

		return res;
	}
}