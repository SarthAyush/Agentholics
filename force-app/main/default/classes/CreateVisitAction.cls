public with sharing class CreateVisitAction {

    public class Input {
        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable(required=true)
        public String storeName;

        @InvocableVariable(required=true)
        public Date visitDate;

        @InvocableVariable(required=true)
        public Time startTime;

        @InvocableVariable(required=true)
        public Time endTime;

        @InvocableVariable
        public String priority;
    }

    public class Output {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Create Visit')
    public static List<Output> createVisit(List<Input> inputs) {

        List<Output> results = new List<Output>();

        // Fetch Contacts
        Map<String, Contact> emailMap = new Map<String, Contact>();
        for (Contact c : [SELECT Id, Email FROM Contact WHERE Email != NULL]) {
            emailMap.put(c.Email.toLowerCase(), c);
        }

        // Fetch Stores
        Map<String, RetailStore> storeMap = new Map<String, RetailStore>();
        for (RetailStore rs : [SELECT Id, Name FROM RetailStore]) {
            storeMap.put(rs.Name.toLowerCase(), rs);
        }

        List<Visit> toInsert = new List<Visit>();

        for (Input inp : inputs) {

            Output out = new Output();

            Contact con = emailMap.get(inp.email.toLowerCase());
            RetailStore rs = storeMap.get(inp.storeName.toLowerCase());

            if (con == null) {
                out.message = 'Contact not found';
                results.add(out);
                continue;
            }

            if (rs == null) {
                out.message = 'Store not found';
                results.add(out);
                continue;
            }

            Datetime startDT = Datetime.newInstance(inp.visitDate, inp.startTime);
            Datetime endDT = Datetime.newInstance(inp.visitDate, inp.endTime);

           Visit v = new Visit();

v.VisitorId = con.Id;        // ✅ FIX
v.PlaceId = rs.Id;           // ✅ FIX

v.AccountId = '001ak000028Bg76AAC';
v.PlannedVisitStartTime = startDT;
v.PlannedVisitEndTime = endDT;
v.Status = 'Planned';
v.VisitPriority = inp.priority;

            toInsert.add(v);

            out.message = 'Visit scheduled successfully';
            results.add(out);
        }

        if (!toInsert.isEmpty()) insert toInsert;

        return results;
    }
}