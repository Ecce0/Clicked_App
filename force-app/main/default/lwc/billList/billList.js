import { LightningElement, track, wire } from 'lwc';
import getBills from '@salesforce/apex/BillAPI.getBills';

export default class BillList extends LightningElement {
    @track bills = [];
    @track error;
    searchKey = '';

    @wire(getBills, { searchKey: '$searchKey' })
    wiredBills({ data, error }) {
        if (data) {
            this.bills = data;
            this.error = undefined;
        }  else if (error) {
            // Extracting the error message from the error object
            console.log('Error object:', JSON.stringify(error));  // Log the full error object for inspection
            this.error = error.body ? error.body.message : error.message;
            this.bills = [];
        
        }
    }

    handleSearchChange(event) {
        window.clearTimeout(this.delayTimeout);
        const searchValue = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchValue;
        }, 300);
    }
}


//Salesforce CLI command to deploy
// sfdx force:source:deploy -p force-app/main/default
