function [outFrame displayedFrames] = generateProcessedFrame(zSet)
  % hello
  zData = evalin('base', 'zImage'); % local link to current data structure
  switch zSet.averageMode
      case 'One Frame'
          numToAverage = 1;
      case 'Average 3'
          numToAverage = 3;
      case 'Average 5'
          numToAverage = 5;
      case 'Average 7'
          numToAverage = 7;
      case 'Average 9'
          numToAverage = 9;
      case 'Average 11'
          numToAverage = 11;
      case 'Average All'
          numToAverage = zData.numFrames;
  end
  firstFrame = zSet.curFrame - fix(numToAverage/2);
  if firstFrame < 1
     firstFrame = 1; 
  end
  lastFrame = firstFrame + (numToAverage - 1);
  if lastFrame > zData.numFrames 
     lastFrame = zData.numFrames; 
  end
  outFrame = getOneFrame(zData, firstFrame, zSet);
  numFramesInAverage = 1;
  if lastFrame > firstFrame
     for frameNum = (firstFrame + 1):lastFrame
        outFrame = outFrame + getOneFrame(zData, frameNum, zSet);
        numFramesInAverage = numFramesInAverage + 1;
     end
     outFrame = outFrame ./ numFramesInAverage;
     displayedFrames = ['Frames ' num2str(firstFrame) ' - ' num2str(lastFrame)];
  else
     displayedFrames = ['Frame ' num2str(firstFrame)];
  end
  
  if ~strcmp(zSet.displayType, 'Main')
     % need background to subtract
     baselineFrame = getOneFrame(zData, 1, zSet);
     numFramesInAverage = 1;
     numToAverage = str2num(zSet.baselineAverage);
     if numToAverage > 1
        for frameNum = 2:numToAverage
          baselineFrame = baselineFrame + getOneFrame(zData, frameNum, zSet);
          numFramesInAverage = numFramesInAverage + 1;
        end
        baselineFrame = baselineFrame ./ numFramesInAverage;
        displayedFrames = [displayedFrames ' (Frames 1 - ' zSet.baselineAverage];
     else
        displayedFrames = [displayedFrames ' (Frame 1'];
     end
     switch zSet.displayType
         case 'dF * 10'
             outFrame = (outFrame - baselineFrame) .* 10;
             displayedFrames = [displayedFrames ' dF*10)'];
         case 'dF/F * 100'
             outFrame = ((outFrame - baselineFrame) ./ baselineFrame) .* 100;
             displayedFrames = [displayedFrames ' dF/F*100)'];
         case 'dF/F * 1000'
             outFrame = ((outFrame - baselineFrame) ./ baselineFrame) .* 1000;
             displayedFrames = [displayedFrames ' dF/F*1000)'];
     end
  end
  
end

function tempFrame = getOneFrame(zData, frameNum, zSet)
  % hello
  tempFrame = zData.stackA(:,:,frameNum);
  if strcmp(zSet.medianEnable, 'on')
      filterLevel = str2double(zSet.medianNum);
      tempFrame = medfilt2(tempFrame, [filterLevel, filterLevel]);
  end
  if strcmp(zSet.wienerEnable, 'on')
      filterLevel = str2double(zSet.wienerNum);
      tempFrame = wiener2(tempFrame, [filterLevel, filterLevel]);
  end
end