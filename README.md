# Retail Store Management Database Project 2

**Team Members:**  
Joanne Lee, Arian Mazloom, Bryson Tanner, Jack Cramer, Richard Kimmig  

---

##  Scenario Description

The data model we created is designed to maintain comprehensive records essential for keeping our retail store operations efficient and organized. It contains all information regarding **suppliers, products, departments, aisles, stores, employees, and work shifts**.

To begin with, the supplier data allows us to track each supplier’s **location and name**, ensuring products arrive on time and in excellent condition. Once the products are received, they are organized by **aisle and department**, giving customers an easy and accessible shopping experience.

Each store is composed of multiple departments, which creates an environment that allows shoppers to find various products without visiting multiple locations. Finally, the model includes detailed employee information such as **hire dates, managers, shifts, and wages**, which helps maintain clean employment records and a clear chain of command.

This database provides the foundation for operational efficiency, workforce management, and data-driven decision-making across our business.

---

##  Data Model
  
![Data Model](DatabaseUpdated.png)

**Data Model**

The data model represents the structure and relationships of a grocery store database. It organizes how the store tracks its departments, employees, products, suppliers, and daily operations like shifts and aisles.

At its core, the Store entity connects to multiple Departments, each overseeing a specific category of goods (e.g., Dairy, Produce, Bakery).
Each Department employs multiple Employees, with one serving as the Department Manager. Employees work various Shifts, which are tracked in a many-to-many relationship via the Shift_has_Employees table.

Aisles represent physical areas in the store where products are displayed. Departments are linked to aisles through the Department_has_Aisle table, showing which departments are responsible for which sections.

Suppliers provide products to the store. Each supplier delivers goods that fall under different Product Categories, which are located in specific aisles.
The Products table ties this information together, linking each item to its supplier and product category.

Relationships

- Store → Department: One store has many departments (1:N)
- Department → Employee: One department has many employees (1:N)
- Employee → Shift: Many employees can work many shifts (M:N via Shift_has_Employees)
- Department → Aisle: Many departments can be responsible for many aisles (M:N via Department_has_Aisle)
- Aisle → Product_Category: Each aisle can contain multiple product categories (1:N)
- Product_Category → Product: Each category contains many products (1:N)
- Supplier → Product: Each supplier provides many products (1:N)

**Data Supported**

The database supports storage of:
  - Store locations and departments
  - Employee details, roles, and work schedules
  - Department–aisle assignments
  - Product information (name, category, supplier)
  - Supplier details and sourcing information

**Data Not Supported**

The database does not store:
  - Customer or sales transaction data
  - Real-time inventory counts or restock tracking
  - Product pricing, promotions, or discounts
  - Customer loyalty or membership information
  - Financial or accounting data

---

##  Data Dictionary

| Table Name | Key Fields | Description |
|-------------|-------------|--------------|
| **Store** | `idStore`, `location`, `year_opened` | Contains store-level data. |
| **Aisle** | `aisle_num`, `aisle_name`, `capacity` | Defines aisles and their capacity. |
| **Department** | `departmentid`, `department_name`, `storeid` | Organizes store departments. |
| **Employees** | `employeeid`, `first_name`, `last_name`, `hire_date`, `hourly_wage`, `managerid`, `departmentid`, `storeid` | Stores all employee and management details. |
| **Supplier** | `supplierid`, `supplier_name`, `city` | Tracks supplier information and location. |
| **Products** | `productid`, `Supplier_supplierid`, `Product_Category_product_categoryid` | Links products to suppliers and categories. |
| **Shift** | `shiftid`, `start_time`, `end_time` | Represents working hours for each shift. |
| **Shift_has_Employees** | `Shift_shiftid`, `Employees_employeeid`, `shift_date` | Links employees to specific shifts and dates. |
| **Department_has_Aisle** | `Department_departmentid`, `Aisle_aisle_num`, `Department_Store_idStore` | Connects aisles to departments within stores. |

[View Data Dictionary (PDF)](Data_Dictionary.pdf)
### *Please click the link above to see the full dictionary* 

---

##  SQL Queries

Below are the SQL queries developed for managerial insights.  
Each query includes a **description** and **justification** to explain its business relevance.

---

### 1. Find departments with labor cost per hour exceeding the store average labor cost per hour
```sql
SELECT 
    Department.departmentid,
    Department.department_name,
    Department.storeid,
    SUM(Employees.hourly_wage) AS total_department_wages,
    AVG(Employees.hourly_wage) AS avg_department_wage,
    Store_Averages.store_avg_wage
FROM Department
JOIN Employees 
    ON Department.departmentid = Employees.departmentid
JOIN (
    SELECT 
        storeid, 
        AVG(hourly_wage) AS store_avg_wage
    FROM Employees
    GROUP BY storeid
) AS Store_Averages
    ON Store_Averages.storeid = Department.storeid
GROUP BY 
    Department.departmentid,
    Department.department_name, 
    Department.storeid,
    Store_Averages.store_avg_wage
HAVING 
    AVG(Employees.hourly_wage) > Store_Averages.store_avg_wage;
```
**Description**: 
- This query compares each department’s average hourly wage to the overall store average. It identifies departments where employee wages are higher than the norm. This supports labor cost monitoring and helps managers understand which departments may require closer salary review or restructuring.
  
