/*
    Type:       Custom Controller with remote methods
    Purpose:    This is used for Event list and Meeting List related apis         
    Used By:     JNEvents and JNMeetings VF Pages.
                 JNEventsjs and JNMeetingjs static resources
    ---------------------------------------------------------------
    History:

    09-Sept-2015     Created     Jifflenow

*/
global with sharing class JNEventMeetingList{
    public boolean displayerror {get;set;}  
  // function to check if jifflenow config setup and based on email check for jn SSO user
   public PageReference chkconfigsettings(){
   		String hostVal  = ApexPages.currentPage().getHeaders().get('Host');
    	String urlVal = Apexpages.currentPage().getUrl();
    	String newSSOURL= 'https://' + hostVal+ urlVal;

            list<JNSettings__c> jnSettingslst = new list<JNSettings__c>();
            JNReqRespWC.SSORedirect authtObj = new JNReqRespWC.SSORedirect();
            displayerror = false;
            jnSettingslst=[select id,JNAccess_Token__c,JNClient_ID__c,JNClient_Secret__c,JNCryptoKey__c,JNEndpoint_URL__c,JNRedirect_URL__c,JNRefresh_Token__c,JNUser_ID__c from JNSettings__c limit 1];            
            if(jnSettingslst!=null && jnSettingslst.size()>0)
            {
                displayerror = false;
            }       
            else
            {
                displayerror = true;
            }
            
        HttpResponse res = new HttpResponse();
        HttpRequest req = new HttpRequest();
        //string SSORedirecturl = Label.SFDCBaseURL + Label.JNEventPage;
        //string SSORedirecturl = Label.JNEventPage;
       // SSORedirecturl = SSORedirecturl+'?statusflag=1';
       if((newSSOURL!= null)&&(newSSOURL!= '')&&(newSSOURL.contains('?'))){
        	newSSOURL = newSSOURL+'&statusflag=1';
       }
       else{
       		newSSOURL = newSSOURL+'&statusflag=1';
       }
        /*string accountId = ApexPages.currentPage().getParameters().get('accid');
        string accountname = ApexPages.currentPage().getParameters().get('accname');
        string oppoid = ApexPages.currentPage().getParameters().get('oppid');
        string opponame = ApexPages.currentPage().getParameters().get('oppname');
        SSORedirecturl = (accountid != null && accountid != '')?(SSORedirecturl+'&accid'+accountId):SSORedirecturl;
        SSORedirecturl = (accountid != null && accountid != '')?(SSORedirecturl+Label.JNaccId+accountId):SSORedirecturl;
        SSORedirecturl = (accountname != null && accountname != '')?(SSORedirecturl+Label.JNaccName+accountname):SSORedirecturl;
        SSORedirecturl = (oppoid != null && oppoid != '')?(SSORedirecturl+Label.JNoppId+oppoid):SSORedirecturl;
        SSORedirecturl = (opponame != null && opponame != '')?(SSORedirecturl+Label.JNoppName+opponame):SSORedirecturl;
        System.debug('SSORedirecturl '+ SSORedirecturl);
        Http http = new Http();
        req = JNUtilClass.JNBuildHTTPReq(Label.JNEventURL,false);
        try {       
            res = http.send(req);
            if(res.getStatusCode() == 401){
                req = JNUtilClass.JNBuildHTTPReq(Label.JNEventURL,true);
                req.setTimeout(2 * 60 * 1000);
                res = http.send(req);
            }           
            
        } catch(System.CalloutException e) {
            System.debug('Event API Callout error: '+ e);
        }*/
       
        res = JNUtilClass.JNsendReq('GET', Label.JNEventURL, '');
        string eventlst = res.getBody();
         //SSORedirecturl = Encodingutil.urlEncode(SSORedirecturl+'&statusflag=1', 'UTF-8');
         System.debug('NewSSO URL:'+newSSOURL);
         newSSOURL = Encodingutil.urlEncode(newSSOURL, 'UTF-8');

         string statusflg = ApexPages.currentPage().getParameters().get('statusflag'); // used to call sso check only once on load;
         statusflg = (statusflg == null || statusflg == '')?'':statusflg;
         
         if(eventlst!=null && res.getStatusCode() == 403 && statusflg !='1' ){
//          authtObj = (JNReqRespWC.Authentication) JSON.deserialize(eventlst.replace('[URL]', SSORedirecturl), JNReqRespWC.Authentication.class);
            authtObj = (JNReqRespWC.SSORedirect) JSON.deserialize(eventlst.replace('[URL]', newSSOURL), JNReqRespWC.SSORedirect.class);
           System.debug('Aut URL:'+authtObj.data.authentication_url);
           PageReference newAuthUrl = new PageReference(authtObj.data.authentication_url);
           newAuthUrl.setRedirect(true);
           return newAuthUrl;
        }
      
    
            
            return null;
   }
  // function to make JN meetings api get meetings list from JN 
   @RemoteAction
    global static string getMeetingListdb(String evntName,String qrystringparams){
        JNReqRespWC.MeetingListResp meetnglist = new JNReqRespWC.MeetingListResp();
        HttpResponse res = new HttpResponse();
        string url = '/' + evntName + Label.JNMeetingRequest;
        res = JNUtilClass.JNsendReq('GET', url, qrystringparams);
        /*string endurl = req.getEndpoint();        
        if(qrystringparams != null && qrystringparams != ''){
            endurl = endurl +'&'+ qrystringparams;
        }
        req.setEndpoint(endurl);
        req.setHeader('Content-Type', 'application/json');
        try {       
            
            res = http.send(req);
            System.debug('Response Body'+res.getBody());
            if(res.getStatusCode() == 401){
                req = JNUtilClass.JNBuildHTTPReq(Label.JNEventURL,true);
                res = http.send(req);
            }           
            
        } catch(System.CalloutException e) {
            System.debug('Event API Callout error: '+ e);
        }*/
        string returnval;
        if(res.getBody() != null){
            //meetnglist = (JNReqRespWC.MeetingListResp)JSON.deserialize(res.getBody(), JNReqRespWC.MeetingListResp.class);
            //returnval = JSON.serialize(res.getBody());
            returnval = res.getBody();
        }
        System.debug('Serealized Response'+returnval);
        return returnval;
        }//end function
         
    //Method to get the list of events.
    @RemoteAction
    global static JNReqRespWC.EventListResp getEventList(String accountid, string accountname, string oppid, string oppname){
        JNReqRespWC.EventListResp eventlistObj = new JNReqRespWC.EventListResp();
        JNReqRespWC.EventListResp updeventlst = new JNReqRespWC.EventListResp();
        updeventlst.data = new JNReqRespWC.datawrap(); 
        updeventlst.data.events = new list <JNReqRespWC.eventswrapper>(); 
        HttpResponse res = new HttpResponse();
        //string SSORedirecturl = Label.SFDCBaseURL + Label.JNEventPage;
        res = JNUtilClass.JNsendReq('GET', Label.JNEventURL, '');
        string eventlst = res.getBody();
        System.debug('Raw Response'+eventlst);
        if(eventlst != null && eventlst != ''){
            eventlistObj = (JNReqRespWC.EventListResp) JSON.deserialize(eventlst, JNReqRespWC.EventListResp.class);
        }
        System.debug('Deserialized'+eventlistObj);
        //System.debug('Error code'+eventlistObj.errors[0]);
        list <JNReqRespWC.eventswrapper> eventlist = new list <JNReqRespWC.eventswrapper>();
        list <JNReqRespWC.eventswrapper> updeventlist = new list <JNReqRespWC.eventswrapper>();
        JNReqRespWC.eventswrapper updeventobj = new JNReqRespWC.eventswrapper();
        if(eventlistObj != null){
            eventlist = eventlistObj.data.events;
        }
        string bookmeetingurl;
        string meeturl;
        if(eventlist !=null){
            for(JNReqRespWC.eventswrapper evelst:eventlist){
                updeventobj = evelst;
                //updeventobj.event_url = Label.SFDCBaseURL + Label.JNEventsName + updeventobj.event_system_name;
                meeturl = Label.JNEventsName+updeventobj.event_system_name;
                meeturl = (accountid != null && accountid != '')?(meeturl+'&'+Label.JNaccId+accountid):meeturl;
				meeturl = (accountname != null && accountname != '')?(meeturl+Label.JNaccName+accountname):meeturl;
				meeturl = (oppid != null && oppid != '')?(meeturl+Label.JNoppId+oppid):meeturl;
				meeturl = (oppname != null && oppname != '')?(meeturl+Label.JNoppName+oppname):meeturl;
				meeturl = Encodingutil.urlEncode(meeturl, 'UTF-8');
                updeventobj.event_url = '&'+meeturl;
                //updeventobj.book_url = Label.SFDCBaseURL + Label.JNBookMeetings;
                if(updeventobj.action.key == 'SCHEDULE_ACTIVITY_ACTION'){
                       //bookmeetingurl = Label.SFDCBaseURL + Label.JNBookMeetings+updeventobj.event_system_name;
                       bookmeetingurl = Label.JNBookMeetings+updeventobj.event_system_name;
                       system.debug('bookmeetingurl'+bookmeetingurl);
                       bookmeetingurl = (accountid != null && accountid != '')?(bookmeetingurl+'&'+Label.JNaccId+accountid):bookmeetingurl;
                       bookmeetingurl = (accountname != null && accountname != '')?(bookmeetingurl+Label.JNaccName+accountname):bookmeetingurl;
                       bookmeetingurl = (oppid != null && oppid != '')?(bookmeetingurl+Label.JNoppId+oppid):bookmeetingurl;
                       bookmeetingurl = (oppname != null && oppname != '')?(bookmeetingurl+Label.JNoppName+oppname):bookmeetingurl;
                       bookmeetingurl = Encodingutil.urlEncode(bookmeetingurl, 'UTF-8');
                       updeventobj.action.url = bookmeetingurl;
                       system.debug('bookmeetingurl'+bookmeetingurl);
                 }
                updeventlist.add(updeventobj);
            }
        }
        if(updeventlist != null){
            updeventlst.data.events = updeventlist;
        }
        return updeventlst; 
    }
    // generic method to do a post call and return string  
    @RemoteAction
    global static string doJNPost(string inpurl){
        Httpresponse res = new Httpresponse();
        string everesp; 
        res = JNUtilClass.JNsendPost(inpurl);
        everesp = res.getBody();
        //if(res.getBody() != null){
            //everesp = (JNReqRespWC.EventListResp) JSON.deserialize(res.getBody(), JNReqRespWC.EventListResp.class);
        //}
        return everesp; 
    }
    // generic method to do a post call and return object                 
    @RemoteAction
    global static JNReqRespWC.EventListResp doJNPostObj(string inpurl){
        Httpresponse res = new Httpresponse();
        JNReqRespWC.EventListResp everesp = new JNReqRespWC.EventListResp(); 
        //req = JNUtilClass.JNBuildHTTPPostReq(inpurl, false);
        res = JNUtilClass.JNsendReq('POST', inpurl, '');
        if(res.getBody() != null){
            everesp = (JNReqRespWC.EventListResp) JSON.deserialize(res.getBody(), JNReqRespWC.EventListResp.class);
        }
        return everesp; 
    }    
    
    /*
    Method to load tabs
    */
    @RemoteAction
    global static JNReqRespWC.menuResp getMenuList(String accountid, string accountname, string oppid, string oppname){ 
        Httpresponse res = new Httpresponse();
        JNReqRespWC.menuResp menulistResp = new JNReqRespWC.menuResp();
        JNReqRespWC.headerElements head = new JNReqRespWC.headerElements(); 
        res = JNUtilClass.JNsendReq('GET', Label.JNEventMeetingMenu, '');
        System.debug('Response' +res.getBody());
        if(res.getBody() != null){
            menulistResp = (JNReqRespWC.menuResp) JSON.deserialize(res.getBody(), JNReqRespWC.menuResp.class);
            System.debug('FOR TEST CLASS'+menulistResp);
        }
        if(menulistResp != null){
            if(menulistResp.data.links.size()>0){
                for(JNReqRespWC.headerElements he:menulistResp.data.links){
                    if(he.name == 'Events'){
                        //he.url = Label.SFDCBaseURL + '/apex/JNEvents';
                        string linkurl = '/apex/JNEvents';
                        linkurl = (accountid != null && accountid != '')?(linkurl+'?'+Label.JNaccId+accountid):linkurl;
                        linkurl = (accountname != null && accountname != '')?(linkurl+Label.JNaccName+accountname):linkurl;
                        linkurl = (oppid != null && oppid != '')?(linkurl+Label.JNoppId+oppid):linkurl;
                        linkurl = (oppname != null && oppname != '')?(linkurl+Label.JNoppName+oppname):linkurl;
                        linkurl = Encodingutil.urlEncode(linkurl, 'UTF-8');
                        he.url = linkurl;
                    }
                    else{
                        //he.url = Label.SFDCBaseURL + Label.JNEventsName + he.event_system_name;
                        string linkurl = Label.JNEventsName + he.event_system_name;
                        linkurl = (accountid != null && accountid != '')?(linkurl+'&'+Label.JNaccId+accountid):linkurl;
                        linkurl = (accountname != null && accountname != '')?(linkurl+Label.JNaccName+accountname):linkurl;
                        linkurl = (oppid != null && oppid != '')?(linkurl+Label.JNoppId+oppid):linkurl;
                        linkurl = (oppname != null && oppname != '')?(linkurl+Label.JNoppName+oppname):linkurl;
                        linkurl = Encodingutil.urlEncode(linkurl, 'UTF-8');
                        he.url = linkurl;
                    }
                }
            }       
        }
        return menulistResp;
    }
    @RemoteAction
    global static string callJNMethod(string evename, string endurl, string queryparam){
        Httpresponse res = new Httpresponse();
        string evelist;
        string url = '/'+evename+endurl;
        res = JNUtilClass.JNsendReq('GET', url, queryparam);
        if(res.getBody() != null){
            evelist = res.getBody();
        }
        return evelist;
    }
}