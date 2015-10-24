% batch inspect dicom slice order using dicom mosaic
base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/dicoms/M3126_CNI_042514/5_2_FracBack_1_BOLD_EPI_18mm_2sec/6793_5_2_dicoms/';
tags = {'TriggerTime','SeriesNumber','AcquisitionNumber',...
    'AcquisitionTime','NumberOfAcquisitions',...
    'InstanceNumber','ImagesInAcquisition','NumberOfTemporalPositions',...
    'StackID','InStackPositionNumber','RepetitionTime','LocationsInAcquisition'};

folders = SearchFiles(base_dir,'*_dicoms');

for n = 1:length(folders)
    clear DH;
    % display folder names
    disp(folders{n});
    DH = dicom_GE_slice_order(folders{n},true);
end

