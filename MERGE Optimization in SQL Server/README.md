# MERGE Optimization in SQL Server

In this article, I would like to share my experience with optimizing the MERGE statement in SQL Server. In addition, you’ll find useful templates at the end of the article.
Previously, I used MERGE only for updating small amounts of data and I heard unpleasant things about its performance on large datasets. At some point, I had to update a legacy table with data from another table containing about 1 million records and multiple columns (> 20). It’s not an extremely large dataset, but it’s a sizable amount. Here is what I discovered.