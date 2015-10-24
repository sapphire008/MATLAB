MATLAB
==============================================================

MATLAB scripts for generic purposes, image processing, and data analyses of fMRI, electrophysiology, and multi-electrode array.

Edward DongBo Cui dcui@case.edu

**Some scripts are borrowed from FileExchange and the help document inside the script will generally indicate the author**

There are some MATLAB scripts interfaces with other applications and packages of other languages. It is necessary to specify the path of these other applications and pacakges before use.

Some functions may require additional MATLAB licensed toolboxes, e.g. statistics, curve fitting, optimization, partial differential equation (PDE), etc.

# Current list of packages #

## General purpose utilities ##
1. `/generic`: generic MATLAB functions / utilities / routines
2. `/MATLAB_search_path/`: scripts that quickly add specified packages
  1. `[addspm8, addspm12,addjongspm8]`: requires the path of `SPM` packages
  2. `addmatlabpkg`: place this script in the directory containing custom packages
  3. `TC.xml`: additional tab complete, to replace the file under `{matlabroot}/toolbox/local/`
3. `ReadNWrite`: MATLAB interface to Excel spreadsheet

## fMRI utilities ##
1. `/fMRI_pipeline/`: fMRI processing pipeline
  1. `FSL_Bet_skull_stripping`: need `FSL ./fsl/5.x.x`
2. `/dicom_tools/`: dicom image header information extraction
  1. `dicom_header_matlab.m`: requires `Image-ExifTool`
  2. `dcm2nii_matlab.m`: requires `mricron`

## Image processing utilities ##
1. `/image_reg3`: fiducial marker based movement tracking
2. `/2photon`: 2photon image reading, processing, and reconstruction

## Electrophysiology utilities
1. `MEA`: multi-electrode array data read (via `NeuroShare`) and analysis
2. `NeuroShare`: MATLAB data reading utilities for `MEA`. Currently tested only on Windows environment, but in theory, should work in all 3 platforms.
3. `ephanalysis`: electrophysiology data reading, processing, and analysis.
