public with sharing class JNMappings {
	public map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public string selectedObject{get;set;}
    public string ret{get;set;}
    public list<mappingWrap> wraplst{get;set;}
    public list<SelectOption> objectNames{get;set;}
    Map<String, Schema.SObjectField> fieldMap;
	Map<String, Schema.SObjectField> fieldMapfortypes;    
    public JNMappings()
    {   
        //selectedObject = 'Account';  
         
    }

    public void ObjNames() 
    {
    	wraplst = new list<mappingWrap>(); 
        objectNames = new list<SelectOption>();
        //list*<String> entities = new list<String>(schemaMap.keySet());
        //entities.sort();
        Schema.SObjectType objtype;
        objectNames.add(new SelectOption('--None--','--None--')); 
        for(Schema.SObjectType name : ProcessInstance.TargetObjectId.getDescribe().getReferenceTo())
        {
        	//objtype = new Schema.SObjectType();
        	//objtype = schemaMap.get(name);
        	if(!name.getDescribe().CustomSetting)
            objectNames.add(new SelectOption(string.valueOf(name),name.getDescribe().getLabel()));
        }
        for(Integer i=0;i<5;i++){
			wraplst.add(new mappingWrap());
		}
     }
     public list<SelectOption> ObjectFields(string obj) 
     {
     	List<SelectOption> fieldNames;
            //Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if(obj != null && obj != '--None--'){
	            Schema.SObjectType ObjectSchema = schemaMap.get(obj);
	            fieldMap = ObjectSchema.getDescribe().fields.getMap();
	            fieldNames = new List<SelectOption>();
	            fieldNames.add(new SelectOption('--None--','--None--'));
	            for (String fieldName: fieldMap.keySet()) 
	            {  
	            	System.debug('ISPERMISSABLE '+fieldMap.get(fieldName).getDescribe().isPermissionable());
	            	System.debug('FIELDLABELS '+fieldMap.get(fieldName).getDescribe().getType()+' '+fieldName);
	            	if(fieldMap.get(fieldName).getDescribe().isPermissionable())
	                fieldNames.add(new SelectOption(fieldName,fieldMap.get(fieldName).getDescribe().getLabel()));
	              //fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
	            }
            }
            return fieldNames;     
	}
	public void populateTable(){
		wraplst = new list<mappingWrap>();
		System.debug('AAAAAAAAAAAAAAAAAA');
        Schema.SObjectType ObjSchema = schemaMap.get(selectedObject);
        fieldMapfortypes = ObjSchema.getDescribe().fields.getMap();
        			System.debug('fieldMapfortypes '+fieldMapfortypes);		
		for(Integer i=0;i<5;i++){
			System.debug('LABEL'+schemaMap.get(selectedObject).getDescribe().getLabel());
			string label = schemaMap.get(selectedObject).getDescribe().getLabel();
			//wraplst.add(new mappingWrap(selectedObject,schemaMap.get(selectedObject).getDescribe().getLabel()));
			wraplst.add(new mappingWrap(selectedObject,label));
		}
		System.debug('BBBBBBBB '+wraplst);
	}
	public void fieldstype(){
		for(mappingWrap wrap:wraplst){
			System.debug('wrap.selectedField '+fieldMapfortypes);
			string strfield = wrap.selectedField;
			System.debug('strfield '+strfield);
			if(wrap.selectedField != null && wrap.selectedField !='' && wrap.selectedField != '--None--'){
				System.debug('FIELDLABELS '+fieldMapfortypes.get(strfield).getDescribe().getType());
				ret = string.valueOf(fieldMapfortypes.get(wrap.selectedField).getDescribe().getType());
			}
			System.debug('FieldType '+ret);
		}
	}
	public string doSave(){
		Mapping__c mapobj;
		list<Mapping__c> maplst = new list<Mapping__c>();
		string errormsg = '';
		if(wraplst != null && wraplst.size()>0){
			for(mappingWrap wrap:wraplst){
				mapobj  = new Mapping__c();
				if(wrap.selectedField != null && wrap.selectedField !='' && wrap.selectedField != '--None--'){
					mapobj.Object_Label__c = wrap.objLabel;
					mapobj.Object_API_Name__c = wrap.objName;
					mapobj.Field_API_Name__c = wrap.selectedField;
					mapobj.Field_Label__c = fieldMapfortypes.get(wrap.selectedField).getDescribe().getLabel();
					mapobj.Field_Type__c = string.valueOf(fieldMapfortypes.get(wrap.selectedField).getDescribe().getType());
					mapobj.Unique_Key__c = mapobj.Object_API_Name__c + mapobj.Field_API_Name__c;
					mapobj.Enabled__c = true;
					maplst.add(mapobj);
				}
			}
			if(maplst != null && maplst.size() >0){
					errormsg  = '';
					System.debug('INSERTLIST '+maplst);
					insert maplst;  
			}
			else{
				errormsg  = 'Please select at least one field.';
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select at least one field.'));
		}
		}
		else{
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select at least one field.'));
				errormsg  = 'Please select at least one field.';
		}
		return errormsg;
	}
	
	public Pagereference justSave(){
			string returnval = doSave();
			if(returnval == ''){
				Pagereference pg = new Pagereference('/apex/JNMappingList');
				return pg;				
			}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,returnval));			
		return null;
	}
	
	public Pagereference saveAndNew(){
		string returnval = doSave();
		if(returnval == ''){
			Pagereference pg = new Pagereference('/apex/JNMappings');
			pg.setRedirect(true);
			return pg;
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,returnval));			
		return null;
	}
	
	public Pagereference doCancel(){
		Pagereference pg = new Pagereference('/apex/JNMappingList');
		return pg;
	}
	
     public class mappingWrap{
     	public JNMappings cls = new JNMappings();
     	public list<SelectOption> fieldName{get;set;}
     	public string selectedField{get;set;}
     	public string fieldType{get;set;}
     	public boolean enabled{get;set;}
     	public string objName{get;set;}
     	public string objLabel{get;set;}
     	public mappingWrap(string oName, string oLabel){ 
     		fieldName = new list<SelectOption>();
     		if(oName!='--None--')
     		fieldName = cls.ObjectFields(oName);
     		enabled = true;
     		objName = oName;
     		objLabel = oLabel;
     	}
     	public mappingWrap(){ 
     		fieldName = new list<SelectOption>();
     		fieldName.add(new Selectoption('--None--','--None--'));
     	}
     }
}