SELECT *
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing

-- Cleaning Data in SQL Queries
--------------------------------------------------------------------------



-- Standardize/Change Sale Date Format
--------------------------------------

  --Didn't work as planned
SELECT SaleDate, CONVERT(Date, SaleDate) AS New_SaleDate
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing

  --Following in succession did!
ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

------------------------------------------------------------------------------------------------------------------------------------------------------


-- Populating Property Address Data
-----------------------------------

  --Shows certain property addresses are null; this shouldn't be
SELECT *
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID
  
  --Self-JOIN statement to match properties without addresses to properties with same ParcelID
  --Using ISNULL to create a column of correct address/prepping for Update
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) AS New_Prop_Adrs
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing a
JOIN PortfolioProject_HouseCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

  --Updating table (must use alias with self joins) to add existing addresses to NULL addresses
  --Could also write ISNULL(a.propertyaddress, 'No address available')
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing a
JOIN PortfolioProject_HouseCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]

--------------------------------------------------------------------------------------------------------------------------------------


--Breaking out address into individual columns (address, city, state)
---------------------------------------------------------------------

  --Option 1 using SUBSTRING
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
 SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing

ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

  -- SUBSTRING will look for ',' within PropertyAddress; -1 removes the ',' character
UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


  --Option 2 Using PARSENAME
    --PARSENAME automatically finds '.' so need to replace ',' with '.' within statement
	--Will work from right to left in terms of sequence so reverse number order
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing

    --Altering table with new info
ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

---------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No is 'Sold as Vacant' field
----------------------------------------------------------

  --Visualizing answers
SELECT Distinct(soldasvacant), COUNT(SoldAsVacant)
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

  --Working through solution; using CASE statement to convert 'Y' and 'N' to 'Yes' and 'No'
SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing

  --UPDATING table with case statement logic
UPDATE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

--------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates (actually removing data from database; usually one would create temp table or store data elsewhere)
------------------------------------------------------------------------------------------------------------------------
  
  --Using CTE and Partition
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject_HouseCleaning.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Delete Unused Columns
-------------------------

  --Only delete unnecessary or redundant columns 
ALTER TABLE PortfolioProject_HouseCleaning.dbo.NashvilleHousing
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress

