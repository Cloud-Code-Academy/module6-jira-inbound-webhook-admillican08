/**
 * Trigger for Jira_Issue__c to create issues in Jira
 */
trigger JiraIssueTrigger on Jira_Issue__c(after insert) {
	// Process after insert events
	if (Trigger.isAfter && Trigger.isInsert) {
		JiraTriggerHelper.processIssueAfterInsert(Trigger.new);
	}
}