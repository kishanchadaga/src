public with sharing class JNUtilClass {
    
    public Blob cryptoKey{get;set;}
    public JNSettings__c jnSettings{get;set;}
    public JNUtilClass()
    {
        try{
            jnSettings=[select id,JNAccess_Token__c,JNClient_ID__c,JNClient_Secret__c,JNCryptoKey__c,JNEndpoint_URL__c,JNRedirect_URL__c,JNRefresh_Token__c,JNUser_ID__c from JNSettings__c limit 1];
            if(jnSettings!=null)
            {
                cryptoKey=EncodingUtil.base64Decode(jnSettings.JNCryptoKey__c);
            }
        }catch(Exception e){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
        }   
    }
    
    public String createCryptoKey()
    {
        cryptoKey = Crypto.generateAesKey(256);
        return EncodingUtil.base64Encode(cryptoKey);
    }
    
    public String encryptToken(String tokentext)
    {
        
        // Generate the data to be encrypted.
        Blob data = Blob.valueOf(tokentext);
        // Encrypt the data and have Salesforce.com generate the initialization vector
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
        return EncodingUtil.base64Encode(encryptedData);
        
    }
    
    public String decryptToken(String tokentext)
    
    {   Blob data =  EncodingUtil.base64Decode(tokentext);
        // Decrypt the data - the first 16 bytes contain the initialization vector
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey,data);
        // Decode the decrypted data for subsequent use
        return decryptedData.toString();
    }
    
   /* public static Httprequest JNBuildHTTPReq(string url, boolean refreshFlag){
        JNSettings__c cs = JNSettings__c.getInstance('JNSettings');
        Httprequest req = new Httprequest();       
        JNOauthController auth = new JNOauthController();
        string uid = cs.JNUser_ID__c;
        //string baseURL = System.Label.JNAPIBaseUrl;
        string baseURL = cs.JNEndpoint_URL__c;
        string email = cs.JNAdmin_Test_email__c;        
        string url2 = url;
        //string accessToken = '?access_token='+cs.JNAccess_Token__c;
        string accessToken = auth.getAccessToken(refreshFlag);
		string edurl = baseURL+url2;
        System.debug('baseURL'+baseURL+'--'+accessToken+'--'+edurl);		
        req.setEndpoint(edurl);
        req.setMethod('GET');
        req.setHeader('X-Integration-User-ID', uid);
        req.setHeader('Authorization', 'Bearer '+accessToken);
        //req.setHeader('X-SFDC-User-ID', 'PM2@jifflenow.net');
        String emailAddress = UserInfo.getUserEmail();
        /*if(emailAddress.contains('tugboat')){
            req.setHeader('X-SFDC-User-ID', Label.JNUserEmail);
        }
        else{
            req.setHeader('X-SFDC-User-ID', emailAddress);
        } //Comment here if necessary
        id id1 = userinfo.getProfileId();
        Profile pro = new Profile();
        pro = [SELECT Name FROM Profile WHERE Id =:id1 LIMIT 1];
        String userProfile = pro.Name;
        System.debug('PROFILE '+userProfile);
        if(userProfile.contains('Administrator')){
            req.setHeader('X-SFDC-User-ID', email);
        }
        else{
            req.setHeader('X-SFDC-User-ID', emailAddress);
        }       
        return req;
    }*/
    
    public static Httpresponse JNsendReq(string methodtype, string url, string querystr){
        JNSettings__c cs = JNSettings__c.getInstance('JNSettings');
        Http ht = new Http();
        Httprequest req = new Httprequest();
        Httpresponse res = new Httpresponse();
        JNOauthController auth = new JNOauthController();
        string uid = cs.JNUser_ID__c;
        string accessToken;
        string email;
        string APIUrl;
        //APIUrl = auth.getEndURL();
        //email = auth.getEmailId();
        APIUrl = cs.JNEndpoint_URL__c;
        email = cs.JNAdmin_Test_email__c;
        accessToken = auth.getAccessToken(false);
        string edurl = APIUrl+url;
        req.setMethod(methodtype);
        req.setHeader('X-Integration-User-ID', uid);
        req.setHeader('Authorization', 'Bearer '+accessToken);
		id id1 = userinfo.getProfileId();
        Profile pro = new Profile();
        pro = [SELECT Name FROM Profile WHERE Id =:id1 LIMIT 1];
        String userProfile = pro.Name;
        String emailAddress = UserInfo.getUserEmail();
        System.debug('PROFILE '+userProfile);
        if(userProfile.contains('Administrator')){
            req.setHeader('X-SFDC-User-ID', email);
        }
        else{
            req.setHeader('X-SFDC-User-ID', emailAddress);
        }
        if(methodtype == 'GET'){
            if(querystr != null && querystr != ''){
            	edurl = edurl + '?' + querystr;
            }
        }
        req.setEndpoint(edurl);
        try {
            res = ht.send(req);
            if(res.getStatusCode() == 401){
            	req.setTimeout(2 * 60 * 1000);
               accessToken = auth.getAccessToken(true);
               req.setHeader('Authorization', 'Bearer '+accessToken);
               res = ht.send(req);
            }

        } catch(System.CalloutException e) {
            System.debug('Event API Callout error: '+ e);
        }
        system.debug('Request'+req);
        system.debug('Response'+res.getBody());
        return res;
    }
    
	public static Httpresponse JNsendPost(string url){
        JNSettings__c cs = JNSettings__c.getInstance('JNSettings');
        Http ht = new Http();
        Httprequest req = new Httprequest();
        Httpresponse res = new Httpresponse();
        JNOauthController auth = new JNOauthController();
        string uid = cs.JNUser_ID__c;
        string accessToken;
        string email;
        email = cs.JNAdmin_Test_email__c;
        accessToken = auth.getAccessToken(false);
        string edurl = url;
        req.setMethod('POST');
        req.setHeader('X-Integration-User-ID', uid);
        req.setHeader('Authorization', 'Bearer '+accessToken);
	id id1 = userinfo.getProfileId();
        Profile pro = new Profile();
        pro = [SELECT Name FROM Profile WHERE Id =:id1 LIMIT 1];
        String userProfile = pro.Name;
        String emailAddress = UserInfo.getUserEmail();
        System.debug('PROFILE '+userProfile);
        if(userProfile.contains('Administrator')){
            req.setHeader('X-SFDC-User-ID', email);
        }
        else{
            req.setHeader('X-SFDC-User-ID', emailAddress);
        }
        req.setEndpoint(edurl);
        try {
            res = ht.send(req);
            if(res.getStatusCode() == 401){
            	req.setTimeout(2 * 60 * 1000);
               accessToken = auth.getAccessToken(true);
               req.setHeader('Authorization', 'Bearer '+accessToken);
               res = ht.send(req);
            }

        } catch(System.CalloutException e) {
            System.debug('Event API Callout error: '+ e);
        }
        system.debug('Request'+req);
        system.debug('Response'+res.getBody());
        return res;
    }
    public static Httpresponse JNPost(string url, string body){
        JNSettings__c cs = JNSettings__c.getInstance('JNSettings');
        Http ht = new Http();
        Httprequest req = new Httprequest();
        Httpresponse res = new Httpresponse();
        JNOauthController auth = new JNOauthController();
        string uid = cs.JNUser_ID__c;
        string accessToken;
        string email;
        string APIUrl;
        //APIUrl = auth.getEndURL();
        //email = auth.getEmailId();
        APIUrl = cs.JNEndpoint_URL__c;
        email = cs.JNAdmin_Test_email__c;
        accessToken = auth.getAccessToken(false);
        string edurl = APIUrl+url;
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('X-Integration-User-ID', uid);
        req.setHeader('Authorization', 'Bearer '+accessToken);
		id id1 = userinfo.getProfileId();
        Profile pro = new Profile();
        pro = [SELECT Name FROM Profile WHERE Id =:id1 LIMIT 1];
        String userProfile = pro.Name;
        String emailAddress = UserInfo.getUserEmail();
        System.debug('PROFILE '+userProfile);
        if(userProfile.contains('Administrator')){
            req.setHeader('X-SFDC-User-ID', email);
        }
        else{
            req.setHeader('X-SFDC-User-ID', emailAddress);
        }
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(edurl);
        try {
            res = ht.send(req);
            if(res.getStatusCode() == 401){
            	req.setTimeout(2 * 60 * 1000);
                accessToken = auth.getAccessToken(true);
                req.setHeader('Authorization', 'Bearer '+accessToken);
                res = ht.send(req);
            }

        } catch(System.CalloutException e) {
            System.debug('Event API Callout error: '+ e);
        }
        system.debug('Request'+req);
        system.debug('Response'+res.getBody());
        return res;
    }
}