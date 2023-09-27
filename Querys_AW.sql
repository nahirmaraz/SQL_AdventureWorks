-- 1.Obtener un listado contactos que hayan ordenado productos de la subcategoría "Mountain Bikes", entre los años 2000 y 2003, cuyo método de envío sea "CARGO TRANSPORT 5".
SELECT DISTINCT c.FirstName, c.LastName
FROM contact c
INNER JOIN salesorderheader h 
ON (h.ContactID= c.ContactID)
INNER JOIN salesorderdetail d
ON (h.SalesOrderID= d.SalesOrderID)
INNER JOIN shipmethod sm
ON ( sm.ShipMethodID= h.ShipMethodID)
INNER JOIN product p 
ON (p.ProductID= d.ProductID)
INNER JOIN productsubcategory ps
ON (ps.ProductSubcategoryID= p.ProductSubcategoryID)
WHERE year(h.OrderDate) between 2000 AND 2003 AND sm.ShipMethodID=5 AND ps.ProductSubcategoryID=1
ORDER BY FirstName;

-- 2.Obtener un listado contactos que hayan ordenado productos de la subcategoría "Mountain Bikes", entre los años 2000 y 2003 con la cantidad de productos adquiridos y ordenado por este valor, de forma descendente.
SELECT distinct concat(c.FirstName,' ', c.LastName) as Contacto, sum(d.OrderQty) as CantidadAdquirida
FROM contact c
INNER JOIN salesorderheader h 
ON (h.ContactID= c.ContactID)
INNER JOIN salesorderdetail d
ON (h.SalesOrderID= d.SalesOrderID)
INNER JOIN product p 
ON (p.ProductID= d.ProductID)
INNER JOIN productsubcategory ps
ON (ps.ProductSubcategoryID= p.ProductSubcategoryID)
WHERE year(h.OrderDate) between 2000 AND 2003  AND ps.ProductSubcategoryID=1
GROUP BY Contacto
ORDER BY CantidadAdquirida desc
LIMIT 10000;

-- 3.Obtener un listado de cual fue el volumen de compra (cantidad) por año y método de envío.
SELECT sum(d.OrderQty) as VolumenDeCompra, year(h.OrderDate) as Año, sm.Name as MetodoDeEnvio
FROM shipmethod sm
INNER JOIN  salesorderheader h
ON(h.ShipMethodID=sm.ShipMethodID)
INNER JOIN salesorderdetail d
ON(d.SalesOrderID=h.SalesOrderID)
GROUP BY MetodoDeEnvio, Año
ORDER BY VolumenDeCompra;

-- 4.Obtener un listado por categoría de productos, con el valor total de ventas y productos vendidos.
SELECT pc.Name as CategoriaProducto, sum(d.OrderQty) as ProductosVendidos, sum(d.LineTotal) as ValorTotal
FROM productcategory pc
INNER JOIN productsubcategory ps
ON( pc.ProductCategoryID=ps.ProductCategoryID)
INNER JOIN product p
ON( p.ProductSubcategoryID=ps.ProductSubcategoryID)
INNER JOIN salesorderdetail d
ON(d.ProductID=p.ProductID)
GROUP BY CategoriaProducto;

-- 5.Obtener un listado por país (según la dirección de envío), con el valor total de ventas y productos vendidos, sólo para aquellos países donde se enviaron más de 15 mil productos.
SELECT cr.Name as Pais, sum(d.OrderQty) as ProductosVendidos, sum(d.LineTotal) as TotalVentas
FROM countryregion cr
INNER JOIN stateprovince sp
ON (cr.CountryRegionCode=sp.CountryRegionCode)
INNER JOIN address a
ON (a.StateProvinceID=sp.StateProvinceID)
INNER JOIN salesorderheader h
ON (a.AddressID=h.ShipToAddressID)
INNER JOIN salesorderdetail d
ON (h.SalesOrderID = d.SalesOrderID)
GROUP BY Pais
HAVING sum(d.OrderQty)>15000;

-- 6.Obtener un listado de cual fue el volumen de ventas (cantidad) por año y método de envío mostrando para cada registro, qué porcentaje representa del total del año. Resolver utilizando Subconsultas y Funciones Ventana, luego comparar la diferencia en la demora de las consultas.
SELECT sum(d.OrderQty) as CantidadVentas, year(h.OrderDate) as Año, sm.Name as MetodoEnvio,
ROUND(sum(d.OrderQty)/sum(sum(d.OrderQty)) OVER (PARTITION BY year(h.OrderDate)) *100,2) as PorcentajeAnual 
FROM salesorderdetail d
JOIN salesorderheader h
ON (h.SalesOrderID = d.SalesOrderID)
JOIN shipmethod sm
ON(sm.ShipMethodID = h.ShipMethodID)
GROUP BY Año, MetodoEnvio;

-- 7.Obtener un listado por categoría de productos, con el valor total de ventas y productos vendidos, mostrando para ambos, su porcentaje respecto del total.
SELECT pc.Name as NombreCategoria,sum(d.OrderQty) as ProductosVendidos, sum(d.LineTotal) as TotalVentas,
		ROUND((SUM(d.OrderQty) / (SELECT SUM(OrderQty) FROM salesorderdetail)) * 100,2) as PorcentajeProductosVendidos,
        ROUND((SUM(d.LineTotal) / (SELECT SUM(LineTotal) FROM salesorderdetail)) * 100,2) as PorcentajeTotalVentas
FROM productcategory pc
INNER JOIN productsubcategory psc
ON (pc.ProductCategoryID= psc.ProductCategoryID)
INNER JOIN product p
ON (p.ProductSubcategoryID=psc.ProductSubcategoryID)
INNER JOIN salesorderdetail d
ON (p.ProductID=d.ProductID)
GROUP BY NombreCategoria;

-- 8.Obtener un listado por país (según la dirección de envío), con el valor total de ventas y productos vendidos, mostrando para ambos, su porcentaje respecto del total.
SELECT cr.Name as Pais, sum(d.OrderQty) as ProductosVendidos, sum(d.LineTotal) as TotalVentas,
		ROUND((SUM(d.OrderQty) / (SELECT SUM(OrderQty) FROM salesorderdetail)) * 100,2) as PorcentajeProductosVendidos,
        ROUND((SUM(d.LineTotal) / (SELECT SUM(LineTotal) FROM salesorderdetail)) * 100,2) as PorcentajeTotalVentas
FROM countryregion cr
INNER JOIN stateprovince sp
ON (cr.CountryRegionCode=sp.CountryRegionCode)
INNER JOIN address a
ON (a.StateProvinceID=sp.StateProvinceID)
INNER JOIN salesorderheader h
ON (a.AddressID=h.ShipToAddressID)
INNER JOIN salesorderdetail d
ON (h.SalesOrderID = d.SalesOrderID)
GROUP BY Pais;

-- 9.Obtener por ProductID, los valores correspondientes a la mediana de las ventas (LineTotal), sobre las ordenes realizadas. Investigar las funciones FLOOR() y CEILING().
WITH RankedSales AS (SELECT ProductID, LineTotal,
    ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY LineTotal) AS RowAsc,
    COUNT(*) OVER (PARTITION BY ProductID) AS TotalRows
FROM salesorderdetail)

SELECT DISTINCT ProductID,
  CASE
    WHEN TotalRows % 2 = 1 THEN LineTotal
    ELSE (FLOOR(LineTotal) + CEILING(LineTotal)) / 2.0
  END AS Median
FROM RankedSales
WHERE RowAsc IN (TotalRows / 2, TotalRows / 2 + 1);