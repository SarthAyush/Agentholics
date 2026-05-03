public class VisitNoteService {

    public static void fetchVisitNotes() {

        // Step 1: Get all Visit Ids
        Set<Id> visitIds = new Set<Id>();
        for (Visit v : [SELECT Id FROM Visit]) {
            visitIds.add(v.Id);
        }

        // Step 2: Get ContentDocumentLinks
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :visitIds
        ];

        // Map Visit -> Document Ids
        Map<Id, List<Id>> visitToDocs = new Map<Id, List<Id>>();
        Set<Id> docIds = new Set<Id>();

        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);

            if (!visitToDocs.containsKey(cdl.LinkedEntityId)) {
                visitToDocs.put(cdl.LinkedEntityId, new List<Id>());
            }
            visitToDocs.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
        }

        // Step 3: Get ContentNotes
        Map<Id, ContentNote> noteMap = new Map<Id, ContentNote>(
            [SELECT Id, Title, Content FROM ContentNote WHERE Id IN :docIds]
        );

        // Step 4: Print Preview
        for (Id visitId : visitToDocs.keySet()) {

            System.debug('---- Visit: ' + visitId + ' ----');

            for (Id docId : visitToDocs.get(visitId)) {
                if (noteMap.containsKey(docId)) {

                    ContentNote cn = noteMap.get(docId);

                    // Convert Blob → String
                    String body = cn.Content.toString();

                    // Preview (first 100 chars)
                    String preview = body.length() > 100 
                        ? body.substring(0, 100) 
                        : body;

                    System.debug('Title: ' + cn.Title);
                    System.debug('Preview: ' + preview);
                }
            }
        }
    }
}