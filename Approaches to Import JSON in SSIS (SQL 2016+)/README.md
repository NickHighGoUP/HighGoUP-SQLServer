# Approaches to Import JSON in SSIS (SQL Server 2016+)

Previously, it was a standard approach to use the Json.NET library or JavaScriptSerializer class in the Script Component in order to import JSON data in SSIS. In this article, I’m going to compare performance of Json.NET library to the performance of the new JSON functionality that appeared in SQL Server 2016. This article consists of two parts. In the 1st part, we’ll consider reading data directly from files and a database. In the 2nd part, we’ll review processing large JSON datasets on a row basis. In addition, we’ll consider how to implement these approaches in SSIS. Let’s start!

[Read the 1st part here.](http://www.sqlservercentral.com/articles/SQL+Server+2016/175784/) <br />
[Read the 2nd part here.](http://www.sqlservercentral.com/articles/SQL+Server+2016/176405/)