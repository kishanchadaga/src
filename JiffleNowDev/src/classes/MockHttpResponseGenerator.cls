@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('https://tugboat-testing.jifflenow.com/api/oauth/token', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token":"testaccesstoken","token_type": "bearer","refresh_token":"testrefreshtoken"}');
        res.setStatusCode(200);
        return res;
    }
}