@RestResource(urlMapping='/updatecontacts/*')
global without sharing class ContactService {

    @HttpPost
    global static void updateContact() {
        RestRequest req = RestContext.request;

        if (req.requestBody == null) {
            prepareResponse(RestContext.response, 422);
            return;
        }

        List<ContactWrapper> listCon;
        try {
            listCon = (List<ContactWrapper>) JSON.deserialize(req.requestBody.toString(), List<ContactWrapper>.class);
            Boolean isError = false;
            Map<String, ContactWrapper> mapData = new Map<String, ContactWrapper>();
            for(ContactWrapper item : listCon){
                System.debug(item);
                if(String.isBlank(item.lastname) || String.isBlank(item.contactexternalid)){
                    isError = true;
                    break;
                }
                else{
                    if(!mapData.containsKey(item.contactexternalid)){
                        mapData.put(item.contactexternalid, item);
                    }
                    else{
                        // error duplicate
                        isError = true;
                        break;
                    }
                }
            }

            if(isError){
                prepareResponse(RestContext.response, 422);
                return;
            }
            else{
                List<Contact> lstCon = new List<Contact>();
                lstCon = [SELECT Id, FirstName, LastName, Active__c, External_ID__c FROM Contact WHERE External_ID__c IN :mapData.keySet()];
                for(Contact con : lstCon){
                    if(mapData.containsKey(con.External_ID__c)){
                        con.FirstName = mapData.get(con.External_ID__c).firstname;
                        con.LastName = mapData.get(con.External_ID__c).lastname;
                        if(mapData.get(con.External_ID__c).active == 'true'){
                            con.Active__c = true;
                        }
                    }
                }
                update lstCon;
                prepareResponse(RestContext.response, 200);
            }
        } catch (Exception ex) {
            prepareResponse(RestContext.response, 400);
            return;
        }
    }

    private static void prepareResponse(RestResponse response, Integer statusCode) {
        response.statusCode = statusCode;
        response.addHeader('Content-Type', 'application/json');
    }
}