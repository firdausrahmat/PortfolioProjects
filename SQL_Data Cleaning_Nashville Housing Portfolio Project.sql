/*
Cleaning Data in SQL Queries
Object: To clean, to make data more usable
*/

SELECT *
FROM PortfolioProject..NashvillelHousing

--------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format --

SELECT SaleDate
FROM PortfolioProject..NashvillelHousing

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject..NashvillelHousing

ALTER TABLE NashvillelHousing
ADD SaleDateConverted Date;

UPDATE NashvillelHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject..NashvillelHousing

 --------------------------------------------------------------------------------------------------------------------------


-- Populate Property Address data --

SELECT PropertyAddress, ParcelID
FROM PortfolioProject..NashvillelHousing
ORDER BY ParcelID
-- There are NULL PropertyAddress and there are duplicated ParcelID with NULL PropertyAddress

-- Self Join the table
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject..NashvillelHousing a
JOIN PortfolioProject..NashvillelHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- to avoid repeated ParcelID
WHERE a.PropertyAddress is null
-- table shown clearer NULL addresses with same ParcelID

-- update what to be stuck in the NULL a.PropertyAddress and update
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvillelHousing a
JOIN PortfolioProject..NashvillelHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvillelHousing a
JOIN PortfolioProject..NashvillelHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]

-- after update, recheck and confirm no NULL PropertyAddress and repeated ParcelID anymore
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvillelHousing a
JOIN PortfolioProject..NashvillelHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

SELECT PropertyAddress, ParcelID
FROM PortfolioProject..NashvillelHousing
ORDER BY ParcelID

--------------------------------------------------------------------------------------------------------------------------


-- Breaking out Address into Individual Columns (Address, City, State) --

--- PropertyAddress
SELECT PropertyAddress
FROM PortfolioProject..NashvillelHousing
-- address were delimeter by ,

-- devide the address using SUBSTRING and CHARINDEX
-- CHARINDEX use to search specific value
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM PortfolioProject..NashvillelHousing

-- create new table and update seperated address (twice)
ALTER TABLE NashvillelHousing
ADD UpdatedPropertyAddress Nvarchar(255);

UPDATE NashvillelHousing
SET UpdatedPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvillelHousing
ADD PropertyCity Nvarchar(255);

UPDATE NashvillelHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- recheck the updated address and city
SELECT *
FROM PortfolioProject..NashvillelHousing


--- OwnerAddress
SELECT OwnerAddress
FROM PortfolioProject..NashvillelHousing
-- address were delimeter by ,

-- devide the address using PARSENAME
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as address
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as city
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as state
FROM PortfolioProject..NashvillelHousing

-- create new table and update seperated address (thrice)
ALTER TABLE NashvillelHousing
ADD UpdatedOwnerAddress Nvarchar(255);

UPDATE NashvillelHousing
SET UpdatedOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvillelHousing
ADD UpdatedOwnerCity Nvarchar(255);

UPDATE NashvillelHousing
SET UpdatedOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvillelHousing
ADD UpdatedOwnerState Nvarchar(255);

UPDATE NashvillelHousing
SET UpdatedOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- recheck the updated address
SELECT *
FROM PortfolioProject..NashvillelHousing

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field --

-- Count how many Y and N in the SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvillelHousing
Group by SoldAsVacant
Order by COUNT(SoldAsVacant)

-- Create CASE statement to update
SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'YES'
	   When SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..NashvillelHousing

-- Update the table
Update NashvillelHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'
						When SoldAsVacant = 'N' THEN 'NO'
						ELSE SoldAsVacant
						END

-- recheck the updated table
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvillelHousing
Group by SoldAsVacant
Order by COUNT(SoldAsVacant)

-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates --

-- Check duplicates using CTE, Row_Number and Partition by
WITH RowNumCTE as(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) as row_num
FROM PortfolioProject..NashvillelHousing
)
SELECT *
FROM RowNumCTE
Where row_num > 1
Order by PropertyAddress

-- Delete the duplicates rows (still using CTE)
WITH RowNumCTE as(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) as row_num
FROM PortfolioProject..NashvillelHousing
)
DELETE
FROM RowNumCTE
Where row_num > 1

-- Recheck the updated table after delete
WITH RowNumCTE as(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) as row_num
FROM PortfolioProject..NashvillelHousing
)
SELECT *
FROM RowNumCTE
Where row_num > 1
Order by PropertyAddress
-- no more duplicates found

---------------------------------------------------------------------------------------------------------


-- Delete Unused Columns --
Select *
FROM PortfolioProject..NashvillelHousing

ALTER TABLE PortfolioProject..NashvillelHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress