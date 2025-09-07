/**
 * Trigger for Jira_Project__c to create projects in Jira
 */
trigger JiraProjectTrigger on Jira_Project__c(before insert, after insert) {
	// Process before insert events
	if (Trigger.isBefore && Trigger.isInsert) {
		JiraTriggerHelper.processProjectBeforeInsert(Trigger.new);
	}
	
	// Prevent recursive triggers if needed
	// Process after insert events
	if (Trigger.isAfter && Trigger.isInsert) {
		JiraTriggerHelper.processProjectAfterInsert(Trigger.new);
	}
}