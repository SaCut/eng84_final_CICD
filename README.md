# Engineering 84 Final Project - Complete DevOps Pipeline


### Continuous Integration / Continuous Deployment
- Continuous Integration and Continuous Delivery are ways of structuring the development pipeline in order to achieve automation starting from the development team to either the testing phase or the production phase of development.


### Tools
- Jenkins
- Google Apps Scripts
- Gmail
- Git and Git-Hub
- Containers with Docker and Docker Hub
- AWS with EC2 instances and CloudWatch


### Our Pipeline structure

![placeholder](https://github.com/SaCut/eng84_final_CICD/blob/main/images/pipeline.png)


Both our flask and web scraping app piplines adhere to the above diagram, by implementing this pipeline structure we successfully created end to end automation.


***How do we do it on jenkins?***  


1. Create a Job that pulls from the dev branch based on a webhook  


2. Use that job to run `pythom -m pytest ./tests`  


3. On pass run the next job, on fail notify the team  


4. Create job 2, to merge dev into main using jenkins git publisher  


5. Create a Job that pulls from the main branch based on a webhook  


6. Use this job to containerise the application and push it to dockerhub  


7. Create a job activated by the push to dockerhub  


8. Access our ec2 instances and update the container that is running  


### How do we dockerize an application  


* Choose a base image, slim if available  

* Set a work directory  

* Perform installation commands using RUN  

* Copy required files for the project over  

* Set the launch command using `CMD`  

```
FROM python:3.8-slim

WORKDIR /usr/src/app

RUN apt-get update -y

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY  ./ /usr/src/app

RUN mkdir /root/Downloads
RUN touch /root/DownloadsItJobsWatchTop30.csv

CMD [ "python",  "-m", "pytest", "tests/", "-v"]
```

