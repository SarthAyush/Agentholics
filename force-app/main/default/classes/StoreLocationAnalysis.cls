public class StoreLocationAnalysis {
    
    public class RequestWrapper {
        @InvocableVariable(label='Store Location'
                          description='Contains the location where the user wants to open a new retail Store')
        public string newLocationSec;
    }
    
    public class ResponseWrapper {
        @InvocableVariable(label='Store Analysis'
                          description='Contains the store analysis done for the asked location')
        public string finalStoreAnalysis;
        
    }
    
    @InvocableMethod(label='Analyze Store Expansion Location')
    public static List<ResponseWrapper> analyzeLocation(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        
        for(RequestWrapper req: requests) {
            
            List<Schema.Location> loc = [SELECT Name, Location,Demand_Score__c,Avg_FootFall__c,Competition_Level__c,Avg_Revenue__c FROM Location
                           WHERE Name=: req.newLocationSec LIMIT 1];
        }
        
        String Recommendation='';
        
        return responses;
    }

}