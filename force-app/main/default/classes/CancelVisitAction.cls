public without sharing class CancelVisitAction {

    public class Input {
        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable(required=true)
        public Id visitId;
    }

    public class Output {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Cancel Visit')
    public static List<Output> cancel(List<Input> inputs) {

        List<Output> results = new List<Output>();

        Map<String, Contact> emailMap = new Map<String, Contact>();
        for (Contact c : [SELECT Id, Email FROM Contact WHERE Email != NULL]) {
            emailMap.put(c.Email.toLowerCase(), c);
        }

        Set<Id> visitIds = new Set<Id>();
        for (Input i : inputs) {
            visitIds.add(i.visitId);
        }

        Map<Id, Visit> visitMap = new Map<Id, Visit>([
            SELECT Id, Status, VisitorId
            FROM Visit
            WHERE Id IN :visitIds
        ]);

        List<Visit> toUpdate = new List<Visit>();

        for (Input inp : inputs) {

            Output out = new Output();

            Contact con = emailMap.get(inp.email.toLowerCase());
            Visit v = visitMap.get(inp.visitId);

            if (con == null || v == null) {
                out.message = 'Invalid user or visit';
                results.add(out);
                continue;
            }

            // Ownership check
            if (v.VisitorId != con.Id) {
                out.message = 'This visit does not belong to you';
                results.add(out);
                continue;
            }

            if (v.Status == 'Cancelled') {
                out.message = 'Visit is already cancelled';
                results.add(out);
                continue;
            }

            v.Status = 'Cancelled';

            toUpdate.add(v);

            out.message = 'Visit cancelled successfully';
            results.add(out);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return results;
    }
}