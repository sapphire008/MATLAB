function out = JPST(action, data);
%function out = JPST(action, data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calls to set values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% JPST('setGDFTicks',ticksperms)				set the number of ticks per ms, not needed if no display
% JPST('setGDF',gdffileandpathname)  		loads the gdf file
% JPST('setXID',xidvalue)						gets a list of x spikes from the gdf file
% JPST('setYID',yidvalue)						gets a list of y spikes from the gdf file
% JPST('setAlignID',alignidvalue)				gets a list of align codes from the gdf file
% JPST('setTimeRange',[starttick stoptick])sets the start and stop times for the PSTHs
%																in gdf ticks
% JPST('setBinWidth',ticksperbin)				sets the bin width (in gdf ticks)
% JPST('setScoop',[firstbin lastbin)			sets the bin range for the scoop,
%																negative values are y->x bin delay
%																positive values are x-> bin delay
% JPST('setDC',[firstbin lastbin smoothing]) sets the bin range for the speical matrix
%																valid smoothing values: 0 1 2 4
%																negative values are y->x bin delay
%																positive values are x-> bin delay
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calls to calculate values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% JPST('calcRaw')				calculates the raw matrix, x and y histograms (and rasters) 
%											also updates the crosscorrelation and scoop histograms,
%											and the special matrix
% JPST('calcCorrected')		calculates the corrected matrix,
%											first calculating the raw, if necessary
%											also updates the crosscorrelation and scoop histograms,
%											and the special matrix
% JPST('calcPSTprod')
% JPST('calcNormalized')
% JPST('calcSignificance')
% JPST('calcBinErr')
% JPST('calcXCorrHist');		calculates the crosscorrelation histogram from the current matrix
% JPST('calcScoopHist');		calculates the scoop histogram from the current matrix
% JPST('calcDCMatrix');		calculates the delayed coinicidence vs time matrix
%											from the current matrix
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calls to get values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% JPST('getXHist')				returns current x histogram
% JPST('getYHist')				returns current y histogram
% JPST('getMatrix')			returns current matrix
% JPST('getXCorrHist')		returns current cross correlation histogram
% JPST('getScoopHist')		returns current scoop histogram
% JPST('getDCMatrix');		returns delayed coinicidence vs time matrix
%
global xID;			%ID of spikes on x axis
global yID;			%ID of spikes on y axis
global alignID;	%ID of align
global xList;		%list of spike times for xChannel ID from gdf file 
global yList;		%list of spike times for yChannel ID from gdf file 
global alignList; %list of align times
global binWidth;	%in unit ticks of gdf file
global startTick;	%offset from align tick to start calculation
global stopTick;	%offset from align tick to stop calculation
global xHist;		%x axis histogram
global yHist;		%y axis histogram
global xSqrd;		%x axis histogram
global ySqrd;		%y axis histogram
global xErrors;	%x axis errors histogram
global yErrors;	%y axis errors histogram
global matrix;		%JPST Matrix
global DCMatrix %delayed coinicidence vs time plot
global DCvals;		%diagonal start bin,stop bin,and smoothing of DC
global SCsm;        % Scoop histogram smoothing value
global xcorrHist;	%crosscorrelation histogram
global scoopHist;	%scoop histogram
global scoop		%diagonal start and stop bin of scoop (inclusive)
global gdf;			%gdf data array
global rawValid;	%boolean, =0 if Raw matrix needs to be(re)calculated
global currentMatrix	% what is the current matrix
global ticksperms %only needed to display
global verbose;
global FileName;
global normalizeMethod;





if exist('action', 'var')

switch(action)
   
case('init')
   % set some default values just to get started
   JPST('setVerbose',1);
   JPST('setNormalizeMethod',1);
   JPST('setGDFTicks',25);
   JPST('setTimeRange',[-50*25 50*25]);
   JPST('setBinWidth',25);
   JPST('setScoop',[-10 10]);
   JPST('setDC',[-10 10 2]);
   JPSTGUI('setRasterDisplayTrials',1000);
   
   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% set value routines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
   
case('toggleVerbose');
verbose = ~verbose;
if verbose
   fprintf('verbose on\n');
else
   fprintf('verbose off\n');
end   
out = 1;


case('setNormalizeMethod')
   if data
      normalizeMethod = 'trials';
   else
      normalizeMethod = 'none';
   end
rawValid = 0;   
if verbose
   fprintf('set normalization method to: %s\n',normalizeMethod);
end
out = 1;

   
case('setVerbose');
if isempty(data) out = 0; else
verbose = data(1);
if verbose
   fprintf('verbose on\n');
else
   fprintf('verbose off\n');
end   
out = 1;
end
   
case('setGDFTicks');
if isempty(data) out = 0; else
ticksperms = data(1);
if verbose
   fprintf('gdf ticks per ms = %d\n',ticksperms);
end
out = 1;
end
   
case('setGDF')
if isempty(data) out = 0; else
gdfName = data;   
if strcmp(gdfName(end - 3:end), '.mat')
    events = load(gdfName);    
    gdf = [];
    sources = unique({events.source});
    for i = 1:numel(events)
        gdf(end + (1:numel(events(i).data) + 1), :) = [30 events(i).stimTime; find(strcmp(events(i).source, sources)) * ones(size(events(i).data)) events(i).data];
    end
else
    gdf = load(gdfName);
end

FileName = data
xHist = [];
yHist = [];
matrix = [];
currentMatrix = 'none';
if verbose
   fprintf('loaded %d events from %s\n',length(gdf),gdfName);
end
rawValid = 0;  
out = length(gdf);
end

case('transferGDF')
if isempty(data)
    out = 0;
else
    gdfName = data;   
    gdf = gdfName;
    FileName = 'Transfered';
    xHist = [];
    yHist = [];
    matrix = [];
    currentMatrix = 'none';
    if verbose
       fprintf('transfered %d events \n',length(gdf));
    end
    rawValid = 0;  
    out = length(gdf);
end

case('setXID')
if isempty(data) out = 0; else
xID = data(1);   
xList = gdf(find(gdf(:,1) == xID),2);
xHist = [];
matrix = [];
currentMatrix = 'none';
rawValid = 0;
if verbose
   fprintf('xID = %d, (%d instances in gdf file)\n',xID,length(xList));
end
out = length(xList);
end

case('setYID')
if isempty(data) out = 0; else
yID = data(1);   
yList = gdf(find(gdf(:,1) == yID),2);
yHist = [];
matrix = [];
currentMatrix = 'none';
rawValid = 0;  
if verbose
   fprintf('yID = %d, (%d instances in gdf file)\n',yID,length(yList));
end
out = length(yList);
end

case('setAlignID')
if isempty(data) out = 0; else
alignID = data(1);   
alignList = gdf(find(gdf(:,1) == alignID),2);
xHist = [];
yHist = [];
matrix = [];
currentMatrix = 'none';
rawValid = 0;  
if verbose
   fprintf('alignID = %d, (%d instances in gdf file)\n',alignID,length(alignList));
end
out = length(alignList);
end

case('setTimeRange')
if isempty(data) out = 0; else
startTick = data(1);
stopTick = data(2);
currentMatrix = 'none';
rawValid = 0;  
if verbose
   fprintf('start tick = %d, stop tick = %d\n',startTick,stopTick);
end
out = 1;
end

case('setBinWidth')
if isempty(data) out = 0; else
binWidth = data(1);
currentMatrix = 'none';
rawValid = 0;  
if verbose
   fprintf('bin width = %d ticks\n',binWidth);
end
out = 1;
end

case('setScoop')
if isempty(data) out = 0; else
scoop = data(1:2);
if verbose
   fprintf('scoop is from bin %d to bin %d, inclusive\n',scoop(1),scoop(2));
end
out = 1;
end

case('setDC')
if isempty(data) out = 0; else
DCvals = data(1:3);
if verbose
   fprintf('delayed correlation is from bin %d to bin %d, smoothing = %d\n',DCvals(1),DCvals(2),DCvals(3));
end
out = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% calculation routines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

case('calcRaw')
if verbose
   tic
   fprintf('calculating raw JPST\n');
end
xcorrHist = [];
scoopHist = [];

%calc some stuff we will need to know
trials = length(alignList);	% number of trials
bins = (stopTick - startTick)/binWidth; %number of bins

%init histos
xErrors = zeros(1,bins);
yErrors = zeros(1,bins);
xHist = zeros(1,bins);
yHist = zeros(1,bins);
xSqrd = zeros(1,bins);
ySqrd = zeros(1,bins);
matrix = zeros(bins, bins);

%bins spikes then add to matrix
for t = 1:trials	% have to do a for loop
	%think about making this a c function
   start = alignList(t) + startTick -1;  % for this trial
   stop = alignList(t) + stopTick;
   
   x= zeros(1,bins);
   y= zeros(1,bins);
   
   binList = ceil((xList(find((xList > start) & (xList < stop))) - start)/binWidth);
   temp = binList(~diff(binList));
   x(temp) = 1;		% bins which have a diff of not zero, ie spike
   xErrors = xErrors + x;  % build xErrorHisto
   x= zeros(1,bins);
   x(binList) = 1;
   if ~isempty(temp)
   for i = 1:length(temp)
     x(temp(i)) = x(temp(i)) +1;			% add in binomial errors so histogram will be right
   end   
   end
   xHist = xHist + x;   	% build xHisto
   xSqrd = xSqrd + x.*x;   % for 'Normalized' proc only
   
   binList = ceil((yList(find((yList > start) & (yList < stop))) - start)/binWidth);
   temp = binList(~diff(binList)); % list of repeat bins
   y(temp) = 1;		% bins which have a diff of not zero, ie spike
   yErrors = yErrors + y;  % build yErrorHisto
   y= zeros(1,bins);
   y(binList) = 1;
   if ~isempty(temp)
   for i = 1:length(temp)
      y(temp(i)) = y(temp(i)) +1;			% add in binomial errors so histogram will be right
   end   
   end   
   yHist = yHist + y;   	% build yHisto
   ySqrd = ySqrd + y.*y;
   
   matrix = matrix + y'*x;	% build matrix
end
if xID == yID	% if autocorrelating
   for i = 1:length(matrix)
      matrix(i,i) = 0;	% zero main diagonal
   end
end   
JPST('normalizeMatrix',normalizeMethod);
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
currentMatrix = 'raw';
rawValid = 1;  
if verbose
  t = toc;
  fprintf('x ID binomial errors: %d\n',sum(xErrors));
  fprintf('y ID binomial errors: %d\n',sum(yErrors));
  fprintf('raw elapsed time: %3.2f s\n',t);
end


case('normalizeMatrix')
    
switch(normalizeMethod)
  case('none')
  if verbose
    fprintf('NOT normalized by trials\n');
  end

   
  case('trials')
  xHist  =  xHist/length(alignList);		% normalize by trials
  yHist  =  yHist/length(alignList);		% normalize by trials
  xSqrd  =  xSqrd/length(alignList);
  ySqrd  =  ySqrd/length(alignList);
  matrix = matrix/length(alignList);		% normalize by trials 
  if verbose
    fprintf('normalized by trials\n');
  end
end   


case('calcCorrected')
%if ~rawValid | ~strcmp(currentMatrix, 'raw')
   JPST('calcRaw');
%end   
if verbose
   tic
   fprintf('calculating corrected JPST\n');
end
if strcmp(normalizeMethod, 'none') 
   matrix = matrix - yHist'*xHist/length(alignList);	% subtract crossproduct
else   
   %xt = xHist/length(alignList);
   %yt = yHist/length(alignList);
   %xt = xHist;
   %yt = yHist;
   matrix = matrix - yHist'*xHist;	    % subtract crossproduct
%matrix = matrix-(yt'*xt)*length(alignList);	% crossproduct
end   
if xID == yID	% if autocorrelating
   for i = 1:length(matrix)
      matrix(i,i) = 0;	% zero main diagonal
   end
end   
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
currentMatrix = 'corrected';
if verbose
  t = toc;
  fprintf('corrected elapsed time: %3.2f s\n',t);
end

case('calcPctExcessCoincidences')
sm = normalizeMethod;
normalizeMethod = 'none';
rawValid = 0;
JPST('calcCorrected');
if verbose
   tic
   fprintf('calculating excess coincidences\n');
end
xt = xHist/length(alignList);
yt = yHist/length(alignList);
d = (yt'*xt)*length(alignList);	% crossproduct

d(find(~d)) = 1;	%no divide by zero problems
matrix = 100*( matrix ./ d );	% crossproduct
normalizeMethod = sm;
rawValid = 0;
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
currentMatrix = 'PctExcessCoin';
if verbose
  t = toc;
  fprintf('Percent excess coincidences elapsed time: %3.2f s\n',t);
end


case('calcPSTprod')
if ~rawValid		% if x, y, align, binWidth, start or stop times have changed
   JPST('calcRaw');
end   
if verbose
   tic
   fprintf('calculating PSTprod matrix\n');
end
if strcmp(normalizeMethod, 'none') 
   matrix = yHist'*xHist;	% crossproduct
else   
   xt = xHist/length(alignList);
   yt = yHist/length(alignList);
   matrix = (yt'*xt)*length(alignList);	% crossproduct
end   
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
currentMatrix = 'PSTProd';
if verbose
  t = toc;
  fprintf('PSTprod elapsed time: %3.2f s\n',t);
end
   
   
case('calcStationarity');   
sn = normalizeMethod;
JPST('setNormalizeMethod',0);
JPST('calcRaw');
   
% save raw values for calculations
rawxHist = xHist;
rawyHist = yHist;
   
%calc some stuff we will need to know
trials = length(alignList);	% number of trials
bins = (stopTick - startTick)/binWidth; %number of bins

%init histos
xErrors = zeros(1,bins);
yErrors = zeros(1,bins);
xHist = zeros(1,bins);
yHist = zeros(1,bins);
scorr = 0;
pstxvar = 0;
pstyvar = 0;

%bins spikes then add to matrix
for t = 1:trials	% have to do a for loop
	%think about making this a c function
   start = alignList(t) + startTick -1;  % for this trial
   stop = alignList(t) + stopTick;
   
   x= zeros(1,bins);
   y= zeros(1,bins);
   
   binList = ceil((xList(find((xList > start) & (xList < stop))) - start)/binWidth);
   temp = binList(~diff(binList));
   x(temp) = 1;		% bins which have a diff of not zero, ie spike
   xErrors = xErrors + x;  % build xErrorHisto
   x= zeros(1,bins);
   x(binList) = 1;
   if ~isempty(temp)
   for i = 1:length(temp)
      x(temp(i)) = x(temp(i)) +1;			% add in binomial errors so histogram will be right
   end   
   end
   xHist = xHist + x;   	% build xHisto
   
   binList = ceil((yList(find((yList > start) & (yList < stop))) - start)/binWidth);
   temp = binList(~diff(binList)); % list of repeat bins
   y(temp) = 1;		% bins which have a diff of not zero, ie spike
   yErrors = yErrors + y;  % build yErrorHisto
   y= zeros(1,bins);
   y(binList) = 1;
   if ~isempty(temp)
   for i = 1:length(temp)
      y(temp(i)) = y(temp(i)) +1;			% add in binomial errors so histogram will be right
   end   
   end   
   yHist = yHist + y;   	% build yHisto
   
   scorr = scorr + sum(y)*sum(x);
   pstxvar = pstxvar + (x - (rawxHist*sum(x)/sum(rawxHist))).*(x - (rawxHist*sum(x)/sum(rawxHist)));
   pstyvar = pstyvar + (y - (rawyHist*sum(y)/sum(rawyHist))).*(y - (rawyHist*sum(y)/sum(rawyHist)));
end

%xHist  =  xHist/length(alignList);		% normalize by trials
%yHist  =  yHist/length(alignList);		% normalize by trials
%rawxHist  =  rawxHist/length(alignList);		% normalize by trials
%rawyHist  =  rawyHist/length(alignList);		% normalize by trials
%xSqrd  =  xSqrd/length(alignList);
%ySqrd  =  ySqrd/length(alignList);
%matrix = matrix/length(alignList);		% normalize by trials

temp = sqrt(pstyvar'*pstxvar);
%temp(find(~temp)) = 1;
temp(find(~temp)) = mean(mean(temp));

matrix = (matrix - ((rawyHist'*rawxHist)*(scorr/(sum(rawxHist)*sum(rawyHist)))) ) ./ temp;
if xID == yID	% if autocorrelating
   for i = 1:length(matrix)
      matrix(i,i) = 0;	% zero main diagonal
   end
end   

%JPST('normalizeMatrix',normalizeMethod);
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
%fprintf('calc nonstationarity corrected not implemented\n');
currentMatrix = 'Stationarity';
JPST('setNormalizeMethod',sn);


   
case('calcNormalized')
%if ~rawValid | ~strcmp(currentMatrix, 'corrected')
%   JPST('calcCorrected');
%end   
trialN = 0;
if verbose
   tic
   fprintf('calculating normalized JPST\n');
end

%if strcmp(normalizeMethod,'none')
%   JPST('setNormalizeMethod','trials');
%   trialN = 1;
%end
NS = length(alignList);
JPST('calcCorrected');
if strcmp(normalizeMethod, 'none')
   vnc = (ySqrd - yHist.*yHist/NS)'*(xSqrd - xHist.*xHist/NS); % variances
else
   vnc = (ySqrd - yHist.*yHist)'*(xSqrd - xHist.*xHist); % variances
end    
   vnc(find(~vnc)) = mean(mean(vnc)); %to avoid dividing 0/
   sd = sqrt(vnc);
   matrix = matrix./sd;	% normalized: corrected/sd

currentMatrix = 'normalized';
if xID == yID	% if autocorrelating
   for i = 1:length(matrix)
      matrix(i,i) = 0;	% zero main diagonal
   end
end   
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
if verbose
  t = toc;
  fprintf('normalized elapsed time: %3.2f s\n',t);
end
   
   
case('calcSignificance')
if verbose
   tic
   fprintf('calculating significance matrix\n');
end
if strcmp(normalizeMethod,'trials')
   JPST('setNormalizeMethod',0);
   JPST('calcRaw');
elseif ~rawValid | ~strcmp(currentMatrix, 'raw')
   JPST('calcRaw');
end   
surpjp;
matrix(find(matrix>=4.605)) = 4.605;
matrix(find(matrix<=-2.996)) = -2.996;
% come in with raw matrix without normalization
%fprintf('calc significance not implemented\n');
currentMatrix = 'significance';
%JPST('setNormalizeMethod','trials');
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
if verbose
  t = toc;
  fprintf('significance elapsed time: %3.2f s\n',t);
end
   
   
case('calcBinErr')
if ~rawValid		% if x, y, align, binWidth, start or stop times have changed
   JPST('calcRaw');
end   
if verbose
   tic
   fprintf('calculating binomial errors matirix\n');
end
matrix = yErrors'*xErrors;	% build matrix
yHist = yErrors;
xHist = xErrors;
JPST('calcXCorrHist');
JPST('calcScoopHist');
JPST('calcDCMatrix');
rawValid = 0;		% need to update the xHist and yHist now
currentMatrix = 'binomialerrors';
if verbose
  t = toc;
  fprintf('binomial errors elapsed time: %3.2f s\n',t);
end
   

case('calcXCorrHist')
xcorrHist = [];   
is = floor(length(matrix)/2);
for i = -is+1:is-1
   xcorrHist(i+is,:) = [i,(sum(diag(matrix,i)))/(length(matrix)-abs(i))];
end
if verbose
  fprintf('calculated cross correlation histogram\n');
end


case('calcScoopHist')
scoopHist = zeros(1,length(diag(matrix,0)));
for sinx = scoop(1):scoop(2)   
   snx = abs(sinx);
   d =diag(matrix,sinx)';
   if isempty(d)
      scoopHist = [];
      return
   end
   scoopHist(snx+1:end) = scoopHist(snx+1:end)+d;
   scoopHist = JPSTSmooth(scoopHist,SCsm);
end   
if verbose
  fprintf('calculated scoop histogram\n');
end


case('calcDCMatrix');
inx = 1;
m = max(abs(DCvals(1:2)));
DCMatrix = [];
m = length(matrix)-m-1;
for sinx = DCvals(2):-1:DCvals(1)  
   d = diag(matrix,sinx);
   if isempty(d)
      DCMatrix = [];
      return
   end
   DCMatrix(inx,:) = JPSTSmooth(d(end-m:end)',DCvals(3));
%   DCMatrix(inx,:) = d(end-m:end)';
   inx = inx+1;
end   
%for sinx = 1:size(DCMatrix,2);
%   DCMatrix(:,sinx) = JPSTSmooth(DCMatrix(:,sinx),1);
%end
%size(DCMatrix)
%load c1.mat
%DCMatrix = conv2(DCMatrix, c);   
%DCMatrix(end-floor(length(c)/2)+1:end,:) = [];
%DCMatrix(:,end-floor(length(c)/2)+1:end) = [];
%DCMatrix(1:floor(length(c)/2),:) = [];
%DCMatrix(:,1:floor(length(c)/2)) = [];
%size(DCMatrix)

if verbose
  fprintf('calculated delayed correlation histogram\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% get value routines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

case('getXHist')
out = xHist;
   
case('getYHist')
out = yHist;
   
case('getMatrix')
out = matrix;
   
case('getXCorrHist')
out = xcorrHist;
   
case('getScoopHist')
out = scoopHist;

case('getDCMatrix'); %delayed coinicidence vs time plot
out = DCMatrix;   

case('display');
fprintf('current matrix: %s\n',currentMatrix);   
if rawValid	%if something has been run successfully
   if exist('data')
      JPSTGUI('batchDisplay',data);   
   else
      JPSTGUI('batchDisplay');   
   end   
   out = 1;
else
   out = 0;
end   
      

end   % end of main switch statement

else  %else nothing passed so run in interactive mode
      dJPST;
      
end   