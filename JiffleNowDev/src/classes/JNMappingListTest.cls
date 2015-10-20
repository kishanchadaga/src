@isTest(seeAllData=true)
private class JNMappingListTest {
	static testMethod void myUnitTest(){
		Test.setMock(HttpCalloutMock.class, new MockResposeHttp());
		Mapping__c mobj = new Mapping__c();
		mobj.Enabled__c = true;
		mobj.Unique_Key__c = 'bfb6cf90-2daa-4d4c-8c40-da89af53b81d';
		insert mobj;
		Test.startTest();
		JNMappingList jn = new JNMappingList();
		Pagereference pg = Page.JNMappingList;
		Test.setCurrentPage(pg);
		
		jn.EnableId = mobj.Id;
		jn.JNSend();
		System.debug('FROMTESTCLASS '+mobj);
		jn.Initialload();
		jn.getMappings();
		jn.refresh();
		jn.next();
		jn.first();
		jn.previous();
		jn.last();
		jn.Redirect();
		list<Mapping__c> Mlist = new list<Mapping__c>();
		Mlist = [Select Name, Enabled__c, Field_API_Name__c, Field_Label__c, Field_Type__c,Mapping_UUID__c,Object_API_Name__c,Object_Label__c,Unique_Key__c from Mapping__c order by Object_Label__c]; 
		System.assertEquals(true, Mlist.size()>0);   
		Test.stopTest();
	}
}