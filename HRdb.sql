create database if not exists HumanResources;
use HumanResources;

create table Jobs
(
        ID int auto_increment,
        title varchar(150),
        minSalary int,
        maxSalary int,
        constraint PK primary key(ID)
);

create table Employees
(
        kennitala char(10),
        firstname varchar(75),
        lastname varchar(75),
        email varchar(150),
        phoneNumber varchar(12),
        hireDate date,
        salary int,
        job int,
        constraint job_FK foreign key(job)references Jobs(ID),
        constraint PK primary key(kennitala)
);

create table Locations
(
        ID int unique,
        city varchar(150),
        address varchar(150),
        zipCode int,
        constraint PK primary key(ID)
);

create table Departments
(
        ID int unique,
        departmentName varchar(100),
        manager char(10),
        location int,
        constraint manager_FK foreign key(manager)references Employees(kennitala),
        constraint location_FK foreign key(location)references Locations(ID),
        constraint PK primary key(ID)
);