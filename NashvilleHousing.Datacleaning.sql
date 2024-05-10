
/*
This SQL script performs various data cleaning tasks on the 'NashvilleHousing' table in the 'PortfolioProject' database.
Tasks include standardizing date formats, populating missing property addresses, breaking down addresses into individual components,
splitting owner addresses, changing 'Y' and 'N' values to 'Yes' and 'No' in the 'SoldAsVacant' field,
removing duplicates, and deleting unused columns.
*/


-- Standardize Date Format
-- Converts the 'SaleDate' column to a standardized date format.

SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)


-- Populate Property Address Data
-- Fills in missing property addresses by assigning non-null addresses to rows with null values.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- Break Down Address into Individual Columns (Address, City, State)
-- Splits the 'PropertyAddress' column into 'Address' and 'City'.

SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 


-- Split Owner Address into Individual Columns (Address, City, State)
-- Separates the 'OwnerAddress' column into 'Address', 'City', and 'State'.

SELECT
    PARSENAME(REPLACE(OwnerAddress,',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress,',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress,',', '.'), 1) AS State
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)


-- Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" Field
-- Converts 'Y' to 'Yes' and 'N' to 'No' in the 'SoldAsVacant' column.

SELECT DISTINCT(SoldasVacant), COUNT(SoldasVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldasVacant
ORDER BY 2

SELECT SoldAsVacant,
    CASE
        WHEN SoldasVacant = 'Y' THEN 'Yes'
        WHEN SoldasVacant = 'N' THEN 'No'
        ELSE SoldasVacant
    END 
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldasVacant = CASE
                       WHEN SoldasVacant = 'Y' THEN 'Yes'
                       WHEN SoldasVacant = 'N' THEN 'No'
                       ELSE SoldasVacant
                   END


-- Remove Duplicates using 'ROW_NUMBER', 'PARTITION BY', and 'CTE'
-- Deletes duplicate rows based on certain criteria.

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused Columns
-- Removes unused columns from the table.

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate