/*
    Type:       Test Class
    Purpose:    Test Class for JNBookMeeting
    ---------------------------------------------------------------
    History:

    09-Sept-2015     Created     Jifflenow

*/
@isTest(SeeAllData=true)
private class JNBookMeetingTest {

    static testMethod void myUnitTest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        list<JNReqRespWC.sfdcAccount> sfdcacc = new list<JNReqRespWC.sfdcAccount>(); 
        list<JNReqRespWC.sfdcOpty> sfdcopty = new list<JNReqRespWC.sfdcOpty>();
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opty';
        opp.CloseDate = system.today();
        opp.StageName = 'Prospecting';
        opp.AccountId = acc.Id;
        insert opp;
        string iid = opp.Id;
        sfdcacc = JNBookMeeting.searchAccOpty('Test', '');
        System.assertEquals(true, sfdcacc != null);
        sfdcopty = JNBookMeeting.getOptyList('Test',iid);
        System.assertEquals(true, sfdcopty != null);
    } 
    
    static testMethod void myTest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        list<JNReqRespWC.sfdcAccount> sfdcacc = new list<JNReqRespWC.sfdcAccount>(); 
        list<JNReqRespWC.sfdcOpty> sfdcopty = new list<JNReqRespWC.sfdcOpty>();
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opty';
        opp.CloseDate = system.today();
        opp.StageName = 'Prospecting';
        opp.AccountId = acc.Id;
        insert opp;
        sfdcacc = JNBookMeeting.searchAccOpty('', acc.Id);
        System.assertEquals(true, sfdcacc != null);
        sfdcopty = JNBookMeeting.getOptyList('Test',opp.Id);
        System.assertEquals(true, sfdcopty != null);
        string resp = JNBookMeeting.getCalendar('even', 'query');
        System.assertEquals(true, resp != null);
    }
	static testMethod void menuitemsTest() {
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opty';
        opp.CloseDate = system.today();
        opp.StageName = 'Prospecting';
        opp.AccountId = acc.Id;
        insert opp;
        system.Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        JNReqRespWC.menuResp menu = new JNReqRespWC.menuResp();
        //menu = JNBookMeeting.getMenuList();
        menu = JNBookMeeting.getMenuList(acc.Id,acc.Name,opp.Id,opp.Name);
        System.assertEquals(true, menu != null);
        system.Test.stopTest();
    }
    static testMethod void postApiTest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        string menu;
        menu = JNBookMeeting.callJNMethod('jifflenow', Label.JNEventMeetingMenu, '');
        System.assertEquals(true, menu != null);
    }
    static testMethod void externalattest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        JNReqRespWC.externalAttendees attend = new JNReqRespWC.externalAttendees();
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Contact con = new Contact();
        con.LastName = 'TestContact';
        con.AccountId = acc.Id;
        insert con;
        attend = JNBookMeeting.getExtAtt(acc.Id, 10, 1);
        System.assertEquals(true, attend != null);
    }
        static testMethod void createMeetTest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        system.Test.startTest();
        string res;
        string req = '{"status":200,"message": "Request successful","data": {"meeting_uuid": "x34QYbpEdqxohm_9qOxYGw","meeting_id": 1,"meeting": {"id": 1,"uuid":"x34QYbpEdqxohm_9qOxYGw","start_time": "2020-01-08T08:00:00.000Z","end_time": "2020-01-08T09:00:00.000Z","status": "approved","activity": {"name": "meeting","display_name": "Meeting","enabled": true,"uuid": "1re9dU7nuuiDhbB6SRndwA","location_id": null},"meeting_with": "test_9472","custom_fields": {"meeting_oncagzsjd": "nothing124"},"creator": "BWb60OsasnSAz_EbnCglng"},"location": {"name": "Board Room","capacity": 20,"location": "","url": null,"url_desc": null,"contact_no": "","description": "","uuid": "YWkM2XeADFcvb3hfqziWQw","location_id": null},"attendee_summary": {"total": 8,"internal": {"total": 4,"pending": 2,"accepted": 1,"declined": 1},"external": {"total": 4,"pending": 3,"accepted": 1,"declined": 0}},"attendees": [{"email": "another@gmail.com","first_name": "Another","last_name": "User","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "3dAiShFqytwmr6uN0iIhRg","role": "Executive","invite_status": "pending","country": "","type": "internal","requestor": true},{"email": "john.mm@gmail.com","first_name": "John","last_name": "MM","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "BWb60OsasnSAz_EbnCglng","role": "Customer Success Manager","invite_status": "accepted","country": "","type": "external","requestor": false}]},"errors": {}}';
        res = JNBookMeeting.createMeeting('testEvent', acc.Id, '', req);
        System.assertEquals(true, res != null);
        system.Test.stopTest();
	}
}