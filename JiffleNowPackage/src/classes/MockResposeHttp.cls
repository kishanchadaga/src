@isTest
global with sharing class MockResposeHttp implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('GET', req.getMethod());
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        System.debug('LABEL'+req.getEndpoint());
       // System.debug('LABEL2'+req.getEndpoint().contains(Label.JNEventMeetingMenu));
        if(req.getEndpoint().contains(Label.JNEventMeetingMenu)){
        	res.setBody('{"data":{"links":[{"name":"Events","url":"/apex/JNEvents"},{"event_system_name":"live2016","name":"Meetings","url":"/apex/JNMeetings?eventName=live2016"}]},"errors":{},"message":"Request Successful"}');
        }
        else if(req.getEndpoint().contains(Label.JNCreateMeeting)){
        	res.setBody('{"status":200,"message": "Request successful","data": {"meeting_uuid": "x34QYbpEdqxohm_9qOxYGw","meeting_id": 1,"meeting": {"id": 1,"uuid":"x34QYbpEdqxohm_9qOxYGw","start_time": "2020-01-08T08:00:00.000Z","end_time": "2020-01-08T09:00:00.000Z","status": "approved","activity": {"name": "meeting","display_name": "Meeting","enabled": true,"uuid": "1re9dU7nuuiDhbB6SRndwA","location_id": null},"meeting_with": "test_9472","custom_fields": {"meeting_oncagzsjd": "nothing124"},"creator": "BWb60OsasnSAz_EbnCglng"},"location": {"name": "Board Room","capacity": 20,"location": "","url": null,"url_desc": null,"contact_no": "","description": "","uuid": "YWkM2XeADFcvb3hfqziWQw","location_id": null},"attendee_summary": {"total": 8,"internal": {"total": 4,"pending": 2,"accepted": 1,"declined": 1},"external": {"total": 4,"pending": 3,"accepted": 1,"declined": 0}},"attendees": [{"email": "another@gmail.com","first_name": "Another","last_name": "User","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "3dAiShFqytwmr6uN0iIhRg","role": "Executive","invite_status": "pending","country": "","type": "internal","requestor": true},{"email": "john.mm@gmail.com","first_name": "John","last_name": "MM","title": "","company_name": "Cisco","contact_no": "9999999","uuid": "BWb60OsasnSAz_EbnCglng","role": "Customer Success Manager","invite_status": "accepted","country": "","type": "external","requestor": false}]},"errors": {}}');
        	system.debug('TestCreateMeeting');
        }
        else{
            res.setBody('{"data":{"events":[{"action":{"key":"SCHEDULE_ACTIVITY_ACTION","name":"REQUEST MEETING","url":"%2Fapex%2FJNBookMeeting%3FeventName%3Dlive2016"},"analytics":{"accepted":4,"declined":1,"meetings":5,"pending":0},"banner_url":"https://jifflenow-61a2879d-d6b9-4219-a1d8-e85d06f8cd5e.s3-us-west-1.amazonaws.com/live2016/banner.png","end_date":"2016-03-19","event_name":"Live 2016","event_system_name":"live2016","event_url":"&%2Fapex%2FJNMeetings%3FeventName%3Dlive2016","location":"Bangalore","metadata":"Live 2016 2016-03-16 2016-03-19","show_meta":false,"start_date":"2016-03-16","status":"LAUNCHED","time_zone":"Chennai","uuid":"nqvoTbDT3mamTWtwIfzx7Q"}]}}');
        }
        res.setStatusCode(200);
        return res;
    }
}