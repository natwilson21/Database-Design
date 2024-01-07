-- CS3200: Database Design
-- GAD: The Genetic Association Database
-- Created by Natalia Wilson

-- Directions: Write a query to answer each of the following questions

-- use gad database:
use gad;

-- 1. 
-- Explore the content of the various columns in your gad table.
-- List all genes that are "G protein-coupled" receptors in alphabetical order by gene symbol
-- Output the gene symbol, gene name, and chromosome
SELECT 
 gene, 
 gene_name, 
 chromosome
FROM gad
WHERE gene LIKE "%G%"
ORDER BY gene;

-- 2. 
-- How many records are there for each disease class?
-- Output your list from most frequent to least frequent
SELECT 
 disease_class,
 count(disease_class) as 'num_records'
FROM gad
GROUP BY disease_class
order by num_records DESC;

-- 3. 
-- List all distinct phenotypes related to the disease class "IMMUNE"
-- Output your list in alphabetical order
SELECT DISTINCT phenotype
FROM gad
where disease_class = "IMMUNE"
order by phenotype;

-- 4.
-- Show the immune-related phenotypes
-- based on the number of records reporting a positive association with that phenotype.
-- Display both the phenotype and the number of records with a positive association
-- Only report phenotypes with at least 60 records reporting a positive association.
-- Your list should be sorted in descending order by number of records
-- Use a column alias: "num_records"
SELECT 
 phenotype,
 count(disease_class) as 'num_records'
FROM gad
where disease_class = "IMMUNE" and association = 'Y'
GROUP BY disease_class, phenotype
having num_records > 60
order by count(disease_class) DESC;

-- 5.
-- List the gene symbol, gene name, and chromosome attributes related
-- to genes positively linked to asthma (association = Y).
-- Include in your output any phenotype containing the substring "asthma"
-- List each distinct record once
-- Sort  gene symbol
select 
 distinct gene, 
 gene_name, 
 chromosome_band
From gad
where association = 'Y' or phenotype = 'asthma'
group by gene, gene_name, chromosome_band
order by gene;

-- 6. 
-- For each chromosome, over what range of nucleotides do we find
-- genes mentioned in GAD?
-- Exclude cases where the dna_start value is 0 or where the chromosome is unlisted.
-- Sort your data by chromosome.
select
 min(dna_start) as 'DNA_Start',
 max(dna_end) as 'DNA_End',
 cast(chromosome as char) as 'Chromosome'
from gad
where chromosome != '' and dna_end != 0 and dna_start != 0
group by chromosome
order by Chromosome;

-- 7 
-- For each gene, what is the earliest and latest reported year
-- involving a positive association
-- Ignore records where the year isn't valid. (Explore the year column to determine what constitutes a valid year.)
-- Output the gene, min-year, max-year, and number of GAD records
-- order from most records to least.
-- Columns with aggregation functions should be aliased
select
 distinct gene,
 min(year) as 'min_year', 
 max(year) as 'max_year',
 count(gene) as 'num_records'
from gad
where year != '' and year != 0 and association = 'Y'
group by gene
order by num_records DESC;

-- 8. 
-- Which genes have a total of at least 100 positive association records (across all phenotypes)?
-- Give the gene symbol, gene name, and the number of associations.
select
 gene,
 gene_name,
 count(association) as 'num_records'
from gad
where association = 'Y'
group by gene, gene_name
having num_records >= 100
order by gene;

-- 9. 
-- How many total GAD records are there for each population group?
-- Sort in descending order by count
-- Show only the top five results based on number of records
-- Do NOT include cases where the population is blank
select 
 population,
 count(population) as 'num_records'
from gad
where population != '' and population is not null
group by population
order by num_records DESC
limit 5;

-- 10. 
-- In question 5, we found asthma-linked genes
-- But these genes might also be implicated in other diseases
-- Output gad records involving a positive association between ANY asthma-linked gene and ANY disease/phenotype
-- Sort your output alphabetically by phenotype
-- Output the gene, gene_name, association (should always be 'Y'), phenotype, disease_class, and population
select 
 gene, 
 gene_name,
 association,
 phenotype,
 disease_class,
 population
From gad
where gene in 
	(select gene From gad
	where phenotype = 'asthma')
having association = 'Y'
order by phenotype;

-- 11. 
-- Modify your previous query.
-- Let's count how many times each of these asthma-gene-linked phenotypes occurs
-- in our output table produced by the previous query.
-- Output just the phenotype, and a count of the number of occurrences for the top 5 phenotypes
-- with the most records involving an asthma-linked gene (EXCLUDING asthma itself).
select 
 phenotype,
 count(phenotype) as 'num_records'
From gad
where gene in 
	(select gene From gad
	where phenotype = 'asthma')
group by phenotype
having phenotype != 'asthma' and phenotype != ''
order by num_records DESC
limit 5;

-- 12. 
-- Interpret your analysis
-- a) Search the Internet. Does existing biomedical research support a connection between asthma and the
-- top phenotype you identified above? Cite some sources and justify your conclusion!

-- Answer: Existing biomedical research support a connection between asthma and type 1 diabetes especially in chlidren. 
-- The National Institute of Health conducted a study using data from the National Health Insurance system of Taiwan to 
-- research the association between asthma and type 1 diabetes. The study concluded that people with type 1 diabetes 
-- have a 47% higher chance to have asthma due to the research that poor glycemic control greatly increases the risk of having asthma. 
-- The Diabetes Research Connection found similar results from their own study and concluded that people with asthma were at increased risk
-- of developing type 1 diabetes. However, people with type 1 diabetes did not have an increased risk of developing asthma later in life.

-- Sources:
-- Ehrlich, Samantha F., et al. “Patients Diagnosed with Diabetes Are at Increased Risk for Asthma, Chronic Obstructive Pulmonary Disease, Pulmonary Fibrosis, and Pneumonia but Not Lung Cancer.” American Diabetes Association, American Diabetes Association, 6 Oct. 2009, diabetesjournals.org/care/article/33/1/55/29794/Patients-Diagnosed-With-Diabetes-Are-at-Increased. 
-- “Examining The Co-Occurrence of Asthma and Type 1 Diabetes.” Diabetes Research Connection, 5 July 2020, diabetesresearchconnection.org/examining-the-co-occurrence-of-asthma-and-type-1-diabetes/. 
-- Hsiao, Yung-Tsung, et al. “Type 1 Diabetes and Increased Risk of Subsequent Asthma: A Nationwide Population-Based Cohort Study.” Medicine, U.S. National Library of Medicine, 11 Sept. 2015, www.ncbi.nlm.nih.gov/pmc/articles/PMC4616625/. 
-- Sgrazzutti, Laura, et al. “Coaggregation of Asthma and Type 1 Diabetes in Children: A Narrative Review.” International Journal of Molecular Sciences, U.S. National Library of Medicine, 28 May 2021, www.ncbi.nlm.nih.gov/pmc/articles/PMC8198343/. 


-- b) Why might a drug company be interested in instances of such "overlapping" phenotypes?

-- Answer: A drug company might be interested in instances of overlapping phenotypes to create medicine that can reach a larger audience
-- if the overlapping phenotypes have a strong association with one another. In addition, if there has been an effective medicine against one phenotype,
-- there might be a similar solution with the overlapping phenotype. 


