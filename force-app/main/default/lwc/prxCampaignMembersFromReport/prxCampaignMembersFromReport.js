import { LightningElement, api, wire } from 'lwc';
import getReports from '@salesforce/apex/PrxCampaignMembersFromReportController.getReports';
import getReportFolder from '@salesforce/apex/PrxCampaignMembersFromReportController.getReportFolder';
import getReportFolderDeveloperName from '@salesforce/apex/PrxCampaignMembersFromReportController.getReportFolderDeveloperName';
import addCampaignMembersFromReport from '@salesforce/apex/PrxCampaignMembersFromReportController.addCampaignMembersFromReport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class PrxCampaignMembersFromReport extends NavigationMixin(LightningElement) {
    @api recordId;
    @api accountFields;
    optReports = [];
    reportId;
    reportFolder;
    reportFolderDeveloperName;
    onlyPrimary = false;
    error;

    connectedCallback() {
    }

    @wire(getReportFolderDeveloperName)
    wiredReportFolderDeveloperName({ error, data }) {
        if (data) {
            this.reportFolderDeveloperName = data;
        } else if (error) {
            console.error('Error fetching reports', error);
            this.error = error;
        }
    }

    @wire(getReportFolder)
    wiredReportFolder({ error, data }) {
        if (data) {
            this.reportFolder = data;
            console.log('Report folder: ' + this.reportFolder);
        } else if (error) {
            console.error('Error fetching reports', error);
            this.error = error;
        }
    }

    @wire(getReports)
    wiredReports({ error, data }) {
        if (data) {
            this.optReports = data.map(report => {
                return { label: report.Name, value: report.Id };
            });
        } else if (error) {
            console.error('Error fetching reports', error);
            this.error = error;
        }
    }

    handleChangeReport(event) {
        this.reportId = event.target.value;
        console.log('Selected report is: ' + this.reportId);
    }

    handlePrimaryContact(event) {
        this.onlyPrimary = event.target.checked;
        console.log('Primary contacts: ' + this.onlyPrimary);
    }

    handleAddSelectedReport() {
        console.log('Try to add members to report');
        const options = new Map();
        options.set('onlyPrimary', this.onlyPrimary);
        options.set('accountFields', this.accountFields);
        // Convert Map to a plain object
        const objectifiedMap = Object.fromEntries(options);

        console.log('objectifiedMap:', objectifiedMap);

        addCampaignMembersFromReport({ campaignId: this.recordId, reportId: this.reportId, options: objectifiedMap })
            .then(data => {
                if (data > 0) {
                    const event = new ShowToastEvent({
                        title: 'Úspešne pridané',
                        variant: 'success',
                        message: 'Počet pridaných členov kampane je ' + data,
                        mode: 'dismissible '
                    });

                    this.dispatchEvent(event);

                    this.refreshView();
                }
            })
            .catch(error => {
                console.error(error);
                const event = new ShowToastEvent({
                    title: 'Upozornenie',
                    variant: 'warning',
                    message: error.body.message,
                    mode: 'dismissible '
                });

                this.dispatchEvent(event);
            })

    }

    refreshView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Campaign',
                actionName: 'view'
            },
        });
    }

    handleNavigateToReportEdit() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.reportId,
                objectApiName: 'Report',
                actionName: 'edit'
            }
        });
    }
}