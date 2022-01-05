/*
Description: demo of mrconso and mrrel tables.
Author: Haley Hunter-Zinck
Date: 2022-01-05
*/

-- find all English language strings associated with a CUI
SELECT DISTINCT sui, str
FROM meta2021aa.mrconso 
WHERE cui = 'C0013404'
	AND lat = 'ENG';
	
-- find all vocabularies with a CUI
SELECT DISTINCT sab 
FROM meta2021aa.mrconso 
WHERE cui = 'C0013404'
	AND lat = 'ENG';
	
-- find all CUIs associate with an English string
SELECT DISTINCT CUI
FROM meta2021aa.mrconso 
WHERE lat = 'ENG'
	AND str = 'Dyspnea';
