# data-warehouse-project
Schema Diagram of the DataWareHouse.
![Screenshot (99)](https://user-images.githubusercontent.com/74343581/169906916-bdddf06c-3a5b-4fee-8df8-4f337069675b.png)

Specification Of Data

The National Health Service (NHS) gives funding each year to local agencies to provide temporary 
staff to cover for doctors and general practitioners when they are either on holiday or absent from 
the workplace due to illness or any other reason.
When a surgery, has a vacancy they contact an agency, by phone, and request a doctor, called a
locum, to cover for a given period, called a session. The agency checks their available locums and 
tries to arrange cover for the vacancy. This locum will be either a GP or a doctor with a particular 
specialism, for example, a paediatrician, optometrist etc. The type of cover is recorded in the 
TYPE_OF_COVER table. When locums register with an agency, their qualifications and references 
will be checked. 

Here Microsoft SQL management studio  is used as a tool to extract data from access database and also for cleaning and datawarehouse creation.
For the prediction of Locum Request Count ARMI model is used and coding is done in jupyter notebook by connecting with sql server.
