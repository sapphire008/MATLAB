function zImage = readIM4file(stackName)
  % last revised 17 May 2012 BWS
  
      try
          localImage = ImageAssembly.clsImage;
      catch
          NET.addAssembly('d:\LabWorld\Assemblies\ImageAssembly.dll');
          localImage = ImageAssembly.clsImage;
      end
            
      localImage.ReadEpisode(stackName);
      
      zImage.Xpixels = localImage.GetXPixels;
      zImage.Ypixels = localImage.GetYPixels;
      zImage.numFrames = localImage.GetNumFrames;
      zImage.numChannels = localImage.GetNumChannels; 
      zImage.zoom = localImage.GetZoom;
      
      zImage.micronsPerPixel = localImage.GetMicronsPerPixel;
      zImage.microsecondsPerPixel = localImage.GetMicrosecondsPerPixel;
      zImage.stackAcqSeconds = localImage.GetStackAcquisitionTimeInSeconds;
      zImage.focusDepthMicrons = localImage.GetFocusDepthInMicrons;
      zImage.filterPosition = localImage.GetFilterPositionNum;
      zImage.filterName = char(localImage.GetFilterName);
     
      zImage.laserDesc = char(localImage.GetLaserDesc);
      zImage.scanDesc = char(localImage.GetScanDesc);
      zImage.PMTAdesc = char(localImage.GetPMTADesc);
      zImage.PMTBdesc = char(localImage.GetPMTBDesc);
     
      zImage.numElementsStackA = localImage.GetNumElementsStackA;
      zImage.numElementsStackB = localImage.GetNumElementsStackB;
      zImage.savedFileName = char(localImage.GetSavedFileName);
      zImage.linkedFileName = char(localImage.GetLinkedFileName);
      zImage.computerName = char(localImage.GetComputerName);
      zImage.exptTime = localImage.GetExptTime;
      zImage.comment = char(localImage.GetComment); 
      zImage.classVersion = localImage.GetClassVersionNum;
      zImage.stackA = int16(localImage.GetStackA);
      zImage.stackB = int16(localImage.GetStackB);
       
      numExtra = localImage.GetNumExtraScalars;
      if numExtra > 0 
         keys = localImage.GetExtraScalarKeys;
         for i = 1:numExtra
            key = char(keys(i));
            value = localImage.GetExtraScalar(key);
            eval(['zImage.' key ' = value;']);
         end
      end
      
       numExtra = localImage.GetNumExtraVectors;
      if numExtra > 0 
         keys = localImage.GetExtraVectorKeys;
         for i = 1:numExtra
            key = char(keys(i));
            value = localImage.GetExtraVector(key);
            eval(['zImage.' key ' = double(value);']);
         end
      end
      assignin('base', 'zImage', zImage);
end