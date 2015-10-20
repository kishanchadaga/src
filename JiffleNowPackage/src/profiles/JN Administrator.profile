<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <applicationVisibilities>
        <application>Jifflenow</application>
        <default>true</default>
        <visible>true</visible>
    </applicationVisibilities>
    <classAccesses>
        <apexClass>JNBookMeeting</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNBookMeetingTest</apexClass>
        <enabled>false</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNEventMeetingList</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNEventMeetingListTest</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNOauthController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNOauthControllerTest</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNReqRespWC</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNUtilClass</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>JNUtilClassTest</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>MockHttpResponseGenerator</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>MockResposeHttp</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Attendee_Email__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Attendee_First_Name__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Attendee_Last_Name__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Attendee_UUID__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Company__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Country__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Mobile__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Attendee__c.Title__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_Code__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_End_Date__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_Location__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_Start_Date__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_Status__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Event__c.Event_UUID__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Attendee_Status__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Attendee__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Comments__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Company__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Contact_Sync__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Contact_Type__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Contact__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Is_Meeting_Requestor__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Invites__c.Meeting_Objective__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Invites__c.Meeting__c</field>
        <hidden>true</hidden>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting_Relations__c.Account__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Meeting_Relations__c.Event__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Meeting_Relations__c.Meeting_Location__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Meeting_Relations__c.Meeting__c</field>
        <hidden>true</hidden>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting_Relations__c.Opportunity__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Meeting_Relations__c.Request_Status__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting_Relations__c.Unique_Name__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Additional_Info__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.End_Date_Time__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>false</editable>
        <field>Meeting__c.Event__c</field>
        <hidden>true</hidden>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Meeting_ID__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Meeting_Location__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Meeting_Type__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Meeting_UUID__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Meeting_with__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Request_Status__c</field>
    </fieldLevelSecurities>
    <fieldLevelSecurities>
        <editable>true</editable>
        <field>Meeting__c.Start_Date_Time__c</field>
    </fieldLevelSecurities>
    <layoutAssignments>
        <layout>Account-Account Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Asset-Asset Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Attendee__c-Attendee Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Campaign-Campaign Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>CampaignMember-Campaign Member Page Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Case-Case Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>CaseClose-Close Case Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>CaseInteraction-Case Feed Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Contact-Contact Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>ContentVersion-General</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Contract-Contract Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>DandBCompany-D%26B Company Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>DuplicateRecordSet-Duplicate Record Set Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Event-Event Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Event__c-JN Event Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Goal-Goal Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>GoalLink-Goal Link Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Idea-Idea Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Invites__c-Invite Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>JobTracker-Job Tracker Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Lead-Lead Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Macro-Macro Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Meeting_Relations__c-Meeting Relations Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Meeting__c-Meeting Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Metric-Completion Metric Layout</layout>
        <recordType>Metric.Completion</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Metric-Metric Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Metric-Metric Layout</layout>
        <recordType>Metric.Progress</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>MetricDataLink-Metric Data Link Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-JN Opportunity Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>OpportunityLineItem-Opportunity Product Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Order-Order Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>OrderItem-Order Product Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Pricebook2-Price Book Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>PricebookEntry-Price Book Entry Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Product2-Product Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>SOSSession-SOS Session Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>SOSSessionActivity-SOS Session Activity Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Solution-Solution Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Task-Task Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>User-User Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>UserProvAccount-User Provisioning Account Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>UserProvisioningLog-User Provisioning Log Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>UserProvisioningRequest-User Provisioning Request Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkCoaching-Coaching Layout 194</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkFeedback-Feedback Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkFeedbackQuestion-Feedback Question Layout - Summer %2715</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkFeedbackQuestionSet-Feedback Question Set Layout - Summer %2715</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkFeedbackRequest-Feedback Request Layout - Summer %2715</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkFeedbackTemplate-Feedback Template Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>WorkPerformanceCycle-Performance Cycle Layout - Summer %2715</layout>
    </layoutAssignments>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Attendee__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Event__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Invites__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Meeting_Relations__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Meeting__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <pageAccesses>
        <apexPage>JNBookMeeting</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
    <pageAccesses>
        <apexPage>JNCreateMeetings</apexPage>
        <enabled>false</enabled>
    </pageAccesses>
    <pageAccesses>
        <apexPage>JNEvents</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
    <pageAccesses>
        <apexPage>JNMeetings</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
    <pageAccesses>
        <apexPage>JNOAuth</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
</Profile>
