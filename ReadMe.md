

Hello,



Here is the workflow and implementation steps for the assignment



On Premise Simulation and Disovery:

\------------------------------------

Copy Code from Github for the app to Laptop

Build Docker Image 

Run Docker Container

Test if App works on Laptop

Collect Stats and lineage

Collect database rowcount validation

Check Application Workflow and document them



Simulation Steps:

\-------------------

On VSCode Bash Terminal, go to C:\\Users\\USER\\code\\database-migration-architect-assessment 

Run the following:

docker-compose -f docker-compose.onprem.yml up -d

On Browser open http://localhost:8080/



Build Azure Components:

\--------------------------

Create Azure container registry to save container app image

Create Azure managed identity and keyvault for passwords and credentials

Create Containerapps and environment, load balancer, Public Ip for app deployment

Create mysql flexible server and database





Migration of Database:

\------------------------

Dump data from onpremise simulation mysql database to a folder

Run migration of data from on premise to azure mysql database

Run validation scripts for rowcount matches etc





CI/CD Pipeline:

\-----------------

Create repo for the migration on github and upload the code from the laptop to github

Create CI/CD pipleline for building, scanning and pushing container to container registry

Create Pipeline to Deploy app to container apps and smoke test





Github Repo:

\----------------

https://github.com/arao-eng/database-migration-architect-assessment





Migrated App:

\----------------

https://petclinic-app.greenrock-e6572175.southeastasia.azurecontainerapps.io/



