public with sharing class PrxCampaignMembersFromReportController {    
    private static final String REPORT_FOLDER_DEVELOPER_NAME = 'ReportsForCampaigns';

    @AuraEnabled(cacheable=true)
    public static String getReportFolderDeveloperName() {                
        return REPORT_FOLDER_DEVELOPER_NAME;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getReportFolder() {        
        List<Folder> folders = [SELECT Name FROM Folder WHERE Type = 'Report' AND DeveloperName=:REPORT_FOLDER_DEVELOPER_NAME LIMIT 1];
        if (!folders.isEmpty()) {  
            return folders[0].Name;            
        }
        else {
            return null;
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<Report> getReports() {        
        List<Folder> folders = [SELECT Name FROM Folder WHERE Type = 'Report' AND DeveloperName=:REPORT_FOLDER_DEVELOPER_NAME LIMIT 1];
        if (!folders.isEmpty()) {  
            return [SELECT Id, Name FROM Report WHERE FolderName = :folders[0].Name];            
        }
        else {
            return new List<Report>();
        }
    }

    
    @AuraEnabled    
    public static Integer addCampaignMembersFromReport(Id campaignId, Id reportId, boolean onlyPrimary) {
        // Define a variable to hold the report results
        List<List<String>> reportData = new List<List<String>>();
        
        // Create an instance of the Reports class
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
        Integer size = results.getFactMap().size();
        System.debug('FactMap Size : ' + size);
        
        // Get detail columns
        Reports.ReportMetadata rm = results.getReportMetadata();
        rm.getDetailColumns();
        Integer accountCellIndex = rm.getDetailColumns().indexOf('ACCOUNT.NAME');        
        System.debug('Account Cell Index : ' + accountCellIndex);
        
        if (accountCellIndex < 0)
            throw new AuraHandledException('Report musí obsahovať stĺpec "Account Name"');
        
        Integer successfulInsertCount = 0;
        // Fetch data from report    
        if (size>0) {
            Map<String,Reports.ReportFact>  factMap = results.getFactMap();
            List<Id> accountIds = new List<Id>();

            for (String key : factMap.keySet()) {
                System.debug(key);
                Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)factMap.get(key);                
                
                for (Reports.ReportDetailRow row : factDetails.getRows()) {   
                    Object accountIdValue = row.getDataCells()[accountCellIndex].getValue();
        
                    // Ensure the value is not null and cast to Id before adding
                    if (accountIdValue != null) {
                        accountIds.add((Id) accountIdValue);
                    }                    
                }            
                
                System.debug('Account Ids : ' + accountIds);
            }

            // Use Account IDs to fetch contacts            
            String query = 'SELECT Id, Name FROM Contact WHERE AccountId IN :accountIds AND Email != NULL';
    
            // Add the Primary__c condition only if `onlyPrimary` is true
            if (onlyPrimary) {
                query += ' AND Primary__c = true';
            }
    
            List<Contact> contacts = Database.query(query);
            System.debug('Total Contacts : ' + contacts.size());

            
            List<CampaignMember> newMembers = new List<CampaignMember>();            
            // Step 4: Create only new campaign members from contacts if does not exist
            for (Contact contact : contacts) {                
                CampaignMember member = new CampaignMember();
                member.CampaignId = campaignId;
                member.ContactId = contact.Id;
                newMembers.add(member);                
            }
            
            if (!newMembers.isEmpty()) {
                Database.SaveResult[] dbResults = Database.insert(newMembers, false);
            
                for (Database.SaveResult sr : dbResults) {
                    if (sr.isSuccess()) {
                        successfulInsertCount++;                        
                    } 
                }
            }
        }
        
        if (successfulInsertCount>0) {
            return successfulInsertCount;
        } else {
            throw new AuraHandledException('Nebol pridaný žiadny nový člen kampane');
        }
    }    
}