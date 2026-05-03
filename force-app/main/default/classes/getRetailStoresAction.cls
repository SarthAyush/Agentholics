public without sharing class getRetailStoresAction {

    public class OutputWrapper {
        @InvocableVariable(label='Stores Output')
        public String outputText;
    }

    @InvocableMethod(label='Get All Retail Stores (Text)' 
                     description='Returns all retail stores as formatted text')
    public static List<OutputWrapper> getRetailStores(List<String> input) {
        
        List<RetailStore> stores = [
            SELECT Id, Name, Location.Name
            FROM RetailStore
        ];

        String result = '';

        for (RetailStore s : stores) {
            result += 'Store: ' + s.Name +
                      ' | Location: ' + 
                      (s.Location != null ? s.Location.Name : 'N/A') +
                      '\n';
        }

        // Handle no records case
        if (String.isBlank(result)) {
            result = 'No retail stores found in the system.';
        }

        OutputWrapper ow = new OutputWrapper();
        ow.outputText = result;

        return new List<OutputWrapper>{ ow };
    }
}