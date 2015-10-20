global with sharing class JNReqRespWC {
         public class deserial{
            public string success;
            public list<Errors> errors;
            public string access_token;
            public string uuid;
    }
/*************************************************************************
 Wrapper class for Meeting List Response
**************************************************************************/
    public class Datawrapper {
        public List<Meeting_requests> meeting_requests;
        public Integer total_entries;
    }

    public class Users {
        public List<Errors> internal;
        public List<Errors> external;
    }

    public class Meeting_requests {
        public string id;
        public String start_time;
        public String uuid;
        public String end_time;
        public String status;
        public String meeting_with;
        public String location;
        public Invitees_status_counts invitees_status_counts;
        public Actions_Urls actions_urls;
        public Users users;
        public List<string> actions;
        public String invite_status;
        public Boolean edit;
    }

    global class MeetingListResp {
        public Boolean success;
        public List<errors> errors;
        public Datawrapper data;
    }

    public class errors{
        //public string error_msg;
        public list<String> user;
    }
    public class Invitees_status_counts {
        public Integer total_invitees;
        public Integer pending;
        public Integer declined;
    }
    
    public class Actions_Urls {
        public string decline_meeting_url;
        public string accept_meeting_url;
    }    
    
/*************************************************************************
 Wrapper class for Event List Response
**************************************************************************/
    public class analyticswrapper{
        public integer meetings;
        public integer pending;
        public integer accepted;
        public integer declined;
    }
   
    public class actionswrapper{
        public string name;
        public string url;
        public string key;
    }
    public class eventswrapper{
        public string event_name;
        public string event_system_name;
        public string uuid;
        public string location;
        public string start_date;
        public string end_date;
        public string status;
        public string description;
        public string time_zone;
        public string datetime_format;
        public boolean show_meta;
        public string metadata;
        public string banner_url;
        public string event_url;
        //public string book_url;
        public actionswrapper action;
        public analyticswrapper analytics;
    }
     public class datawrap{
        public list<eventswrapper> events;
    }
    /*global class EventListResp{
        public boolean success;
        public list<Errors> errors;
        public list<eventswrapper> events;
    }
    */
    global class EventListResp{
        public Integer status;
        public string message;
        public Errors errors;
        public datawrap data;
    }
    
/*************************************************************************
 Wrapper class for SSO Redirect
**************************************************************************/
    public class SSOData{
        public string authentication_url;
    }
    
    global class SSORedirect{
        public Integer status;
        public string message;
        public Errors errors;
        public SSOData data;
    }
/*************************************************************************
 Wrapper class for Account and Opportunity Search
**************************************************************************/
    public class sfdcOpportunity{
        public string name;
        public string id;
    }
    global class sfdcOpty{
        public string name;
        public string id;
        public string accountid;
        public string accountname;
    }
    global class sfdcAccount{
        public list<sfdcOpportunity> opty;
        public string name;
        public string id;
    }
/*************************************************************************
 Wrapper class for Event and Meeting Menu
**************************************************************************/
    public class headerElements{
        public string name;
        public string url;
        public string event_system_name;
    }
    /*global class menuResp{
        public boolean success;
        public list<Errors> errors;
        public list<headerElements> links;
    }*/
    
    public class dataWrapp{
        public list<headerElements> links;
    }
    
    global class menuResp{
        public string message;
        public dataWrapp data;
        public Errors errors;
    }
    
/*************************************************************************
 Wrapper class for Authentication
**************************************************************************/
    global class Authentication{
        public string user_status;
        public string message;
        public string authentication_url;
        
    }
/*************************************************************************
 Wrapper class for External attendees
**************************************************************************/
    global class externalAttendees{
        public string message;
        public ExtAttDataWrap data;
        public Errors errors;
    }
    public class ExtAttDataWrap{
        public Integer total_entries;
        public Integer current_page;
        public Integer total_pages;
        public list<itemsWrap> items;
    }
    public class itemsWrap{
        public string uuid;
        public string email;
        public string first_name;
        public string last_name;
        public string title;
        public string company_name;
        public string contact_no;
        public boolean show_in_meeting;
        public boolean sfdc_enabled;
        public statusesWrap statuses;
        public string role;
        public boolean available;
    }
    public class statusesWrap{
        public boolean verified;
        public boolean active;
        public string approved;
        public boolean sso_enabled;
    }
/*************************************************************************
 Wrapper class for Updated Meeting Response(22/9/15)
**************************************************************************/
    public class Meeting_Resp{
        public dataWrapMeet data;
        public String message;
        public Errors errors;
        public Integer status;
    }
    public class MeetWrapper{
        public String status;
        public ActWrapper activity;
        public Datetime end_time;
        public String meeting_with;
        public Datetime start_time;
        public CustomWrapper custom_fields;
        public String uuid;
        public String creator;
        public string id;
    }
    public class LocWrapper{
        public String location_id;
        public String url_desc;
        public String url;
        public String contact_no;
        public String location;
        public String description;
        public Integer capacity;
        public String uuid;
        public String name;
    }
    public class IntWrapper{
        public Integer accepted;
        public Integer pending;
        public Integer declined;
        public Integer total;
    }
    public class ExtWrapper{
        public Integer accepted;
        public Integer total;
        public Integer declined;
        public Integer pending;
    }
    public class dataWrapMeet{
        public LocWrapper location;
        public MeetWrapper meeting;
        public AttSumWrapper attendee_summary;
        public Integer meeting_id;
        public list<AttWrapper> attendees;
        public String meeting_uuid;
    }
    public class CustomWrapper{
        public String meeting_oncagzsjd;
    }
    public class AttWrapper{
        public String last_name;
        public String uuid;
        public String role;
        public String contact_no;
        public String invite_status;
        public String company_name;
        public String country;
        public String title;
        public String type;
        public String first_name;
        public Boolean requestor;
        public String email;
    }
    public class AttSumWrapper{
        public ExtWrapper external;
        public IntWrapper internal;
        public Integer total;
    }
    public class ActWrapper{
        public String uuid;
        public Boolean enabled;
        public String display_name;
        public String location_id;
        public String name;
    }
/*************************************************************************
 Wrapper class for Error Handling
**************************************************************************/
    public class errorData {
    }
    public class errorResp{
        public Integer status;
        public String message;
        public errorData data;
        public errorHandle errors;
    }

    public class errorHandle {
        public List<String> RuntimeError;
    }
}