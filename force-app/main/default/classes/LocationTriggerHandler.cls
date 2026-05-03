public class LocationTriggerHandler {

    // Prevent recursion
    private static Boolean isRunning = false;

    public static void calculateDemandScore(List<Schema.Location> triggerRecords) {

        if (isRunning) return;
        isRunning = true;

        // 1) Aggregate MIN/MAX
        AggregateResult agg = [
            SELECT 
                MIN(Avg_Revenue__c) minRev,
                MAX(Avg_Revenue__c) maxRev,
                MIN(Avg_FootFall__c) minFootfall,
                MAX(Avg_FootFall__c) maxFootfall,
                MIN(Avg_Setup_Cost__c) minSetup,
                MAX(Avg_Setup_Cost__c) maxSetup,
                MIN(Avg_Payback_Period__c) minPayback,
                MAX(Avg_Payback_Period__c) maxPayback,
                MIN(Population__c) minPopulation,
                MAX(Population__c) maxPopulation,
                MIN(Per_Capita_Income__c) minIncome,
                MAX(Per_Capita_Income__c) maxIncome,
            	MIN(No_of_Competitors__c) minCompetition,
            	MAX(No_of_Competitors__c) maxCompetition
            	
            FROM Location
        ];

        Decimal minRev = (Decimal) agg.get('minRev');
        Decimal maxRev = (Decimal) agg.get('maxRev');
        Decimal minFootfall = (Decimal) agg.get('minFootfall');
        Decimal maxFootfall = (Decimal) agg.get('maxFootfall');
        Decimal minSetup = (Decimal) agg.get('minSetup');
        Decimal maxSetup = (Decimal) agg.get('maxSetup');
        Decimal minPayback = (Decimal) agg.get('minPayback');
        Decimal maxPayback = (Decimal) agg.get('maxPayback');
        Decimal minPopulation = (Decimal) agg.get('minPopulation');
        Decimal maxPopulation = (Decimal) agg.get('maxPopulation');
        Decimal minIncome = (Decimal) agg.get('minIncome');
        Decimal maxIncome = (Decimal) agg.get('maxIncome');
        Decimal minCompetition = (Decimal) agg.get('minCompetition');
        Decimal maxCompetition = (Decimal) agg.get('maxCompetition');

        // 2) Custom Setting
        Custom_Set__c customSet = Custom_Set__c.getValues('Global');

        Boolean recalculateAll = false;

        if (customSet == null ||
            customSet.Min_Revenue__c != minRev || customSet.Max_Revenue__c != maxRev ||
            customSet.Min_Footfall__c != minFootfall || customSet.Max_Footfall__c != maxFootfall ||
            customSet.Min_Setup_Cost__c != minSetup || customSet.Max_Setup_Cost__c != maxSetup ||
            customSet.Min_Payback__c != minPayback || customSet.Max_Payback__c != maxPayback ||
            customSet.Min_Population__c != minPopulation || customSet.Max_Population__c != maxPopulation ||
            customSet.Min_Income__c != minIncome || customSet.Max_Income__c != maxIncome ||
            customSet.Min_Competitors__c != minCompetition || customSet.Max_Competitors__c != maxCompetition
        ) {
            recalculateAll = true;
           
        }
		 System.debug('Recal Value:'+recalculateAll);
        // 3) Scope (ALWAYS query — never use trigger records directly for DML)
        List<Schema.Location> scope;

        if (recalculateAll) {
            scope = [
                SELECT Id, Avg_Revenue__c, Avg_FootFall__c, Avg_Setup_Cost__c,
                       Avg_Payback_Period__c, Population__c, Per_Capita_Income__c,
                       Demand_Score__c,No_of_Competitors__c,Competition_Level__c,Competiton_Score__c,Name
                FROM Location
            ];
        } else {
            Set<Id> ids = new Map<Id, Schema.Location>(triggerRecords).keySet();

            scope = [
                SELECT Id, Avg_Revenue__c, Avg_FootFall__c, Avg_Setup_Cost__c,
                       Avg_Payback_Period__c, Population__c, Per_Capita_Income__c,
                       Demand_Score__c,No_of_Competitors__c,Competition_Level__c,Competiton_Score__c,Name
                FROM Location
                WHERE Id IN :ids
            ];
        }

        List<Schema.Location> updatedList = new List<Schema.Location>();

        for (Schema.Location loc : scope) {

            if (loc.Id == null) continue; // safety

            Decimal normRev = normalize(loc.Avg_Revenue__c, minRev, maxRev);
            Decimal normFootfall = normalize(loc.Avg_FootFall__c, minFootfall, maxFootfall);
            Decimal normPopulation = normalize(loc.Population__c, minPopulation, maxPopulation);
            Decimal normIncome = normalize(loc.Per_Capita_Income__c, minIncome, maxIncome);
            Decimal normSetup = normalize(loc.Avg_Setup_Cost__c, minSetup, maxSetup);
            Decimal normPayback = normalize(loc.Avg_Payback_Period__c, minPayback, maxPayback);
            //Decimal normCompetitors = normalize(loc.No_of_Competitors__c, minCompetition, maxCompetition);

            Decimal setupScore = 1 - normSetup; //(Setup Score is inverse of Setup Cost) --> low setup Cost = High Demand 
            Decimal paybackScore = 1 - normPayback; //(Payback score is inverse of payback period) --> low payback period = High Demand
            
            //Decimal revenuePressure = 1 - normRev;   // (Revenue Pressure is inverse of Revenue) --> lower revenue = higher competition

            //final demand score calculation
            Decimal finalScore = (
                (normFootfall * 0.25) +
                (normRev * 0.20) +
                (normPopulation * 0.15) +
                (normIncome * 0.10) +
                (paybackScore * 0.15) +
                (setupScore * 0.15)
            ) * 100;
			
            //competiton score calculation
            //Decimal competitionScore = loc.No_of_Competitors__c;
            
            //competion level calulcation from competiton score
            String competitionLevel;
            if (loc.No_of_Competitors__c > 8) {
                competitionLevel = 'High';
            } else if (loc.No_of_Competitors__c > 4) {
                competitionLevel = 'Medium';
            } else {
                competitionLevel = 'Low';
            }
            
            System.debug('final Demand score has changed for location  '+loc.Name+' from  : '+loc.Demand_Score__c+'-->'+finalScore);
            System.debug('No. of Competitors for location '+loc.Name+' : '+loc.No_of_Competitors__c);
            System.debug('final Competiton Level has changed for location  '+loc.Name+' from  : '+loc.Competition_Level__c+'-->'+competitionLevel);
            System.debug('--------------------------------------------------------------------------------------------------');
            finalScore = finalScore.setScale(2);
			
            // ONLY update if changed (prevents recursion + unnecessary DML)
            if (loc.Demand_Score__c != finalScore || loc.Competition_Level__c != competitionLevel) {
                
                
                loc.Demand_Score__c = finalScore;
                loc.Competition_Level__c  = competitionLevel;
                //loc.Competiton_Score__c = competitionScore;
                updatedList.add(loc);    
            }
        }

        if (!updatedList.isEmpty()) {
            update updatedList;
        }

        // 4) Update Custom Setting (use UPSERT, not update)
        if (recalculateAll) {
            Custom_Set__c cs = Custom_Set__c.getInstance('Global');
                
            cs.Min_Revenue__c = minRev;
            cs.Max_Revenue__c = maxRev;
            cs.Min_Footfall__c = minFootfall;
            cs.Max_Footfall__c = maxFootfall;
            cs.Min_Setup_Cost__c = minSetup;
            cs.Max_Setup_Cost__c = maxSetup;
            cs.Min_Payback__c = minPayback;
            cs.Max_Payback__c = maxPayback;
            cs.Min_Population__c = minPopulation;
            cs.Max_Population__c = maxPopulation;
            cs.Min_Income__c = minIncome;
            cs.Max_Income__c = maxIncome;
            cs.Min_Competitors__c = minCompetition;
            cs.Max_Competitors__c = maxCompetition;
            

            update cs;
        }
    }

    private static Decimal normalize(Decimal value, Decimal min, Decimal max) {
        if (value == null || min == null || max == null || max == min) {
            return 0;
        }
        return (value - min) / (max - min);
    }
}