**Justification**:
- Highlights departments that contribute disproportionately to labor expenses.
- Helps managers make informed decisions about budgeting, wage adjustments, and staffing levels.
- Supports financial planning by identifying areas that may impact store profitability.
  
### 2. Identify employees who supervise more than the average amount of employees per department
```sql
SELECT 
    Employees.employeeid AS manager_id,
    Employees.first_name,
    Employees.last_name,
    COUNT(Subordinates.employeeid) AS num_subordinates,
    COUNT(DISTINCT Subordinates.departmentid) AS num_departments_supervised
FROM Employees
JOIN Employees AS Subordinates 
    ON Employees.employeeid = Subordinates.managerid
GROUP BY 
    Employees.employeeid,
    Employees.first_name,
    Employees.last_name
HAVING 
    COUNT(Subordinates.employeeid) > 
		(SELECT AVG(sub_count)
        FROM (
            SELECT 
                COUNT(Subordinates.employeeid) AS sub_count
            FROM Employees
            JOIN Employees AS Subordinates
                ON Employees.employeeid = Subordinates.managerid
            GROUP BY Employees.employeeid
        ) AS avg_subordinate_counts
    );
```
**Description**:
- This query identifies managers who oversee more than the average in relation to other managers. It provides a clear view of employee supervision workload and helps determine organizational hierarchy and role distribution.

**Justification**:
- Identifies managers carrying heavier or more complex workloads.
- Helps assess whether responsibilities are balanced across leadership staff.
- Supports HR decisions regarding promotions, support staffing, or redistribution of responsibilities.
  
### 3. Determine departments with the highest product variety based on aisle assignments
```sql
SELECT
    DeptVariety.department_name,
    DeptVariety.storeid,
    DeptVariety.total_product_categories
FROM (
    SELECT 
        Department.department_name,
        Department.storeid,
        COUNT(DISTINCT Product_Category.product_categoryid) AS total_product_categories
    FROM Department
    JOIN Department_has_Aisle 
        ON Department.departmentid = Department_has_Aisle.Department_departmentid
    JOIN Aisle 
        ON Department_has_Aisle.Aisle_aisle_num = Aisle.aisle_num
    JOIN Product_Category 
        ON Product_Category.Aisle_aisle_num = Aisle.aisle_num
    GROUP BY 
        Department.department_name, 
        Department.storeid
) AS DeptVariety
ORDER BY DeptVariety.total_product_categories DESC;
```
**Description**: 
-  This query determines which departments have the highest number of distinct product categories based on aisle assignments. It highlights departments offering the broadest product selection and shows how merchandise variety is distributed across the store.

**Justification**:
- Helps evaluate which departments require more space, attention, or resources.
- Assists in planning merchandising, product placement, and store layout strategies.
- Provides insights into inventory complexity, helping prevent overcrowding or shortages.

### 4. Calculate store productivity: Number of employees per aisle
```sql
SELECT
    Store.idStore AS store_id,
    Employee_Count.total_employees,
    Aisle_Count.total_aisles,
    ROUND(Employee_Count.total_employees / Aisle_Count.total_aisles, 2) AS employees_per_aisle
FROM Store
JOIN (
    SELECT 
        Department.storeid,
        COUNT(DISTINCT Employees.employeeid) AS total_employees
    FROM Department
    JOIN Employees 
        ON Department.departmentid = Employees.departmentid
    GROUP BY Department.storeid
) AS Employee_Count
    ON Employee_Count.storeid = Store.idStore
JOIN (
    SELECT 
        Department.storeid,
        COUNT(DISTINCT Department_has_Aisle.Aisle_aisle_num) AS total_aisles
    FROM Department
    JOIN Department_has_Aisle 
        ON Department.departmentid = Department_has_Aisle.Department_departmentid
    GROUP BY Department.storeid
) AS Aisle_Count
    ON Aisle_Count.storeid = Store.idStore;
```
**Description**: 
- This query calculates productivity by dividing the total number of employees in each store by the number of aisles assigned to its departments. It measures how labor resources are distributed relative to the store’s physical structure.

**Justification**:
- Identifies stores that may be understaffed or overstaffed.
- Supports staffing and scheduling decisions to improve operational efficiency.
- Provides a baseline metric for comparing productivity across different store locations.

