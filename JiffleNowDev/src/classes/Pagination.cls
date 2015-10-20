public with sharing class Pagination {
    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                size = 4;
                string queryString = 'Select Name, Object_Label__c, Field_API_Name__c, Field_Label__c, Enabled__c from MappingObject__c order by Name';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }
     
    Public List<MappingObject__c> getMappingObjects(){
        List<MappingObject__c> MOList = new List<MappingObject__c>();
        for(MappingObject__c m : (List<MappingObject__c>)setCon.getRecords())
            MOList.add(m);
        return MOList;
    }
     
    public pageReference refresh() {
        setCon = null;
        getMappingObjects();
        setCon.setPageNumber(1);
        return null;
    }
     
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
  
    public void first() {
        setCon.first();
    }
  
    public void last() {
        setCon.last();
    }
  
    public void previous() {
        setCon.previous();
    }
  
    public void next() {
        setCon.next();
    }
    public PageReference Redirect(){
        PageReference send = new PageReference('/'+'apex/CreateEditPage');
        send.setRedirect(true);
        return send;
    }
}