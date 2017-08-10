function hFigOut = displayFrame(newFrame, zSet)
  %  updated 29Oct2011 BWS
  
  if nargin == 0 
      try
         newFrame = evalin('base', 'lastDisplayedFrame');
      catch
         msgbox('Could not load last displayed frame.');
         return
      end
  else
     assignin('base', 'lastDisplayedFrame', newFrame);
  end
 
  persistent hFig
  try    
     hFig = evalin('base','hFig');
     figure(hFig);
  catch
     hFig = figure;
     assignin('base','hFig',hFig);
  end
  
  highLimit = str2double(zSet.palleteMax);
  lowLimit = str2double(zSet.palleteMin);
  displayZoom = str2double(zSet.zoom(1:end-1));
  if displayZoom == 1
    hImage = imshow(newFrame', [lowLimit highLimit], 'Border', 'Tight');
  else
    hImage = imshow(imresize(newFrame', displayZoom, 'nearest'), [lowLimit highLimit], 'Border', 'Tight');
  end

%   if curPos ~= -1
%     newPos = get(hFig, 'Position');
%     newPos(1) = curPos(1);
%     newPos(2) = curPos(2);
%     set(hFig, 'Position', newPos);
%   end 
  
  newMap = ones(256, 3);
  newGreyIndex = 1:256;
  
  newGrey = linspace(0, 1, 256);
  newMap(newGreyIndex, 1) = newGrey;
  newMap(newGreyIndex, 2)= newGrey;
  newMap(newGreyIndex, 3) = newGrey;
  if strcmp(zSet.invertPallete, 'on')
          newMap(:,1)=1-newGrey;
          newMap(:,2)=1-newGrey;
          newMap(:,3)=1-newGrey;
  end
  
  switch zSet.colorMode
      case 'Gray Scale'
          % do nothing and use home-made grayscale
          isNewMap = 1;
      case 'Gray 5% red sat'
          % grey with red saturate within 5% of max
          newMap(243:256,1)=1; % to set as red
          newMap(243:256,2)=0;
          newMap(243:256,3)=0;
          isNewMap = 1;
      case 'Gray 10% red sat'
          % grey with red saturate within 10% 
           newMap(230:256,1)=1; % to set as red
           newMap(230:256,2)=0;
           newMap(230:256,3)=0;
            isNewMap = 1;
      case 'Red / Blue'
          % blue/red
          newMap(:,2)=0; % no green
          newMap(:,3)=1-newGrey; % reverse blue
          isNewMap = 1;
      case 'Green / Red'
          % green/red
          newMap(:,3)=0; % no blue
          newMap(:,2)=1-newGrey; % reverse green
          isNewMap = 1;
      case 'Reds'
          % red
          newMap(:,2)=0; % no green
          newMap(:,3)=0; % no blue
          isNewMap = 1;
      case 'Greens'
           % green
          newMap(:,1)=0; % no red
          newMap(:,3)=0; % no blue
          isNewMap = 1;
      case 'Spring'
          colormap spring
          isNewMap = 0;
      case 'Summer'
          colormap summer
          isNewMap = 0;
      case 'Autumn'
          colormap autumn
          isNewMap = 0;
      case 'Winter'
          colormap winter
          isNewMap = 0;
  end
  if isNewMap == 1
      set(hFig,'ColorMap',newMap)
  end
  
  set(hFig, 'NumberTitle', 'Off');
  set(hFig, 'Name', [zSet.displayedFrames '  Zoom ' num2str(zSet.zoom)]);
  if strcmp(zSet.colorBar, 'on') 
      colorbar('location', 'East');
  end
  hFigOut = hFig;
  assignin('base', 'displaySettings', zSet);
end