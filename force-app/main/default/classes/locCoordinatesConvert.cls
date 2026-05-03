public class locCoordinatesConvert {
	public class Input {
        @InvocableVariable(required=true)
        public String latitude;

        @InvocableVariable(required=true)
        public String longitude;
    }

    public class Output {
        @InvocableVariable
        public String fullAddress;

        @InvocableVariable
        public String sectorName;
    }

    @InvocableMethod(label='Get Address from Coordinates' description='Converts latitude and longitude to human-readable address using Mappls API')
    public static List<Output> getAddress(List<Input> inputs) {

        List<Output> results = new List<Output>();

        for (Input inp : inputs) {
            Output out = new Output();

            try {
                Http http = new Http();
                HttpRequest req = new HttpRequest();

                String endpoint = 'https://search.mappls.com/search/address/rev-geocode'
                    + '?lat=' + String.valueOf(inp.latitude)
                    + '&lng=' + String.valueOf(inp.longitude)
                    + '&access_token=nywppxzxrpcqtsohhswmkadjrvnjvwbiiwmn';

                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setTimeout(10000);

                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {

                    // Parse JSON
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    List<Object> resultsList = (List<Object>) jsonResponse.get('results');

                    if (!resultsList.isEmpty()) {
                        Map<String, Object> firstResult = (Map<String, Object>) resultsList[0];

                        // "formatted_address" is usually present
                        if (firstResult.containsKey('formatted_address')) {
                            out.fullAddress = (String)firstResult.get('formatted_address');
                            System.debug((String)firstResult.get('formatted_address'));
                        } 
                        if(firstResult.containsKey('locality')) {
                            out.sectorName = (String)firstResult.get('locality');
                            System.debug((String)firstResult.get('locality'));
                        }
                    }
                } else {
                    out.fullAddress = 'Error: HTTP ' + res.getStatusCode() + '-->' + res.getBody();
                }

            } catch (Exception e) {
                out.fullAddress = 'Exception: ' + e.getMessage();
            }

            results.add(out);
        }

        return results;
    }
}