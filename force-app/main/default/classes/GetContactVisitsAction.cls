public without sharing class GetContactVisitsAction {

    // ================= INPUT =================
    public class Input {
        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String dateInput;
    }

    // ================= WRAPPER =================
    public class VisitWrapper {

        @InvocableVariable
        public Id visitId;

        @InvocableVariable
        public Datetime visitStartTime;

        @InvocableVariable
        public Datetime visitEndTime;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String retailStoreName;

        @InvocableVariable
        public String priority;
    }

    // ================= OUTPUT =================
    public class Output {

        @InvocableVariable
        public String contactName;

        @InvocableVariable
        public List<VisitWrapper> visits;
    }

    // ================= DATE RANGE CLASS =================
    public class DateRange {
        public Date startDate;
        public Date endDate;
    }

    // ================= MAIN METHOD =================
    @InvocableMethod(label='Get Contact Visits (Smart Filter)')
    public static List<Output> getVisits(List<Input> inputs) {

        List<Output> results = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            return results;
        }

        // -------- Normalize Emails --------
        Set<String> emailSet = new Set<String>();

        for (Input inp : inputs) {
            if (String.isNotBlank(inp.email)) {
                emailSet.add(inp.email.trim().toLowerCase());
            }
        }

        if (emailSet.isEmpty()) return results;

        // -------- Fetch Contacts --------
        Map<String, Contact> emailToContact = new Map<String, Contact>();

        for (Contact c : [
            SELECT Id, Name, Email
            FROM Contact
            WHERE Email IN :emailSet
        ]) {
            if (c.Email != null) {
                emailToContact.put(c.Email.toLowerCase(), c);
            }
        }

        // -------- Process Each Input --------
        for (Input inp : inputs) {

            Output out = new Output();
            out.visits = new List<VisitWrapper>();

            if (String.isBlank(inp.email)) {
                results.add(out);
                continue;
            }

            String key = inp.email.trim().toLowerCase();
            Contact con = emailToContact.get(key);

            if (con == null) {
                results.add(out);
                continue;
            }

            out.contactName = con.Name;

            Id contactId = con.Id;

            String normalizedStatus = normalizeStatus(inp.status);
            DateRange range = parseDateRange(inp.dateInput);

            // 👇 FIX: Extract variables for binding
            Date startDate;
            Date endDate;

            if (range != null) {
                startDate = range.startDate;
                endDate = range.endDate;
            }

            // -------- Build Query --------
            String baseQuery =
                'SELECT Id, PlannedVisitStartTime, PlannedVisitEndTime, Status, VisitPriority, RetailStore.Name ' +
                'FROM Visit WHERE ContactId = :contactId';

            if (normalizedStatus != null) {
                baseQuery += ' AND Status = :normalizedStatus';
            }

            if (startDate != null && endDate != null) {
                baseQuery += ' AND DAY_ONLY(PlannedVisitStartTime) >= :startDate';
                baseQuery += ' AND DAY_ONLY(PlannedVisitStartTime) <= :endDate';
            }

            List<Visit> visits = Database.query(baseQuery);

            // -------- Map Output --------
            for (Visit v : visits) {
                VisitWrapper vw = new VisitWrapper();

                vw.visitId = v.Id;
                vw.visitStartTime = v.PlannedVisitStartTime;
                vw.visitEndTime = v.PlannedVisitEndTime;
                vw.status = v.Status;
                vw.priority = v.VisitPriority;
                vw.retailStoreName = (v.RetailStore != null) ? v.RetailStore.Name : null;

                out.visits.add(vw);
            }

            results.add(out);
        }

        return results;
    }

    // ================= STATUS NORMALIZER =================
    private static String normalizeStatus(String status) {
        if (String.isBlank(status)) return null;

        String s = status.trim().toLowerCase();

        if (s.contains('plan')) return 'Planned';
        if (s.contains('complete')) return 'Completed';
        if (s.contains('cancel')) return 'Cancelled';
        if (s.contains('progress')) return 'In Progress';

        return null;
    }

    // ================= DATE RANGE PARSER =================
    private static DateRange parseDateRange(String input) {

        if (String.isBlank(input)) return null;

        String s = input.trim().toLowerCase();
        Date today = Date.today();

        DateRange range = new DateRange();

        // ---- Today / Tomorrow / Yesterday ----
        if (s == 'today') {
            range.startDate = today;
            range.endDate = today;
            return range;
        }

        if (s == 'tomorrow') {
            range.startDate = today.addDays(1);
            range.endDate = today.addDays(1);
            return range;
        }

        if (s == 'yesterday') {
            range.startDate = today.addDays(-1);
            range.endDate = today.addDays(-1);
            return range;
        }

        // ---- Week Logic ----
        Date startOfWeek = today.toStartOfWeek();
        Date endOfWeek = startOfWeek.addDays(6);

        if (s.contains('this week')) {
            range.startDate = startOfWeek;
            range.endDate = endOfWeek;
            return range;
        }

        if (s.contains('last week')) {
            range.startDate = startOfWeek.addDays(-7);
            range.endDate = endOfWeek.addDays(-7);
            return range;
        }

        if (s.contains('next week')) {
            range.startDate = startOfWeek.addDays(7);
            range.endDate = endOfWeek.addDays(7);
            return range;
        }

        // ---- Month Logic ----
        Date startOfMonth = Date.newInstance(today.year(), today.month(), 1);
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);

        if (s.contains('this month')) {
            range.startDate = startOfMonth;
            range.endDate = endOfMonth;
            return range;
        }

        if (s.contains('last month')) {
            Date lastMonthStart = startOfMonth.addMonths(-1);
            range.startDate = lastMonthStart;
            range.endDate = startOfMonth.addDays(-1);
            return range;
        }

        if (s.contains('next month')) {
            Date nextMonthStart = startOfMonth.addMonths(1);
            range.startDate = nextMonthStart;
            range.endDate = nextMonthStart.addMonths(1).addDays(-1);
            return range;
        }

        // ---- Fallback Exact Date ----
        try {
            Date d = Date.valueOf(s);
            range.startDate = d;
            range.endDate = d;
            return range;
        } catch (Exception e) {}

        return null;
    }
}