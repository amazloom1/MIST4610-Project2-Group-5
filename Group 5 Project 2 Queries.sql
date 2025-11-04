use cs_rmk03895;

# 1. Find departments with labor cost per hour exceeding the store average labor cost per hour
SELECT 
    Department.department_name,
    Department.storeid,
    SUM(Employees.hourly_wage) AS total_department_wages,
    AVG(Employees.hourly_wage) AS avg_department_wage,
    Store_Averages.store_avg_wage
FROM Department
JOIN Employees ON Department.departmentid = Employees.departmentid
JOIN (
    SELECT storeid, AVG(hourly_wage) AS store_avg_wage
    FROM Employees
    GROUP BY storeid
) AS Store_Averages ON Store_Averages.storeid = Department.storeid
GROUP BY Department.department_name, Department.storeid, Store_Averages.store_avg_wage
HAVING AVG(Employees.hourly_wage) > Store_Averages.store_avg_wage;

#2. Identify employees who supervise more than 3 employees across multiple departments
SELECT 
    Employees.employeeid AS manager_id,
    Employees.first_name,
    Employees.last_name,
    COUNT(Subordinates.employeeid) AS num_subordinates
FROM Employees
JOIN Employees AS Subordinates ON Employees.employeeid = Subordinates.managerid
GROUP BY Employees.employeeid, Employees.first_name, Employees.last_name
HAVING COUNT(Subordinates.employeeid) > 3;


#3. Determine departments with the highest product variety based on aisle assignments
SELECT 
    Department.department_name,
    Department.storeid,
    COUNT(DISTINCT Product_Category.product_categoryid) AS total_product_categories
FROM Department
JOIN Department_has_Aisle ON Department.departmentid = Department_has_Aisle.Department_departmentid
JOIN Aisle ON Department_has_Aisle.Aisle_aisle_num = Aisle.aisle_num
JOIN Product_Category ON Product_Category.Aisle_aisle_num = Aisle.aisle_num
GROUP BY Department.department_name, Department.storeid
ORDER BY total_product_categories DESC;

#4. Calculate store productivity: Number of employees per aisle
SELECT 
    Store.idStore AS store_id,
    COUNT(DISTINCT Employees.employeeid) AS total_employees,
    COUNT(DISTINCT Aisle.aisle_num) AS total_aisles,
    ROUND(COUNT(DISTINCT Employees.employeeid) / COUNT(DISTINCT Aisle.aisle_num), 2) AS employees_per_aisle
FROM Store
JOIN Department ON Store.idStore = Department.storeid
JOIN Employees ON Department.departmentid = Employees.departmentid
JOIN Department_has_Aisle ON Department.departmentid = Department_has_Aisle.Department_departmentid
JOIN Aisle ON Department_has_Aisle.Aisle_aisle_num = Aisle.aisle_num
GROUP BY Store.idStore;


#5. Find suppliers whose products are placed in the highest number of aisles across all stores
SELECT 
    Supplier.supplier_name,
    COUNT(DISTINCT Aisle.aisle_num) AS total_aisles_stocked
FROM Supplier
JOIN Products ON Supplier.supplierid = Products.Supplier_supplierid
JOIN Product_Category ON Products.Product_Category_product_categoryid = Product_Category.product_categoryid
JOIN Aisle ON Product_Category.Aisle_aisle_num = Aisle.aisle_num
GROUP BY Supplier.supplier_name
ORDER BY total_aisles_stocked DESC;

