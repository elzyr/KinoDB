# KinoDB — Distributed Cinema Database 🎬🌐

![PL/SQL](https://img.shields.io/badge/PL%2FSQL-Oracle-red?logo=oracle&logoColor=white)  
![T-SQL](https://img.shields.io/badge/T--SQL-SQL%20Server-blue?logo=microsoft%20sql%20server&logoColor=white)  
![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker&logoColor=white)  

## 📖 Project Description

**KinoDB** is a simulated, **distributed** cinema database spanning two nodes:

- **Oracle** (PL/SQL, object-oriented database model)  
- **SQL Server Master** (T-SQL in a Docker container, relational database)  
- **SQL Server Replica** (T-SQL subscriber with transactional replication)  
- **Excel Workbook** (sample data and analytics)
![diagram](https://github.com/user-attachments/assets/10048c87-acb5-4477-a15c-ce09f0028dec)

> **Note:** SQL Server includes views to flatten and consume the object-oriented data from Oracle for seamless querying.

The goal of this project is to demonstrate:

- Configuration and replication in a distributed data model  
- Cross-database synchronization (DB Links / Linked Servers)  
- Common DDL, DML operations and distributed queries  
- Architecture visualization via ERD and sequence diagrams

---

## 📂 Repository Structure and Diagrams

- `/Oracle` – PL/SQL scripts (DDL, DML, DB Links)  
- `/SQLServer` – T-SQL scripts  
- `/docker` – `docker-compose.yml` + initialization scripts for SQL Server  
- `KinoDB.xlsx` – Excel workbook with sample data and analytics  
- `diagram.png` – ERD of all entities  
- `diagram_sequence.png` – replication sequence diagram

---

## 🛠️ Technologies

- **Databases:** 🐘 Oracle Database & 🦅 Microsoft SQL Server  
- **Containerization:** 🐳 Docker & ⚓ Docker Compose  
- **Scripting Languages:** ✍️ PL/SQL, T-SQL  
- **Tools:** 🛠️ SQL Developer, SSMS / Azure Data Studio, SQL*Plus
