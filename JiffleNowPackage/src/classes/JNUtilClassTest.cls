@isTest
public class JNUtilClassTest {
static testmethod void utiltest(){
    insert new JNSettings__c(name = 'JNSettings',JNAccess_Token__c='2hJBXA7eKxAP0Cojnkya7J1tfmWU9sE4VAlfVNGt0UmC71NomVlR4dLvAH8jF53KEhLK61QkO1wEIBr8EwXRRCmJmKgm3ezr/H0Jn3ZjwdjmBQH2E+jAEfEImJMd0GYZ',JNClient_ID__c='84deb55ac7347e0ddbb7417f333c3563a4e5c6a6399d29a610bafa6100a066ad',JNEndpoint_URL__c='https://tugboat-testing.jifflenow.com/api/oauth',JNClient_Secret__c='8a7a4547479d50ea1ef9c8910e1dba4f50b88d01a9711362fa0a5730c8115cba',JNCryptoKey__c='bWbuwlbfhp9Ptlc3yz9ivJCGfIJs1cdkvREA1Mq6qlU=',JNUser_ID__c='d5fa1676c9f03b8d2ab2fcf35e67a1150d252396df305da673de6f2cb80b0f7@integration.tugboat.com');
    Test.startTest();
    JNUtilClass jnutil=new JNUtilClass();
    
    
    jnutil.encryptToken('testtoken');
    jnutil.decryptToken('2hJBXA7eKxAP0Cojnkya7J1tfmWU9sE4VAlfVNGt0UmC71NomVlR4dLvAH8jF53KEhLK61QkO1wEIBr8EwXRRCmJmKgm3ezr/H0Jn3ZjwdjmBQH2E+jAEfEImJMd0GYZ');
    //JNUtilClass.JNBuildHTTPReq('http://google.com', false); 
    //JNUtilClass.JNBuildHTTPPostReq('http://google.com',false);  
    //JNUtilClass.JNBuildHTTPPostReq('http://google.com',true);   
    jnutil.createCryptoKey();
    
    }
}