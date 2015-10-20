public with sharing class JNMappingList{
    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    public string EnableId{get;set;}
    public boolean disflg {get;set;}
    public List<Mapping__c> updlst;
     public List<Mapping__c> dellst;
    public ApexPages.StandardSetController setCon {
        
        get{
            if(setCon == null){
               disflg = true; 
               List<Mapping__c> updlst= new List<Mapping__c>();
               List<Mapping__c> dellst= new List<Mapping__c>();
                size = 10;
                string queryString = 'Select Name, Enabled__c, Field_API_Name__c, Field_Label__c, Field_Type__c,Mapping_UUID__c,Object_API_Name__c,Object_Label__c,Unique_Key__c from Mapping__c order by Object_Label__c';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(size);
         
                noOfRecords = setCon.getResultSize();
                system.debug('BBBB'+noOfRecords);
                Initialload();
                if (noOfRecords > 0){
                    disflg = false;
                    Initialload();
                }
                else{
                	
                	disflg = true;
                	system.debug('IAMHERE' +disflg);
                
                }
            }
            return setCon;
        }set;
    }
    
    public void Initialload(){
       
        if(disflg == false){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Use "Add Mapping" button to add new objects/fields to the jifflenow Mapping List.'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Use Enable|Disable|Del Links to edit/remove field mapping.'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Use "Send to Jifflenow" button to synch the list with jifflenow app once objects/fields Mapping is complete.'));                
        }
        //return null;
    }     
    public List<Mapping__c> getMappings(){
        List<Mapping__c> MList = new List<Mapping__c>();
        for(Mapping__c m : (List<Mapping__c>)setCon.getRecords())
            MList.add(m);
        return MList;
    }
     
    public pageReference refresh() {
        setCon = null;
        getMappings();
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
        PageReference send = new PageReference('/'+'apex/JNMappings');
        send.setRedirect(true);
        return send;
    }
    public PageReference EnableRecord(){
    system.debug('AAAAAA'+EnableId);
    updlst= new List<Mapping__c>();
    updlst.add(new Mapping__c(Id=EnableId,Enabled__c=true));
    update updlst;
    PageReference pg = new PageReference('/'+'apex/JNMappingList');
    pg.setRedirect(true);
    return pg;
    //return null;
    //getMappings();
    }
    public PageReference DisableRecord(){
    system.debug('BBBBBBBB'+EnableId);
    updlst= new List<Mapping__c>();
    updlst.add(new Mapping__c(Id=EnableId,Enabled__c=false));
    update updlst;
    PageReference pg = new PageReference('/'+'apex/JNMappingList');
    pg.setRedirect(true);
    return pg;
    //getMappings();
    }
    public PageReference DeleteRecord(){
    system.debug('CCCCCCC'+EnableId);
    dellst=[select Name, Enabled__c, Field_API_Name__c, Field_Label__c, Field_Type__c,Mapping_UUID__c,Object_API_Name__c,Object_Label__c,Unique_Key__c from Mapping__c where ID =:EnableId];
    delete dellst;
    PageReference pg = new PageReference('/'+'apex/JNMappingList');
    pg.setRedirect(true);
    return pg;
    }
    
    public Pagereference JNSend(){
        Httpresponse res = new Httpresponse();
        JNReqRespWC.fieldData sfdcInti = new JNReqRespWC.fieldData();
        sfdcInti.api_params = new JNReqRespWC.paramsWrap();
        sfdcInti.api_params.integration_fields = new list<JNReqRespWC.fieldswrap>();
        JNReqRespWC.fieldswrap inte;
        List<Mapping__c> MList = new List<Mapping__c>();
        for(Mapping__c m : (List<Mapping__c>)setCon.getRecords()){
            MList.add(m);
        }
        for(Mapping__c m:MList){
            if(m.Enabled__c){
                inte = new JNReqRespWC.fieldswrap();
                inte.name = m.Field_API_Name__c;
                inte.display_name = m.Field_Label__c;
                inte.entity_name = m.Object_Label__c;
                inte.entity_reference = m.Object_API_Name__c;
                inte.integration_type = 'SFDC';
                inte.field_type = m.Field_Type__c;
                //inte.uuid = m.Mapping_UUID__c;
                //inte.uuid = '';
                sfdcInti.api_params.integration_fields.add(inte);
            }
        }
        string resBody;
        string returnval = JSON.serialize(sfdcInti);
        system.debug('returnval1111'+returnval );
        string endu = Label.JNFieldIntegration;
        res = JNUtilClass.JNPost(endu, returnval);
        system.debug('res2222'+res.getBody() );
        if(res.getBody() != null){
            resBody = res.getBody();
        }
        if(resBody.contains('"status":200')){
            syncMapping(resBody);
            PageReference pg = new PageReference('/'+'apex/JNMappingList');
            pg.setRedirect(true);
            return pg;
        }
        return null;
    }
    public void syncMapping(string response){
        JNReqRespWC.integration sfdcInti = new JNReqRespWC.integration();
        List<Mapping__c> MList = new List<Mapping__c>();
        Mapping__c mobj;
        sfdcInti.data = new JNReqRespWC.paramsWrap();
        sfdcInti.data.integration_fields = new list<JNReqRespWC.fieldswrap>();
        JNReqRespWC.fieldswrap inte;
        sfdcInti = (JNReqRespWC.integration) JSON.deserialize(response, JNReqRespWC.integration.class);
        system.debug('sfdcInti2222'+sfdcInti);
        for(JNReqRespWC.fieldswrap f:sfdcInti.data.integration_fields){
            mobj = new Mapping__c();
            mobj.Field_API_Name__c = f.name;
            mobj.Field_Label__c = f.display_name;
            mobj.Field_Type__c = f.field_type;
            mobj.Object_API_Name__c = f.entity_reference;
            mobj.Object_Label__c = f.entity_name;
            mobj.Unique_Key__c = f.entity_reference + f.name;
            mobj.Mapping_UUID__c = f.uuid;
            MList.add(mobj);
        }
                system.debug('MList 3333'+MList);
        if(MList != null && MList.size()>0){
            upsert MList Unique_Key__c;
        }
    }
}