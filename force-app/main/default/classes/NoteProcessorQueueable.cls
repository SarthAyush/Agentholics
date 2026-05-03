public class NoteProcessorQueueable implements Queueable, Database.AllowsCallouts {

    Map<Id, Id> noteToVisitMap;

    public NoteProcessorQueueable(Map<Id, Id> noteToVisitMap) {
        this.noteToVisitMap = noteToVisitMap;
    }

    public void execute(QueueableContext context) {

        System.debug('Queueable started');
        System.debug('Input map: ' + noteToVisitMap);

        Map<Id, Visit> visitMap = new Map<Id, Visit>(
            [SELECT Id, RetailStoreId, RetailStore.Name
             FROM Visit
             WHERE Id IN :noteToVisitMap.values()]
        );

        System.debug('VisitMap: ' + visitMap);

        Map<Id, ContentNote> noteMap = new Map<Id, ContentNote>(
            [SELECT Id, TextPreview FROM ContentNote
             WHERE Id IN :noteToVisitMap.keySet()]
        );

        System.debug('NoteMap: ' + noteMap);

        List<RetailStore> storesToUpdate = new List<RetailStore>();

        for (Id noteId : noteToVisitMap.keySet()) {

            Id visitId = noteToVisitMap.get(noteId);

            System.debug('Processing noteId: ' + noteId);
            System.debug('VisitId: ' + visitId);

            if (!visitMap.containsKey(visitId) || !noteMap.containsKey(noteId)) {
                System.debug('Missing visit or note');
                continue;
            }

            Visit visit = visitMap.get(visitId);
            System.debug('Visit record: ' + visit);

            if (visit.RetailStoreId == null) {
                System.debug('RetailStoreId is null');
                continue;
            }

            ContentNote note = noteMap.get(noteId);

            if (note.TextPreview == null) {
                System.debug('TextPreview null even after delay. Skipping.');
                continue;
            }

            String noteBody = String.valueOf(note.TextPreview);

            System.debug('NoteBody: ' + noteBody);

            String jsonResponse = callPromptTemplate(noteBody);
            System.debug('AI Response: ' + jsonResponse);

            if (String.isBlank(jsonResponse)) {
                System.debug('Empty AI response');
                continue;
            }

            Map<String, Object> parsed;

            try {
                parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                System.debug('Parsed JSON: ' + parsed);
            } catch (Exception e) {
                System.debug('JSON parse failed: ' + jsonResponse);
                continue;
            }

            RetailStore store = new RetailStore();
            store.Id = visit.RetailStoreId;

            String existingName = visit.RetailStore != null ? visit.RetailStore.Name : null;
            store.Name = existingName;

            System.debug('Preserving existing store name: ' + existingName);

            if (parsed.get('Annual Revenue') != null) {
                String revenueStr = parsed.get('Annual Revenue').toString();

                if (!String.isBlank(revenueStr) && revenueStr != 'Unknown') {
                    try {
                        store.Annual_Revenue__c = Decimal.valueOf(revenueStr);
                    } catch (Exception e) {
                        System.debug('Invalid Annual Revenue: ' + revenueStr);
                    }
                }
            }

            if (parsed.get('Average Footfall') != null) {
                String footfallStr = parsed.get('Average Footfall').toString();

                if (!String.isBlank(footfallStr) && footfallStr != 'Unknown') {
                    try {
                        store.Avg_Daily_Footfall__c = Decimal.valueOf(footfallStr);
                    } catch (Exception e) {
                        System.debug('Invalid Footfall: ' + footfallStr);
                    }
                }
            }

            storesToUpdate.add(store);
            System.debug('Prepared store update: ' + store);
        }

        System.debug('Final update list: ' + storesToUpdate);

        if (!storesToUpdate.isEmpty()) {
            update storesToUpdate;
            System.debug('Records updated successfully');
        } else {
            System.debug('No records to update');
        }

        System.debug('Queueable finished');
    }

    private String callPromptTemplate(String noteText) {

        System.debug('Calling AI with: ' + noteText);
        ConnectApi.WrappedValue wrappedInput = new ConnectApi.WrappedValue();
        wrappedInput.value = noteText;

        Map<String, ConnectApi.WrappedValue> inputParams =
            new Map<String, ConnectApi.WrappedValue>();

        inputParams.put('Input:notetext', wrappedInput);
		
		ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;
        
        try {
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                        'Visit_Note_Analysis',
                        executeTemplateInput
                    );
                if (generationsOutput != null && 
                    generationsOutput.generations != null && 
                    !generationsOutput.generations.isEmpty()) {
                    
                    ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
                    String rawResponse = response.text;
                		return rawResponse;
                    }
        
            } catch (Exception e) {
                System.debug('Error calling Einstein Prompt Template: ' + e.getMessage());
            }
            return 'Some Error Occured';
    }
}