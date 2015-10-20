/*
    Type:       Custom Controller for jn oauth 
    Purpose:    This is used for sfdc to jn oath flows.
                Has Methods access token request, authorize page launch and refrsh token.                
    Used By:    JNoauthPage
    			JNBookMeetings
                JNEventMeetingList
    ---------------------------------------------------------------
    History:

    07-Sept-2015     Created     Jifflenow

*/
public with sharing class JNOauthController {

    //Declaration
    public JNSettings__c jnSettings{get;set;}
    public JNUtilClass jutil{get;set;}
    public boolean disReadOnly {get;set;}

    //Constructor
    public JNOauthController(){
        disReadOnly = true;
        jutil=new JNUtilClass();
        try{
            jnSettings=[select id,JNAccess_Token__c,JNCryptoKey__c,JNClient_ID__c,JNAdmin_Test_email__c,JNoAuthEndpoint_URL__c,JNClient_Secret__c,JNEndpoint_URL__c,JNRedirect_URL__c,JNRefresh_Token__c,JNUser_ID__c from JNSettings__c limit 1];
        }catch(Exception e){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            jnSettings=new JNSettings__c(name='JNSettings');
            
        }   
        
    }
    
    public void checkTokenRequest()
    {
        //Retrive Code if exists
        try{
            if(ApexPages.currentPage().getParameters().get('code')!=null){      
                getToken(ApexPages.currentPage().getParameters().get('code'),false);
            }
            if(ApexPages.currentPage().getParameters().get('error')!=null){     
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'Authorization not successful'));
            }
        }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'Authorization not successful'));
        }
    }

    //Init call to get the code 
    public PageReference initAuth() {
        //disReadOnly = true;
        try{
            
            jnSettings.JNCryptoKey__c=jutil.createCryptoKey();
            upsert jnSettings;
            
            //PageReference oAuthEndPoint =new PageReference(jnSettings.JNEndpoint_URL__c+'/authorize');
            PageReference oAuthEndPoint =new PageReference(jnSettings.JNoAuthEndpoint_URL__c+'/authorize');
            //oAuthEndPoint.getParameters().put('approval_prompt', 'force');
            oAuthEndPoint.getParameters().put('client_id', jnSettings.JNClient_ID__c);
            //oAuthEndPoint.getParameters().put('scope', 'email profile');
            oAuthEndPoint.getParameters().put('response_type', 'code');
            oAuthEndPoint.getParameters().put('redirect_uri',jnSettings.JNRedirect_URL__c);
            oAuthEndPoint.setRedirect(true);
            return oAuthEndPoint;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
        }
        
        return null;
    }
    
    public string getEmailId(){
        string email = jnSettings.JNAdmin_Test_email__c;
        if(email != null && email !=''){
            return email;
        }
        else{
            return '';
        }
    }
    
    public string getEndURL(){
        string url = jnSettings.JNEndpoint_URL__c;
        if(url != null && url!= ''){
            return url;
        }
        else{
            return ''; 
        }
    }
    
    //Retrieve accesstoken and return to calling method
    public String getAccessToken(boolean refresh){
        try{
            if(refresh){
                getToken(null, true);
                return jutil.decryptToken(jnSettings.JNAccess_Token__c);
            }else{
                return jutil.decryptToken(jnSettings.JNAccess_Token__c);
            }
        }catch(Exception e){
            return null;
        }
    }
    
    
    
    //Get Accesstoken using code
    public void getToken(String code,boolean refreshtokenrequest){
        HttpResponse res = new HttpResponse();
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        //req.setEndpoint(jnSettings.JNEndpoint_URL__c+'/token');
        req.setEndpoint(jnSettings.JNoAuthEndpoint_URL__c+'/token');
        req.setMethod('POST');
        String body;
        if(!refreshtokenrequest)
             body = 'code='+code+'&grant_type=authorization_code&client_secret='+jnSettings.JNClient_Secret__c+'&redirect_uri='+jnSettings.JNRedirect_URL__c+'&client_id='+jnSettings.JNClient_ID__c;
        else
             body = 'grant_type=refresh_token&refresh_token='+jutil.decryptToken(jnSettings.JNRefresh_Token__c)+'&redirect_uri='+jnSettings.JNRedirect_URL__c;
        req.setbody(body);
        system.debug('hihello'+req+'--'+body);        
        res = http.send(req);
        system.debug('hihello'+res.getBody());
        JSONParser parser = JSON.createParser(res.getBody());
        JNResponse grp=new JNResponse();
        
        while (parser.nextToken() != null) {
            // Start at the array of Google response.
            // if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
              //  while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        grp = (JNResponse)parser.readValueAs(JNResponse.class);
                        String s = JSON.serialize(grp);
                        parser.skipChildren();
                   // }
               // }
            }
        }

        
        System.debug('Accesstoken' +grp.access_token);
        //Encrypt accesstoken
        // Generate an AES key for the purpose of this sample. 
        // Normally this key should be stored in a protected custom setting 
        // or an encrypted field on a custom object
        
        jnSettings.JNRefresh_Token__c=jutil.encryptToken(grp.refresh_token);
        jnSettings.JNAccess_Token__c=jutil.encryptToken(grp.access_token);
        
        
        try{
            update jnSettings;
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Access-Token Recieved! AccessToken::'+grp.access_token+'Dcrepted Token::'+jutil.decryptToken(jnSettings.JNAccess_Token__c)));
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
        } 
    }   
   
    public PageReference chgToedit(){

        disReadOnly = false;
        return null;
    }

    public PageReference doCancel(){
        PageReference Pg = Page.JNOAuth;
        disReadOnly = true;
        return Pg;
    }

    //Google JSON response wrapper
    public class JNResponse {
        public String access_token;
        public String token_type;
        public String expires_in;
        public String refresh_token;
    }
     
}