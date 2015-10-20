public with sharing class GetFields {
    public Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

    public String selectedObject {get; set;}

    public String selectedField {get; set;}

    Public GetFields()
    {   
        selectedObject = 'account';
    }

    public List<SelectOption> getObjectNames() 
    {
        List<SelectOption> objNames = new List<SelectOption>();
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        Schema.SObjectType objtype;
        for(String name : entities)
        {
        	//objtype = new Schema.SObjectType();
        	objtype = schemaMap.get(name);
            objNames.add(new SelectOption(name,objtype.getDescribe().getLabel()));
        }
        return objNames;
     }

     public List<SelectOption> getObjectFields() 
     {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType ObjectSchema = schemaMap.get(selectedObject);
            Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();
            List<SelectOption> fieldNames = new List<SelectOption>();
            for (String fieldName: fieldMap.keySet()) 
            {  
                fieldNames.add(new SelectOption(fieldName,fieldMap.get(fieldName).getDescribe().getLabel()));
              //fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
            }
            return fieldNames;     
	}
	public list<MappingObject__c> getmaps(){
		list<MappingObject__c> mapps = new list<MappingObject__c>();
		mapps = [SELECT Enabled__c,Field_API_Name__c,Field_Label__c,Mapping_UUID__c,Name,Object_Label__c FROM MappingObject__c];
		return mapps;
	}
}