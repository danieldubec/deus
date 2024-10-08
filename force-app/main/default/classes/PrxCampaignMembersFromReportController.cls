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
    public static Integer addCampaignMembersFromReport(Id campaignId, Id reportId, Map<String,Object> options) {
        System.debug(options);
        // Options
        Boolean onlyPrimary = false;
        if (options.containsKey('onlyPrimary')) {
            onlyPrimary = (Boolean) options.get('onlyPrimary');
        }
        System.debug('onlyPrimary : ' + onlyPrimary);

        String accountFields = 'ACCOUNT.NAME';
        if (options.containsKey('accountFields')) {
            String name = (String) options.get('accountFields');
            accountFields += ',' + name.trim().toUpperCase();
        }
        accountFields = accountFields.trim();
        if (accountFields.endsWith(',')) {
            accountFields = accountFields.left(accountFields.length()-1);
        }

        System.debug('accountFields : ' + accountFields);

        // Account column names
        List<String> columnNames = new List<String>();                
        if (String.isNotBlank(accountFields)) {
            columnNames = accountFields.split(',');            
        }        

        System.debug('Column Names');
        System.debug(columnNames);

        // Define a variable to hold the report results
        List<List<String>> reportData = new List<List<String>>();
        
        // Create an instance of the Reports class
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
        Integer size = results.getFactMap().size();        
        
        // We are looking for column with account in report        
        Reports.ReportMetadata rm = results.getReportMetadata();        
        System.debug('Report columns');
        System.debug(rm.getDetailColumns());

        Integer accountCellIndex = -1;
        for (String column:columnNames) {            
            accountCellIndex = rm.getDetailColumns().indexOf(column);
            // Break loop if we found the account column
            if (accountCellIndex > -1) {
                break;
            }
        }

        System.debug('Account Cell Index : ' + accountCellIndex);
        
        if (accountCellIndex < 0)
            throw new AuraHandledException('Report musí obsahovať jeden zo stĺpcov ' +  accountFields);
        
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