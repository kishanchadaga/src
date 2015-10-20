public with sharing class ObjectRetrieve {
	
	public string obj{get;set;}
	public List<SelectOption> options{get;set;}
	public List<SelectOption> getobjNames()
	{
		List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('--None','--None--'));
		for(Schema.SObjectType f : gd){
			options.add(new SelectOption(f.getDescribe().getLabel(),f.getDescribe().getName()));
		}
	return options;
	}
	
	public Pagereference lstfields(){
		Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
		system.debug('==>m is==>'+m);
		Schema.SObjectType s = m.get(obj) ;
		system.debug('==>Sobject Type is ==>'+s);
		Schema.DescribeSObjectResult r = s.getDescribe() ;
		system.debug('==>DescribeSObjectResult==>'+r);
		Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
		system.debug('==>fields==>'+fields);
		list<string> lstrequiredfields=new List<String>();
		options = new List<SelectOption>();
		options.add(new SelectOption('--None','--None--'));
		for(String f : fields.keyset()){
			Schema.DescribeFieldResult desribeResult = fields.get(f).getDescribe();
		    lstrequiredfields.add(f);
		}
		system.debug('==>lstrequiredfields==>'+lstrequiredfields);
		for(String f : lstrequiredfields){
			options.add(new SelectOption(f,f));
		}
	return null;
	}
}