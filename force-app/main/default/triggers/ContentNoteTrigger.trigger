trigger ContentNoteTrigger on ContentDocumentLink (after insert) {

    Map<Id, Id> noteToVisitMap = new Map<Id, Id>();

    System.debug('Trigger fired: ' + Trigger.new);

    for (ContentDocumentLink cdl : Trigger.new) {

        System.debug('Processing CDL: ' + cdl);

        if (cdl.LinkedEntityId != null &&
            String.valueOf(cdl.LinkedEntityId).startsWith('0Z')) {

            noteToVisitMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);

            System.debug('Mapped Note -> Visit: ' +
                cdl.ContentDocumentId + ' -> ' + cdl.LinkedEntityId);
        } else {
            System.debug('Skipping non-visit record: ' + cdl.LinkedEntityId);
        }
    }

    System.debug('Final map: ' + noteToVisitMap);

    if (!noteToVisitMap.isEmpty()) {

        System.debug('Enqueuing Queueable with 1-minute delay');

        // Delay from the trigger itself
        System.enqueueJob(
            new NoteProcessorQueueable(noteToVisitMap),
            1 // delay in minutes
        );

    } else {
        System.debug('No valid records to process');
    }
}