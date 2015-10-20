@isTest
public class JNOauthControllerTest {
    
    
    static testmethod void oauthtest(){
        insert new JNSettings__c(name = 'JNSettings',JNEndpoint_URL__c='https://tugboat-testing.jifflenow.com/api',JNoAuthEndpoint_URL__c='https://tugboat-testing.jifflenow.com/api/oauth',JNCryptoKey__c='bWbuwlbfhp9Ptlc3yz9ivJCGfIJs1cdkvREA1Mq6qlU=',JNAdmin_Test_email__c='demo@demo.com');
        Test.startTest();
        //Creating object for JNOauthControoller
        JNOauthController jnOauth=new JNOauthController();
        
        
        System.currentPageReference().getParameters().put('code', 'testcode');
        System.currentPageReference().getParameters().put('error', 'testcode');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        jnOauth.checkTokenRequest();
        
        jnOauth.getAccessToken(false);
        jnOauth.getAccessToken(true); 
        
        jnOauth.initAuth();
        jnOauth.jnSettings.JNEndpoint_URL__c='goggle';
        jnOauth.initAuth();
        
        jnOauth.doCancel();
        jnOauth.chgToedit();
        jnOauth.getEmailId();
        jnOauth.getEndURL();
        
        
    }
}