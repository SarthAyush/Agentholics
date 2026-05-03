trigger EventRiseTrigger on DataObjectDataChgEvent (after insert) {

    Map<String, Competitor__c> competitorMap = new Map<String, Competitor__c>();
    Set<String> sectorIds = new Set<String>();
    List<Map<String, Object>> payloadList = new List<Map<String, Object>>();

    for (DataObjectDataChgEvent dce : Trigger.new) {

        if (dce.ActionDeveloperName == 'Event_Riser' && dce.PayloadCurrentValue != null) {

            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(dce.PayloadCurrentValue);

            payloadList.add(payload);

            String sectorId = (String) payload.get('competitorDataDMO__dlm_Sector_ID__c');

            if (sectorId != null) {
                sectorIds.add(sectorId);
            }
        }
    }

    Map<String, Id> locationMap = new Map<String, Id>();

 if (!sectorIds.isEmpty()) {
    for (Schema.Location loc : [
      SELECT Id, Location_Code__c
      FROM Location
     WHERE Location_Code__c IN :sectorIds
   ]) {
        locationMap.put(loc.Location_Code__c, loc.Id);
    }
}

    for (Map<String, Object> payload : payloadList) {

        String shopCode = (String) payload.get('competitorDataDMO__dlm_Shop_Code__c');

        if (shopCode == null) continue; 

        Competitor__c comp = competitorMap.containsKey(shopCode)
            ? competitorMap.get(shopCode)
            : new Competitor__c();

        comp.Shop_Code__c = shopCode;
        // comp.Name = (String) payload.get('competitorDataDMO__dlm_Shop_ID__c');

        if (payload.get('competitorDataDMO__dlm_Annual_Revenue_INR__c') != null) {
            comp.Annual_Revenue__c = Decimal.valueOf(String.valueOf(
                payload.get('competitorDataDMO__dlm_Annual_Revenue_INR__c')));
        }

        if (payload.get('competitorDataDMO__dlm_Avg_Daily_Footfall__c') != null) {
            comp.Avg_Daily_Footfall__c = Decimal.valueOf(String.valueOf(
                payload.get('competitorDataDMO__dlm_Avg_Daily_Footfall__c')));
        }

        if (payload.get('competitorDataDMO__dlm_Setup_Cost_INR__c') != null) {
            comp.Setup_Cost__c = Decimal.valueOf(String.valueOf(
                payload.get('competitorDataDMO__dlm_Setup_Cost_INR__c')));
        }

        String sectorId = (String) payload.get('competitorDataDMO__dlm_Sector_ID__c');

        if (sectorId != null && locationMap.containsKey(sectorId)) {
            comp.Location__c = locationMap.get(sectorId);
        }

        competitorMap.put(shopCode, comp);
    }

    if (!competitorMap.isEmpty()) {
        upsert competitorMap.values() Shop_Code__c;
    }
}