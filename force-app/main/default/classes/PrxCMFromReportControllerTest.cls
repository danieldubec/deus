@isTest
private class PrxCMFromReportControllerTest {

       
    static Account testAccount;

    @TestSetup
    static void setup() {
        // Create a test campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign');
        insert testCampaign;

        // Create a test account
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        
        // Create a test contact linked to the account
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', AccountId = testAccount.Id);
        insert testContact;

        // Create a report (you would need to manually create or reference an existing report)
        // For simplicity, we're assuming there's a report in the org.
    }

    @IsTest
    static void testAddCampaignMembersFromReport_Success() {
        // Mock report results (you need to mock the structure of Reports.ReportResults)
        Test.startTest();

        // Use Test.setMock() if mocking Reports.ReportManager.runReport (use a mocking framework if available)
        // For simplicity, we directly assume a report ID and continue with testing logic.
        
        Id campaignId = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign' LIMIT 1].Id;
        Id reportId = '00OJ500000133cAMAQ'; // Replace with a real report ID from your org

        Integer successfulInserts = PrxCampaignMembersFromReportController.addCampaignMembersFromReport(campaignId, reportId, false);

        Test.stopTest();

        // Assert results
        System.assertEquals(1, successfulInserts, 'There should be one successful insert');
    }

    @IsTest
    static void testAddCampaignMembersFromReport_NoAccountColumn() {
        Test.startTest();
        
        Id campaignId = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign' LIMIT 1].Id;
        Id reportId = '00OJ500000133hAMAQ'; // Replace with a real report ID

        try {
            PrxCampaignMembersFromReportController.addCampaignMembersFromReport(campaignId, reportId, false);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(true,'Exception should have been thrown');
        }        

        Test.stopTest();
    }

    @isTest
    static void testGetReportFolder() {

        String reportFolder = PrxCampaignMembersFromReportController.getReportFolder();
        System.assertNotEquals('Campaign Member Reports', reportFolder);
    }   

    @isTest
    static void testGetReportFolderDeveloperName() {
        String developerName = 'ReportsForCampaigns';
        Test.startTest();
        String reportFolder = PrxCampaignMembersFromReportController.getReportFolderDeveloperName();
        Test.stopTest();
        System.assertEquals(developerName, reportFolder, 'Report folder developer name should match');
    }

    }