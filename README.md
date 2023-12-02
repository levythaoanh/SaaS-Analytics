# SaaS Analytics

## DESCRIPTIVE
You are working for a company that offers Software as a Service ( SaaS) online. 
Their customers can try the product before purchasing. If the work is too heavy, they must pay first. 

    The transaction of the users is stored in the table events. 
    The information of the users is stored in the table user_info. 
    If the customer account is suspended, the last login date of the user will be recorded, the statistics of the account will be calculated and stored in the table.  
    The geography data contains the country code and the geospatial data in case you want to visualize a map. 


## REQUIREMENT

### Task 1 : 
Descriptive statistics. Overview insights into the service.
Hints : 
How many people use the service each day , how many daily accesses does the service have ? 
What is the average volume of the user’s work ? And the trends over time. 
How many users are there ? Where do they come from ? 

### Task 2 : 
Let day 1 be the day a user first comes to the app, becoming a new user.
How many percent users still use the app after X days (i.e. 1 day, 2 days, etc.) from day 0? 

### Task 3 :
There are many people suspend their account and create a new one after they used up their quota to exploit the glitch for trail usage. As a result, one user can have many different account history.  Please identify the most serious cheater and provide your explaination based on your perspective so that we can ban them from using the service. 

### Task 4 :
Because there are some users that exploit the apps. They access the service too much. As a result, managers want to recalculate the access number. 
If they re-access within 6 hours , it is still counted as 1 access regardless of the actual access number. 
However, the volumes used by customers are still calculated normally. 
Recalculate the access statistics. After recalculating, comment about the difference between the new calculating method and the previous one. 

### Task 5 : Customer Segmentation 
Please perform customer segmentation based on their usage data. You can do whatever you want and please tell us how does our customer look like. 
Hint : You can use analytical models that based on RFM model.
