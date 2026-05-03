import { LightningElement, wire, track } from 'lwc';
import getLocations from '@salesforce/apex/RetailDashboardController.getLocations';
import getDashboardData from '@salesforce/apex/RetailDashboardController.getDashboardData';

import chartJs from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class RetailDashboard extends LightningElement {

    @track locations = [];
    @track selectedLocationId;
    @track dashboardData;

    chart;
    chartInitialized = false;

    get locationOptions() {
        return this.locations.map(loc => ({
            label: loc.Name,
            value: loc.Id
        }));
    }

    @wire(getLocations)
    wiredLocations({ data, error }) {
        if (data) {
            this.locations = data;
        }
    }

    handleChange(event) {
        this.selectedLocationId = event.detail.value;
        this.loadDashboard();
    }

    loadDashboard() {
        getDashboardData({ locationId: this.selectedLocationId })
            .then(result => {
                this.dashboardData = result;
                this.renderChart();
            })
            .catch(error => {
                console.error(error);
            });
    }

    renderedCallback() {
        if (this.chartInitialized) return;

        loadScript(this, chartJs)
            .then(() => {
                this.chartInitialized = true;
            })
            .catch(error => {
                console.error(error);
            });
    }

    renderChart() {
        if (!this.chartInitialized || !this.dashboardData) return;

        const ctx = this.template.querySelector('canvas');

        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Footfall', 'Revenue'],
                datasets: [{
                    data: [
                        this.dashboardData.location.Avg_FootFall__c,
                        this.dashboardData.location.Avg_Revenue__c
                    ]
                }]
            }
        });
    }
}