@isTest(SeeAllData=true)
private class JNEventMeetingListTest {

    static testMethod void myUnitTest() {
        Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
        JNReqRespWC.EventListResp eventlist = new JNReqRespWC.EventListResp();
        eventlist = JNEventMeetingList.getEventList('hello', 'hi','optyid','optyname');
        Http ht = new Http();
        System.assertEquals(true, eventlist!=null);
        //System.assertEquals(200, res.getStatusCode());
        
        //JNReqRespWC.MeetingListResp meetinglist = new JNReqRespWC.MeetingListResp();
        string meetinglist = JNEventMeetingList.getMeetingListdb('TestEvent', 'search');
        //Http ht = new Http();
        System.assertEquals(true, meetinglist!=null);
        
        //eventlist = new JNReqRespWC.EventListResp();
        string evntlist = JNEventMeetingList.doJNPost('Test URL for POST Method');
        System.assertEquals(true, eventlist!=null);
        eventlist = new JNReqRespWC.EventListResp();
        eventlist = JNEventMeetingList.doJNPostObj('TestUrl');
        
        JNEventMeetingList jn = new JNEventMeetingList();
        jn.chkconfigsettings();     
        
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
        //menu = JNEventMeetingList.getMenuList();
        menu = JNEventMeetingList.getMenuList(acc.Id,acc.Name,opp.Id,opp.Name);
        System.assertEquals(true, menu != null);
        string res;
        res = JNEventMeetingList.callJNMethod('HI', 'Hello', '');
        System.assertEquals(true, res != null);
        system.Test.stopTest();        
    }    
}