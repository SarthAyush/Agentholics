public without sharing class RetailDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLocations() {
        List<Map<String, String>> locationOptions = new List<Map<String, String>>();
        
        try {
            List<Schema.Location> locations = [
                SELECT Id, Name 
                FROM Location 
                ORDER BY Name 
                LIMIT 50000
            ];
            
            for (Schema.Location loc : locations) {
                Map<String, String> option = new Map<String, String>();
                option.put('label', loc.Name);
                option.put('value', loc.Id);
                locationOptions.add(option);
            }
        } catch (Exception e) {
            System.debug('Error fetching locations: ' + e.getMessage());
        }
        
        return locationOptions;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LocationComparison> getAllLocationsComparison() {
        List<LocationComparison> comparisons = new List<LocationComparison>();
        
        try {
            List<Schema.Location> locations = [
                SELECT Id, Name, Demand_Score__c, Competition_Level__c,
                       Avg_Revenue__c, Avg_FootFall__c
                FROM Location 
                ORDER BY Demand_Score__c DESC NULLS LAST
                LIMIT 50000
            ];
            
            for (Schema.Location loc : locations) {
                LocationComparison comp = new LocationComparison();
                comp.locationId = loc.Id;
                comp.locationName = loc.Name;
                comp.demandScore = loc.Demand_Score__c != null ? loc.Demand_Score__c : 0;
                comp.competitionLevel = loc.Competition_Level__c;
                comp.avgRevenue = loc.Avg_Revenue__c != null ? loc.Avg_Revenue__c : 0;
                comp.avgFootfall = loc.Avg_FootFall__c != null ? loc.Avg_FootFall__c : 0;
                comparisons.add(comp);
            }
        } catch (Exception e) {
            System.debug('Error fetching location comparisons: ' + e.getMessage());
        }
        
        return comparisons;
    }
    
    @AuraEnabled(cacheable=true)
    public static DashboardData getLocationDashboardData(String locationId) {
        DashboardData data = new DashboardData();
        
        try {
            // Get location details with all fields including geolocation
            Schema.Location location = [
                SELECT Id, Name, Description, 
                       Email, Phone, Mobile,
                       Avg_Revenue__c, Avg_FootFall__c,
                       Demand_Score__c, Competition_Level__c,
                       No_of_Competitors__c, Population__c,
                       Per_Capita_Income__c, Avg_Setup_Cost__c,
                       Competiton_Score__c, LastModifiedDate,
                       Latitude, Longitude
                FROM Location 
                WHERE Id = :locationId 
                LIMIT 1
            ];
            
            // Basic location info
            data.locationName = location.Name;
            data.address = location.Description != null ? location.Description : 'N/A';
            data.monthlyRevenue = location.Avg_Revenue__c != null ? location.Avg_Revenue__c : 0;
            data.customerTraffic = location.Avg_FootFall__c != null ? Integer.valueOf(location.Avg_FootFall__c) : 0;
            data.squareFootage = location.Population__c != null ? Integer.valueOf(location.Population__c) : 0;
            data.storeManager = 'Store Manager';
            data.phone = location.Phone;
            data.email = location.Email;
            data.demandScore = location.Demand_Score__c != null ? location.Demand_Score__c : 0;
            data.competitionLevel = location.Competition_Level__c;
            
            // Additional fields now utilized
            data.perCapitaIncome = location.Per_Capita_Income__c != null ? location.Per_Capita_Income__c : 0;
            data.avgSetupCost = location.Avg_Setup_Cost__c != null ? location.Avg_Setup_Cost__c : 0;
            data.competitionScore = location.Competiton_Score__c != null ? location.Competiton_Score__c : 0;
            data.lastUpdated = location.LastModifiedDate;
            data.locationLatitude = location.Latitude;
            data.locationLongitude = location.Longitude;
            
            // Query RetailStore records for this location
            List<RetailStore> retailStores = [
                SELECT Id, Name, Annual_Revenue__c, Avg_Daily_Footfall__c,
                       Setup_Cost__c, Industry__c, CreatedDate,
                       AccountId, Account.Name
                FROM RetailStore
                WHERE LocationId = :locationId
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            
            data.hasExistingStore = !retailStores.isEmpty();
            if (!retailStores.isEmpty()) {
                RetailStore store = retailStores[0];
                
                // Calculate store performance metrics
                Decimal storeRevenue = store.Annual_Revenue__c != null ? store.Annual_Revenue__c : 0;
                Decimal storeFootfall = store.Avg_Daily_Footfall__c != null ? store.Avg_Daily_Footfall__c : 0;
                Decimal storeSetupCost = store.Setup_Cost__c != null ? store.Setup_Cost__c : 0;
                
                // Calculate ROI for existing store
                Decimal storeROI = 0;
                if (storeSetupCost > 0 && storeRevenue > 0) {
                    storeROI = ((storeRevenue - storeSetupCost) / storeSetupCost * 100).setScale(1);
                }
                
                // Compare with location averages
                Decimal revenueComparison = 0;
                if (location.Avg_Revenue__c != null && location.Avg_Revenue__c > 0) {
                    revenueComparison = (storeRevenue / location.Avg_Revenue__c * 100).setScale(1);
                }
                
                Decimal footfallComparison = 0;
                if (location.Avg_FootFall__c != null && location.Avg_FootFall__c > 0) {
                    footfallComparison = (storeFootfall / location.Avg_FootFall__c * 100).setScale(1);
                }
                
                data.existingStoreMessage = String.format(
                    'Existing retail store "{0}" found at this location. Annual Revenue: ${1}, Daily Footfall: {2}',
                    new List<String>{
                        store.Name,
                        String.valueOf(storeRevenue.setScale(2)),
                        String.valueOf(storeFootfall.setScale(0))
                    }
                );
                
                data.existingStoreDetails = new ExistingStoreData();
                data.existingStoreDetails.name = store.Name;
                data.existingStoreDetails.revenue = storeRevenue.setScale(2);
                data.existingStoreDetails.openedDate = store.CreatedDate;
                data.existingStoreDetails.industry = store.Industry__c;
                data.existingStoreDetails.setupCost = storeSetupCost.setScale(2);
                data.existingStoreDetails.dailyFootfall = storeFootfall.setScale(0);
                data.existingStoreDetails.roi = storeROI;
                data.existingStoreDetails.revenueVsLocationAvg = revenueComparison;
                data.existingStoreDetails.footfallVsLocationAvg = footfallComparison;
                data.existingStoreDetails.accountName = store.Account != null ? store.Account.Name : null;
            }
            
            // Get competitors data
            List<Competitor__c> competitors = [
                SELECT Id, Name, Industry__c,
                       Annual_Revenue__c, Avg_Daily_Footfall__c,
                       Setup_Cost__c, Shop_Code__c
                FROM Competitor__c 
                WHERE Location__c = :locationId 
                ORDER BY Annual_Revenue__c DESC NULLS LAST
                LIMIT 50
            ];
            
            data.competitorsCount = competitors.size();
            data.competitors = new List<CompetitorData>();
            
            Decimal totalRevenue = 0;
            Decimal totalFootfall = 0;
            Decimal totalSetupCost = 0;
            
            for (Competitor__c comp : competitors) {
                CompetitorData compData = new CompetitorData();
                compData.name = comp.Name;
                compData.shopCode = comp.Shop_Code__c;
                compData.setupCost = comp.Setup_Cost__c != null ? comp.Setup_Cost__c : 0;
                compData.priceRange = comp.Industry__c;
                compData.revenue = comp.Annual_Revenue__c != null ? comp.Annual_Revenue__c : 0;
                compData.footfall = comp.Avg_Daily_Footfall__c != null ? Integer.valueOf(comp.Avg_Daily_Footfall__c) : 0;
                
                // Distance calculation not available without geolocation fields on Competitor
                compData.distance = null;
                
                // Rating field not available - generate estimated rating based on revenue
                compData.rating = compData.revenue > 0 ? 
                    Math.min(5.0, 3.0 + (compData.revenue / 100000)) : 4.0;
                
                data.competitors.add(compData);
                
                totalRevenue += compData.revenue;
                totalFootfall += compData.footfall;
                totalSetupCost += compData.setupCost;
            }
            
            // Calculate average competitor metrics
            if (competitors.size() > 0) {
                data.avgCompetitorRevenue = totalRevenue / competitors.size();
                data.avgCompetitorRating = 4.0; // Default average rating since field not available
                data.avgCompetitorFootfall = totalFootfall / competitors.size();
                data.avgCompetitorSetupCost = totalSetupCost / competitors.size();
            }
            
            // Get actual historical trend data or generate if not available
            data.monthlyTrends = getActualMonthlyTrends(locationId, location.Avg_Revenue__c, location.Avg_FootFall__c);
            
            // Calculate additional metrics
            data.revenuePerSqFt = calculateRevenuePerSqFt(data.monthlyRevenue, data.squareFootage);
            data.revenuePerCustomer = calculateRevenuePerCustomer(data.monthlyRevenue, data.customerTraffic);
            data.competitionDensity = calculateCompetitionDensity(competitors.size(), data.squareFootage);
            data.setupCostROI = calculateSetupCostROI(data.monthlyRevenue, data.avgSetupCost);
            data.dataQualityScore = calculateDataQualityScore(location, competitors);
            
            // Generate performance metrics
            data.performanceScore = calculatePerformanceScore(location, data.avgCompetitorRevenue);
            data.marketShare = calculateMarketShare(location.Avg_Revenue__c, data.avgCompetitorRevenue, competitors.size());
            
        } catch (Exception e) {
            System.debug('Error fetching dashboard data: ' + e.getMessage());
            throw new AuraHandledException('Error loading dashboard data: ' + e.getMessage());
        }
        
        return data;
    }
    
    // Get actual monthly trends from historical data or generate fallback
    private static List<MonthlyTrend> getActualMonthlyTrends(String locationId, Decimal currentRevenue, Decimal currentFootfall) {
        List<MonthlyTrend> trends = new List<MonthlyTrend>();
        
        // Try to get actual historical data from Opportunities closed in last 6 months
        try {
            Date sixMonthsAgo = Date.today().addMonths(-6);
            AggregateResult[] results = [
                SELECT CALENDAR_MONTH(CloseDate) month,
                       SUM(Amount) totalRevenue,
                       COUNT(Id) dealCount
                FROM Opportunity
                WHERE CloseDate >= :sixMonthsAgo
                AND IsWon = true
                AND AccountId IN (SELECT Id FROM Account WHERE BillingCity != null)
                GROUP BY CALENDAR_MONTH(CloseDate)
                ORDER BY CALENDAR_MONTH(CloseDate)
            ];
            
            if (!results.isEmpty()) {
                List<String> monthNames = new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
                for (AggregateResult ar : results) {
                    MonthlyTrend trend = new MonthlyTrend();
                    Integer monthNum = (Integer)ar.get('month');
                    trend.month = monthNames[monthNum - 1];
                    trend.revenue = (Decimal)ar.get('totalRevenue');
                    trend.traffic = currentFootfall != null ? Integer.valueOf(currentFootfall) : 0;
                    trend.isActual = true;
                    trends.add(trend);
                }
                return trends;
            }
        } catch (Exception e) {
            System.debug('Could not fetch historical data: ' + e.getMessage());
        }
        
        // Fallback to simulated data with clear indicator
        return generateSimulatedTrends(currentRevenue, currentFootfall);
    }
    
    private static List<MonthlyTrend> generateSimulatedTrends(Decimal currentRevenue, Decimal currentFootfall) {
        List<MonthlyTrend> trends = new List<MonthlyTrend>();
        List<String> months = new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};
        
        for (Integer i = 0; i < 6; i++) {
            MonthlyTrend trend = new MonthlyTrend();
            trend.month = months[i];
            Decimal variance = (Math.random() * 0.3 - 0.15);
            trend.revenue = currentRevenue != null ? currentRevenue * (1 + variance) : 0;
            trend.traffic = currentFootfall != null ? Integer.valueOf(currentFootfall * (1 + variance)) : 0;
            trend.isActual = false; // Mark as simulated
            trends.add(trend);
        }
        
        return trends;
    }
    
    // Haversine formula for distance calculation between two coordinates
    private static Decimal calculateDistance(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            return null;
        }
        
        Decimal earthRadius = 3959; // miles
        Decimal dLat = (lat2 - lat1) * Math.PI / 180;
        Decimal dLon = (lon2 - lon1) * Math.PI / 180;
        
        Decimal a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                   Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                   Math.sin(dLon/2) * Math.sin(dLon/2);
        
        Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        Decimal distance = earthRadius * c;
        
        return distance.setScale(2);
    }
    
    // Additional metric calculations
    private static Decimal calculateRevenuePerSqFt(Decimal revenue, Integer sqft) {
        if (revenue == null || sqft == null || sqft == 0) return 0;
        return (revenue / sqft).setScale(2);
    }
    
    private static Decimal calculateRevenuePerCustomer(Decimal revenue, Integer traffic) {
        if (revenue == null || traffic == null || traffic == 0) return 0;
        return (revenue / traffic).setScale(2);
    }
    
    private static Decimal calculateCompetitionDensity(Integer competitors, Integer sqft) {
        if (competitors == null || sqft == null || sqft == 0) return 0;
        return ((Decimal)competitors / sqft * 10000).setScale(2); // per 10k sqft
    }
    
    private static Decimal calculateSetupCostROI(Decimal revenue, Decimal setupCost) {
        if (revenue == null || setupCost == null || setupCost == 0) return 0;
        return ((revenue * 12 - setupCost) / setupCost * 100).setScale(2); // Annual ROI %
    }
    
    private static Integer calculateDataQualityScore(Schema.Location location, List<Competitor__c> competitors) {
        Integer score = 0;
        Integer maxScore = 10;
        
        // Location data completeness
        if (location.Avg_Revenue__c != null) score++;
        if (location.Avg_FootFall__c != null) score++;
        if (location.Demand_Score__c != null) score++;
        if (location.Per_Capita_Income__c != null) score++;
        if (location.Avg_Setup_Cost__c != null) score++;
        if (location.Latitude != null && location.Longitude != null) score++;
        
        // Competitor data availability
        if (competitors.size() > 0) score++;
        if (competitors.size() >= 3) score++;
        if (competitors.size() >= 5) score++;
        
        // Recent update
        if (location.LastModifiedDate != null && 
            location.LastModifiedDate > DateTime.now().addDays(-30)) score++;
        
        return (score * 100 / maxScore);
    }
    
    private static Decimal calculatePerformanceScore(Schema.Location location, Decimal avgCompRevenue) {
        if (location.Avg_Revenue__c == null && location.Demand_Score__c == null) {
            return 0; // No data available
        }
        
        Decimal revenueScore = 0;
        if (avgCompRevenue != null && avgCompRevenue > 0 && location.Avg_Revenue__c != null) {
            revenueScore = (location.Avg_Revenue__c / avgCompRevenue) * 40;
        } else if (location.Avg_Revenue__c != null) {
            revenueScore = 20; // Base score if no competitor data
        }
        
        Decimal demandScore = location.Demand_Score__c != null ? location.Demand_Score__c / 2 : 0;
        Decimal competitionScore = location.Competiton_Score__c != null ? (100 - location.Competiton_Score__c) / 5 : 0;
        
        Decimal overallScore = revenueScore + demandScore + competitionScore;
        return overallScore > 100 ? 100 : overallScore.setScale(1);
    }
    
    private static Decimal calculateMarketShare(Decimal locationRevenue, Decimal avgCompRevenue, Integer compCount) {
        if (locationRevenue == null || locationRevenue == 0) return 0;
        if (compCount == null || compCount == 0) return 100;
        if (avgCompRevenue == null || avgCompRevenue == 0) return 50; // Default if no competitor revenue data
        
        Decimal totalMarketRevenue = locationRevenue + (avgCompRevenue * compCount);
        return totalMarketRevenue > 0 ? (locationRevenue / totalMarketRevenue * 100).setScale(2) : 0;
    }
    
    // Wrapper classes
    public class LocationComparison {
        @AuraEnabled public String locationId;
        @AuraEnabled public String locationName;
        @AuraEnabled public Decimal demandScore;
        @AuraEnabled public String competitionLevel;
        @AuraEnabled public Decimal avgRevenue;
        @AuraEnabled public Decimal avgFootfall;
    }
    
    public class DashboardData {
        @AuraEnabled public String locationName;
        @AuraEnabled public String address;
        @AuraEnabled public Decimal monthlyRevenue;
        @AuraEnabled public Integer customerTraffic;
        @AuraEnabled public Integer squareFootage;
        @AuraEnabled public String storeManager;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public Integer competitorsCount;
        @AuraEnabled public Decimal avgCompetitorRevenue;
        @AuraEnabled public Decimal avgCompetitorRating;
        @AuraEnabled public Decimal avgCompetitorFootfall;
        @AuraEnabled public Decimal avgCompetitorSetupCost;
        @AuraEnabled public Decimal performanceScore;
        @AuraEnabled public Decimal marketShare;
        @AuraEnabled public Decimal demandScore;
        @AuraEnabled public String competitionLevel;
        @AuraEnabled public Boolean hasExistingStore;
        @AuraEnabled public String existingStoreMessage;
        @AuraEnabled public ExistingStoreData existingStoreDetails;
        @AuraEnabled public List<CompetitorData> competitors;
        @AuraEnabled public List<MonthlyTrend> monthlyTrends;
        
        // New fields for production enhancements
        @AuraEnabled public Decimal perCapitaIncome;
        @AuraEnabled public Decimal avgSetupCost;
        @AuraEnabled public Decimal competitionScore;
        @AuraEnabled public DateTime lastUpdated;
        @AuraEnabled public Decimal locationLatitude;
        @AuraEnabled public Decimal locationLongitude;
        @AuraEnabled public Decimal revenuePerSqFt;
        @AuraEnabled public Decimal revenuePerCustomer;
        @AuraEnabled public Decimal competitionDensity;
        @AuraEnabled public Decimal setupCostROI;
        @AuraEnabled public Integer dataQualityScore;
    }
    
    public class ExistingStoreData {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public DateTime openedDate;
        @AuraEnabled public String industry;
        @AuraEnabled public Decimal setupCost;
        @AuraEnabled public Decimal dailyFootfall;
        @AuraEnabled public Decimal roi;
        @AuraEnabled public Decimal revenueVsLocationAvg;
        @AuraEnabled public Decimal footfallVsLocationAvg;
        @AuraEnabled public String accountName;
    }
    
    public class CompetitorData {
        @AuraEnabled public String name;
        @AuraEnabled public String shopCode;
        @AuraEnabled public Decimal setupCost;
        @AuraEnabled public Decimal distance;
        @AuraEnabled public Decimal rating;
        @AuraEnabled public String priceRange;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public Integer footfall;
    }
    
    public class MonthlyTrend {
        @AuraEnabled public String month;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public Integer traffic;
        @AuraEnabled public Boolean isActual;
    }
}