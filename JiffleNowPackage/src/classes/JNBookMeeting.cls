/*
    Type:       Custom Controller with remote methods
    Purpose:    This is used for apis and controller methods for Bookmeeting.
                Has Methods for Account and opportunity search.
                The appis on load of the page are Attendees, room listing, calender, envitems
    Used By:    JNBookMeetings
                 JNBookjs
    ---------------------------------------------------------------
    History:

    09-Sept-2015     Created     Jifflenow

*/
global with sharing class JNBookMeeting {
    @RemoteAction
    global static list<JNReqRespWC.sfdcAccount> searchAccOpty(string accName, string accId){
        list<Opportunity> optylst = new list<Opportunity>();
        Account acc;
        list<Account> acclst = new list<Account>();
        JNReqRespWC.sfdcAccount sfdcAcc; 
        list<JNReqRespWC.sfdcAccount> sfdcAcclst = new list<JNReqRespWC.sfdcAccount>();
        JNReqRespWC.sfdcOpportunity sfdcOpty;
        list<JNReqRespWC.sfdcOpportunity> sfdcOptylst;
        string queryString;
        if(accId != null && accId != ''){
            queryString = 'select Name, Id,(select Name, Id from Opportunities order by LastModifiedDate desc limit 10) from Account where Id = \''+accId+'\' order by LastModifiedDate desc limit 10';
            acclst = Database.Query(queryString);
            System.debug('QueryResult'+acclst);
        }
        else if(accName != null && accName != ''){
            queryString = 'select Name, Id,(select Name, Id from Opportunities order by LastModifiedDate desc limit 10) from Account where Name like \'%'+accName+'%\' order by LastModifiedDate desc limit 10';
            acclst = Database.Query(queryString);
            System.debug('QueryResult'+acclst);
        }
        if(acclst != null && acclst.size()>0){
            for(Account ac:acclst){
                sfdcAcc = new JNReqRespWC.sfdcAccount();
                sfdcOptylst = new list<JNReqRespWC.sfdcOpportunity>();
                acc = new Account();
                sfdcacc.Id = ac.Id;
                string encoAccName = Encodingutil.urlEncode(ac.Name, 'UTF-8');
                sfdcacc.name = encoAccName;
                System.debug('Encode'+ac.Name+' '+encoAccName);
                acc = ac;
                for(Opportunity op:ac.Opportunities){
                    sfdcOpty = new JNReqRespWC.sfdcOpportunity();
                    string encoOpName = Encodingutil.urlEncode(op.Name, 'UTF-8');
                    sfdcOpty.name = encoOpName;
                    sfdcOpty.Id = op.Id;
                    sfdcOptylst.add(sfdcOpty);
                }
                sfdcAcc.opty = sfdcOptylst;
                sfdcAcclst.add(sfdcacc);
            }
        }
        System.debug(sfdcAcclst);
        return sfdcAcclst;
    }  
    @RemoteAction
    global static list<JNReqRespWC.sfdcOpty> getOptyList(string oppName, string oppId){
        list<Opportunity> optylst = new list<Opportunity>();
        list<JNReqRespWC.sfdcOpty> optywraplst = new list<JNReqRespWC.sfdcOpty>();
        JNReqRespWC.sfdcOpty optywrap;
        if(oppId != null && oppId != ''){
            string queryString = 'SELECT Id,Name, Account.Name, Account.Id FROM Opportunity WHERE Id = \'' + oppId + '\' ORDER BY LastModifiedDate DESC LIMIT 10';
            optylst = Database.Query(queryString);
        }
        else if(oppName != null &&  oppName != ''){
            string queryString = 'SELECT Id,Name, Account.Name, Account.Id FROM Opportunity WHERE Name LIKE \'%' + oppName + '%\' ORDER BY LastModifiedDate DESC LIMIT 10';
            optylst = Database.Query(queryString);
        }
        if(optylst != null){
            for(Opportunity op:optylst){
                optywrap = new JNReqRespWC.sfdcOpty();
                optywrap.id = op.Id;
                string encoOpName = Encodingutil.urlEncode(op.Name, 'UTF-8');
                optywrap.name = encoOpName;
                string encoAccName = Encodingutil.urlEncode(op.Account.Name, 'UTF-8');
                optywrap.accountname = encoAccName;
                optywrap.accountid = op.Account.Id;
                optywraplst.add(optywrap);
            }
        }
        System.debug(' Response' + optywraplst);
        return optywraplst;
    }
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
    
    @RemoteAction
    global static JNReqRespWC.externalAttendees getExtAtt(string accId, Integer listSize, Integer pgNo){
        JNReqRespWC.itemsWrap it;
        JNReqRespWC.externalAttendees extAtt = new JNReqRespWC.externalAttendees();
        list<JNReqRespWC.itemsWrap> itemslst = new list<JNReqRespWC.itemsWrap>();
        extAtt.data = new JNReqRespWC.ExtAttDataWrap();
        extAtt.data.items  =  new list<JNReqRespWC.itemsWrap>();
        list<Contact> conlst = new list<Contact>();
        Integer totalSize;
        Integer totPages;
        Integer offset;
        if(accId != null && accId != ''){
            string qryCount = 'SELECT count() FROM Contact WHERE AccountId = \'' +accId+'\'';
            totalSize = Database.countQuery(qryCount);
            totPages = getTotalPages(totalSize, listSize); 
            offset = getoffset(pgNo, listSize);
            string qry = 'SELECT Account.Name,Email,FirstName,LastName,MobilePhone,Title FROM Contact WHERE AccountId = \'' +accId+'\' LIMIT '+listSize+' OFFSET '+ offset;
            conlst = Database.query(qry);
        }
        if(conlst != null && conlst.size()>0){
            for(Contact c:conlst){
                it = new JNReqRespWC.itemsWrap();
                it.first_name = c.FirstName;
                it.last_name = c.LastName;
                it.email = c.Email;
                it.contact_no = c.MobilePhone;
                it.company_name = c.Account.Name;
                it.available = true;
                it.title = c.Title;
                itemslst.add(it);
            }
        System.debug('ITEMSLST ' +itemslst);
        extAtt.data.items = itemslst;
        extAtt.data.total_entries = totalSize;
        extAtt.data.total_pages = totPages;
        extAtt.data.current_page = pgNo;
        }
        System.debug('extAtt ' +extAtt);
        return extAtt;
    }
    
    @RemoteAction
    global static string getCalendar(string eventName, string qry){
        Httpresponse res = new Httpresponse();
        string link = '/' + eventName + '/meeting_request' + '/calendar';
        res = JNUtilClass.JNsendReq('GET', link, qry);
        string returnval;
        if(res.getBody() != null){
            returnval = res.getBody();
        }
        System.debug('RESPONSE' + returnval);
        return returnval;
    }
    
    public static Integer getoffset(Integer pagenum, Integer list_size){
        Integer counter = (pagenum-1)*list_size;
        return counter;
    }
    public static Integer getTotalPages(Integer total_size, Integer list_size){
        if (math.mod(total_size, list_size) > 0) {
            return total_size/list_size + 1;
        } else {
            return (total_size/list_size);
        }
    }
    
    @RemoteAction
    global static string createMeeting(string eventName, string accId, string optyId ,string request){
        System.debug('Account Id '+accId);
        System.debug('Opportunity Id '+optyId);
        string endurl = '/'+ eventName + Label.JNCreateMeeting;
        Httpresponse res = new Httpresponse();
        res = JNUtilClass.JNPost(endurl, request);
        string resBody;
        string response;
        if(res.getBody() != null){
            resBody = res.getBody();
        }
        System.debug('RESPONSE BODY' +resBody);
        System.debug('FOR TEST CLASS'+resBody.contains('"status":200'));
        if(resBody.contains('"status":200')){
           response= syncMeeting(resBody,accId,optyId);
            if(response == 'success'){
                system.debug('RESPONSE'+resBody);
                return resBody;
            }
            else{
                system.debug('RESPONSE'+response);
                return response;
            }           
        }
        else{
                system.debug('RESPONSE'+resBody);
                return resBody;
        }

    }
    
    public static string syncMeeting(string resp,string accountid,string OpportunityId){
        string returnval = 'success';
        list<string> strlst = new list<string>();
        JNReqRespWC.errorResp err = new JNReqRespWC.errorResp();
        err.status = 400;
        err.data = new JNReqRespWC.errorData();
        err.message = Label.JNSyncError;
        err.errors = new JNReqRespWC.errorHandle();
        try{
        Event__c eve = new Event__c(); 
        eve = [select Id from Event__c LIMIT 1];
        system.debug('resp123'+resp);
        //string response = '{"status": 200,"message": "Request successful","data": {"meeting_uuid": "x34QYbpEdqxohm_9qOxYGw","meeting_id": 1,"meeting": {"id": 1,"uuid":"x34QYbpEdqxohm_9qOxYGw","start_time": "2020-01-08T08:00:00.000Z","end_time": "2020-01-08T09:00:00.000Z","status": "approved","activity": {"name": "meeting","display_name": "Meeting","enabled": true,"uuid": "1re9dU7nuuiDhbB6SRndwA","location_id": null},"meeting_with": "test_9472","custom_fields": {"meeting_oncagzsjd": "nothing124"},"creator": "BWb60OsasnSAz_EbnCglng"},"location": {"name": "Board Room","capacity": 20,"location": "","url": null,"url_desc": null,"contact_no": "","description": "","uuid": "YWkM2XeADFcvb3hfqziWQw","location_id": null},"attendee_summary": {"total": 8,"internal": {"total": 4,"pending": 2,"accepted": 1,"declined": 1},"external": {"total": 4,"pending": 3,"accepted": 1,"declined": 0}},"attendees": [{"email": "another@gmail.com","first_name": "Another","last_name": "User","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "3dAiShFqytwmr6uN0iIhRg","role": "Executive","invite_status": "pending","country": "","type": "internal","requestor": true},{"email": "john.mm@gmail.com","first_name": "John","last_name": "MM","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "BWb60OsasnSAz_EbnCglng","role": "Customer Success Manager","invite_status": "accepted","country": "","type": "external","requestor": false}]},"errors": {}}';
        string response = resp;
        Map<string,string> attObjMap = new Map<string,string>(); 
        Meeting__c meetObj = new Meeting__c();
        Schema.SObjectField extId = Attendee__c.Fields.Attendee_UUID__c;
        //Database.UpsertResult [] cr = new list<Database.UpsertResult>();
        list<Database.UpsertResult> cr= new list<Database.UpsertResult>(); 
        Meeting_Relations__c relationobj = new Meeting_Relations__c();
        JNReqRespWC.Meeting_Resp meetRes = new JNReqRespWC.Meeting_Resp();
        JNReqRespWC.MeetWrapper meetwrap = new JNReqRespWC.MeetWrapper(); 
        inviteWrapper invWrapObj = new inviteWrapper();
        list<inviteWrapper> invWraplst = new list<inviteWrapper>();
        meetRes.data = new JNReqRespWC.dataWrapMeet();
        meetRes.data.location = new JNReqRespWC.LocWrapper();
        meetRes.data.attendees = new list<JNReqRespWC.AttWrapper>();
        meetRes = (JNReqRespWC.Meeting_Resp) JSON.deserialize(response, JNReqRespWC.Meeting_Resp.class);
        meetwrap = meetRes.data.meeting;
        meetObj.Meeting_ID__c = meetwrap.id; 
        meetObj.Meeting_UUID__c = meetwrap.uuid;
        meetObj.Start_Date_Time__c = meetwrap.start_time;
        meetObj.End_Date_Time__c = meetwrap.end_time;
        meetObj.Request_Status__c = meetwrap.status;
        meetObj.Meeting_Location__c = meetRes.data.location.Name;
        meetObj.Meeting_with__c = meetwrap.meeting_with;
        meetObj.Event__c = eve.Id;
        if(meetObj != null){
            try{
                insert meetObj;
            }
            catch(DMLException e){
                strlst = new list<string>{Label.JNSyncError};
                err.errors.RuntimeError = strlst;
                System.debug('Exception' +e);
                returnval = JSON.serialize(err);
            }
        }
        system.debug('meetObj'+meetObj);
        list<JNReqRespWC.AttWrapper> attendlst = new list<JNReqRespWC.AttWrapper>();
        list<Attendee__c> updattendlst = new list<Attendee__c>();
        list<Invites__c> invitlst = new list<Invites__c>();
        Invites__c invitObj = new Invites__c();
        Attendee__c attendObj;
        attendlst = meetRes.data.attendees;
        System.debug('Attendees' +attendlst);
        for(JNReqRespWC.AttWrapper att:attendlst){
            attendObj = new Attendee__c();
            attendObj.Attendee_Email__c = att.email;
            attendObj.Attendee_First_Name__c = att.first_name;
            attendObj.Attendee_Last_Name__c = att.last_name;
            attendObj.Title__c = att.title;
            attendObj.Company__c = att.company_name;
            attendObj.Mobile__c = att.contact_no;
            attendObj.Attendee_UUID__c = att.uuid;
            attendObj.Country__c = att.country;
            updattendlst.add(attendObj);
            invitObj = new Invites__c(Meeting__c = meetObj.Id);
            invWrapObj = new inviteWrapper();
            invitObj.Attendee_Status__c = att.invite_status;
            invitObj.Contact_Type__c = att.type;
            invitObj.Is_Meeting_Requestor__c = att.requestor;
            invWrapObj.inv = invitObj;
            invWrapObj.UUID = att.uuid;
            invWraplst.add(invWrapObj);
        }

        if(updattendlst != null && updattendlst.size()>0){
            //insert updattendlst;
            try{
                upsert updattendlst Attendee_UUID__c;
            }
            catch(DMLException e){
                strlst = new list<string>{Label.JNSyncError};
                err.errors.RuntimeError = strlst;
                System.debug('Exception' +e);
                returnval = JSON.serialize(err);
            }
        }
        system.debug('Database.UpsertResult' +cr);
        for(Attendee__c att:updattendlst){
            attObjMap.put(att.Attendee_UUID__c, att.Id);
        }
        System.debug('updattendlst' +updattendlst);
        //updattendlst = new list<Attendee__c>();
        //updattendlst = [SELECT Id FROM Attendee__c];
        System.debug('AAAA' +invWraplst);
        for(inviteWrapper att:invWraplst){
            invitObj = new Invites__c();
            invitObj = att.inv;
            if(attObjMap.containsKey(att.UUID)){
                invitObj.Attendee__c = attObjMap.get(att.UUID);
            }
            invitlst.add(invitObj);
        }
        System.debug('invitlst' +invitlst);
        if(invitlst != null && invitlst.size()>0){
            Database.insert(invitlst,false);
        }
        System.debug('invitlst' +invitlst);
        if(meetObj!=null && meetObj.Id !=null){
            relationobj = new Meeting_Relations__c(Meeting__c = meetObj.Id);
            if(OpportunityId != '' && OpportunityId !=null)
            {
                relationobj.Opportunity__c = OpportunityId;
            }
            else if(accountid != '' && accountid !=null){
                relationobj.Account__c = accountid;
            }
            try{
                insert relationobj;
            }
            catch(DMLException e){
                strlst = new list<string>{Label.JNSyncError};
                err.errors.RuntimeError = strlst;
                System.debug('Exception' +e);
                returnval = JSON.serialize(err);
            }
            System.debug('relationobj' +relationobj);
         }
         }
         catch(Exception e){
                strlst = new list<string>{Label.JNSyncError};
                err.errors.RuntimeError = strlst;
                System.debug('Exception' +e);
                returnval = JSON.serialize(err);
            }
         return returnval;
    }
    public class inviteWrapper{
        public Invites__c inv;
        public string UUID; 
    }
}