### 5. Find suppliers whose products are placed in the highest number of aisles across all stores
```sql
SELECT 
    Supplier.supplier_name,
    COUNT(DISTINCT Aisle.aisle_num) AS total_aisles_stocked
FROM Supplier
JOIN Products 
    ON Supplier.supplierid = Products.Supplier_supplierid
JOIN Product_Category 
    ON Products.Product_Category_product_categoryid = Product_Category.product_categoryid
JOIN Aisle 
    ON Product_Category.Aisle_aisle_num = Aisle.aisle_num
GROUP BY 
    Supplier.supplier_name
HAVING 
    COUNT(DISTINCT Aisle.aisle_num) = (
        SELECT MAX(aisle_count)
        FROM (
            SELECT 
                Supplier.supplierid,
                COUNT(DISTINCT Aisle.aisle_num) AS aisle_count
            FROM Supplier
            JOIN Products 
                ON Supplier.supplierid = Products.Supplier_supplierid
            JOIN Product_Category 
                ON Products.Product_Category_product_categoryid = Product_Category.product_categoryid
            JOIN Aisle 
                ON Product_Category.Aisle_aisle_num = Aisle.aisle_num
            GROUP BY Supplier.supplierid
        ) AS Supplier_Aisle_Counts
    );
```
**Description**: 
- This query finds the supplier(s) whose products appear in the most distinct aisles across all stores. It identifies suppliers with the widest product reach, showing which vendors contribute most heavily to product distribution.

**Justification**:
- Highlights key supplier relationships and helps evaluate vendor performance.
- Informs contract negotiations, sourcing priorities, and potential partnership opportunities.
- Reveals supplier dominance or reliance, supporting diversification and risk mitigation strategies.

---

##  Visualizations

Supplier Locations
![View Image](SupplierLocations.png)
![View Image](AisleInformationVisualization.png)
[![View My Tableau Dashboard](TableauVisualizations.png)](https://us-east-1.online.tableau.com/#/site/jnl63774-f8235c8c77/views/Group5Project2/Dashboard1?:iid=4)

Please click on the image to get redirected to the Tableau page

### Visualization Analysis & Importance

The Employee Wages visualization highlights wage distribution across different hire years and departments, making it easy for managers to identify compensation patterns and potential discrepancies. By presenting wages visually rather than through raw tables, this chart helps uncover trends such as departments with consistently higher wages, shifts in hiring costs over time, or employees whose pay may be misaligned with similar roles. This supports more informed decisions around budgeting, raises, and staffing allocations.

The Aisle Capacity and Aisle Information charts provide a clear view of how store space is used across departments. By visualizing the capacity of each aisle, managers can quickly identify high-demand areas that may require more frequent stocking, as well as underutilized aisles that could be reorganized or repurposed. These insights are essential for optimizing store layouts, improving customer flow, and ensuring that products are placed where they are most accessible and effective.

The Supplier’s Products visualization shows how many products each supplier contributes to the store, enabling leadership to easily compare vendor impact. This helps identify key suppliers, evaluate product diversity, and detect whether the store is overly reliant on a small number of vendors. Understanding these relationships is valuable for negotiating contracts, strengthening partnerships, and planning for more resilient sourcing strategies.

Finally, the Supplier Locations map adds a geographic layer to supplier analysis by showing where vendors are physically located. This context is crucial for understanding delivery times, potential shipping delays, and regional supply chain risks. It also helps managers diversify sourcing across different regions rather than relying too heavily on suppliers from the same area.

Together, these visualizations turn complex relational data into intuitive insights that support operational efficiency, strategic planning, and informed decision-making throughout the retail organization.

---

##  Summary

This project demonstrates the design, implementation, and analysis of a relational database system built to support the core operations of a retail grocery store. Through a carefully constructed data model, we captured key operational elements including suppliers, products, employees, departments, aisles, and store locations. This structure allows the organization to track the flow of goods from suppliers to store aisles, manage employee schedules and reporting hierarchies, and maintain organized department-aisle assignments across multiple store locations.

Using this database, we developed a series of complex SQL queries that provide actionable managerial insights. These queries leverage subqueries, HAVING clauses, and aggregate functions to answer real business questions—such as identifying high-cost departments, understanding managerial workload, evaluating product variety, assessing store productivity, and analyzing supplier distribution across aisles. Together, these insights support more informed decision-making in staffing, merchandising, budgeting, and supplier relations.

The accompanying visualizations and Tableau dashboard further demonstrate how this data can be transformed into meaningful analytics. From supplier distribution maps to aisle capacity breakdowns, the visual tools help communicate trends and findings in a clear and accessible way.

Overall, this project highlights how a well-designed database, combined with thoughtful analysis, can improve operational efficiency, enhance workforce management, and support strategic planning within a retail environment. It also showcases the power of SQL and data modeling in building scalable systems that address real-world business needs.

---





