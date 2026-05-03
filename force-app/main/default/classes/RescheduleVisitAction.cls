public without sharing class RescheduleVisitAction {

    public class Input {
        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable(required=true)
        public Id visitId;

        @InvocableVariable(required=true)
        public Date newDate;

        @InvocableVariable(required=true)
        public Time newStartTime;

        @InvocableVariable(required=true)
        public Time newEndTime;
    }

    public class Output {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Reschedule Visit (Final Fixed)')
    public static List<Output> reschedule(List<Input> inputs) {

        List<Output> results = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            return results;
        }

        // ---------------- CONTACT FETCH (SAFE NORMALIZATION) ----------------
        Map<String, Contact> emailMap = new Map<String, Contact>();

        for (Contact c : [
            SELECT Id, Email 
            FROM Contact 
            WHERE Email != NULL
        ]) {
            String normalized = c.Email.trim().toLowerCase();
            emailMap.put(normalized, c);
        }

        // ---------------- VISIT FETCH ----------------
        Set<Id> visitIds = new Set<Id>();
        for (Input i : inputs) {
            if (i.visitId != null) {
                visitIds.add(i.visitId);
            }
        }

        Map<Id, Visit> visitMap = new Map<Id, Visit>([
            SELECT Id, Status, VisitorId, ContactId,
                   PlannedVisitStartTime, PlannedVisitEndTime
            FROM Visit
            WHERE Id IN :visitIds
        ]);

        // ---------------- PROCESS ----------------
        List<Visit> toUpdate = new List<Visit>();

        for (Input inp : inputs) {

            Output out = new Output();

            // Normalize email
            String emailKey = inp.email != null ? inp.email.trim().toLowerCase() : null;

            Contact con = emailMap.get(emailKey);
            Visit v = visitMap.get(inp.visitId);

            // -------- DEBUG (YOU WILL THANK ME LATER) --------
            System.debug('Input Email: ' + inp.email);
            System.debug('Normalized Email: ' + emailKey);
            System.debug('Contact Found: ' + con);
            System.debug('Visit Found: ' + v);

            // -------- VALIDATIONS --------
            if (con == null) {
                out.message = 'Contact not found for this email';
                results.add(out);
                continue;
            }

            if (v == null) {
                out.message = 'Visit not found';
                results.add(out);
                continue;
            }

            // -------- OWNERSHIP CHECK (HANDLES BOTH FIELDS) --------
            Boolean isOwner = false;

            if (v.VisitorId != null && v.VisitorId == con.Id) {
                isOwner = true;
            }

            if (v.ContactId != null && v.ContactId == con.Id) {
                isOwner = true;
            }

            if (!isOwner) {
                out.message = 'This visit does not belong to this user';
                results.add(out);
                continue;
            }

            // -------- STATUS CHECK --------
            if (v.Status != 'Planned') {
                out.message = 'Only Planned visits can be rescheduled';
                results.add(out);
                continue;
            }

            // -------- TIME VALIDATION --------
            if (inp.newStartTime == null || inp.newEndTime == null) {
                out.message = 'Start and End time required';
                results.add(out);
                continue;
            }

            // -------- UPDATE --------
            v.PlannedVisitStartTime = Datetime.newInstance(inp.newDate, inp.newStartTime);
            v.PlannedVisitEndTime = Datetime.newInstance(inp.newDate, inp.newEndTime);

            toUpdate.add(v);

            out.message = 'Visit rescheduled successfully';
            results.add(out);
        }

        // ---------------- SAVE ----------------
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return results;
    }
}