function out = JPSTGUI(action,data);
global FileName;
global DataPath;
global DataOutputPath;
global gdf;
global alignIDRange;
global spikeIDRange;
global startstopRange;
global binRange;
global alignIDlist;
global spikeIDlist;
global binWidth;
global alignList; %list of align times
global ticksperms;	% gdf tics per millisecond for us currently = 25;
global startTick;	%offset from align tick to start calculation
global stopTick;	%offset from align tick to stop calculation
global xHist;		%x axis histogram
global yHist;		%y axis histogram
global xErrors;		%x axis errors histogram
global yErrors;		%y axis errors histogram
global xList;		% to determine if we have loaded anything yet
global yList;		% to determine if we have loaded anything yet
global matrix;		%current Matrix
global DCMatrix %delayed coinicidence vs time plot
global xcorrHist;	%crosscorrelation histogram
global scoopHist;	%scoop histogram
global scoop;		%diagonal start and stop bin of scoop (inclusive)
global DCvals;
global SCsm;        % Scoop histogram smoothing value
global normalizeMethod;
global PosMatrix;	%location on screen of various displays
global PosXHist;
global PosXRast;
global PosYHist;
global PosYRast;
global PosXCorScoop;
global PosSpecial;
global PosInfo;
global defaultCalculation;
global defaultDisplay;	% what to display
global currentMatrix;	% what is the current matrix
global updateList;			% what to do before displaying
global Version;
global oldAlign;
global oldXID;
global oldYID;
global xID;
global yID;
global alignID;
global rasterDisplayTrials;


switch(action)
case('openGDF')
   JPSTGUI('busy',1);
   source = [DataPath '*.gdf'];
   [Fn, DataP] = uigetfile({'*.gdf', 'GDF'; '*.mat', 'Matlab Event File'}, 'Open a gdf or mat file');
   if Fn
      JPST('setGDF',[DataP Fn]);
      if ~isempty(gdf)
        status(1) = JPSTGUI('setAlignMenuList',oldAlign);
        status(2) = JPSTGUI('setSpikeMenuList',[oldXID oldYID]);
        if sum(status) ~=2
			   if ~status(1)
			      fprintf('No valid align IDs found in gdf file!\n');
			   end   
			   if ~status(2)
			      fprintf('No valid spike IDs found in gdf file!\n');
            end
            JPSTDefaultOptions('open');
            uiwait;
            status(1) = JPSTGUI('setAlignMenuList',oldAlign); % check if valid ids have been entered
            status(2) = JPSTGUI('setSpikeMenuList',[oldXID oldYID]);
            if sum(status) ~=2
              return
            end
        end   
        DataPath = DataP;
        FileName = Fn;
        cf = findobj('tag','JPSTMain');
        if ~isempty(cf)
           set(cf,'Name',[Version '  ' DataP Fn]);
        end   
      else
         fprintf('Can not open %s\n',[DataP Fn]);
         out = 0;
         return;
      end   
   end   
   JPSTGUI('busy',0);
   out = 1;
   updateList = [1 1 1 1 1];	% reget everything
   
case('transferGDF')
   JPSTGUI('busy',1);
   
    JPST('transferGDF',data);
    if ~isempty(gdf)
    status(1) = JPSTGUI('setAlignMenuList',oldAlign);
    status(2) = JPSTGUI('setSpikeMenuList',[oldXID oldYID]);
    if sum(status) ~=2
           if ~status(1)
              fprintf('No valid align IDs found in gdf file!\n');
           end   
           if ~status(2)
              fprintf('No valid spike IDs found in gdf file!\n');
           end
        JPSTDefaultOptions('open');
        uiwait;
        status(1) = JPSTGUI('setAlignMenuList',oldAlign); % check if valid ids have been entered
        status(2) = JPSTGUI('setSpikeMenuList',[oldXID oldYID]);
        if sum(status) ~=2
          return
        end
    end   
    DataPath = '';
    FileName = 'Transfer';
    cf = findobj('tag','JPSTMain');
    if ~isempty(cf)
       set(cf,'Name',[Version '  Transfer']);
    end   
    end   

   JPSTGUI('busy',0);
   out = 1;
   updateList = [1 1 1 1 1];	% reget everything
   
   
case('busy')
   if data
      cf = findobj('tag','dispWhat');
      set(cf,'Enable','off');
      cf = findobj('tag','xIDlist');
      set(cf,'Enable','off');
      cf = findobj('tag','yIDlist');
      set(cf,'Enable','off');
      cf = findobj('tag','alignIDlist');
      set(cf,'Enable','off');
   else   
      cf = findobj('tag','dispWhat');
      set(cf,'Enable','on');
      cf = findobj('tag','xIDlist');
      set(cf,'Enable','on');
      cf = findobj('tag','yIDlist');
      set(cf,'Enable','on');
      cf = findobj('tag','alignIDlist');
      set(cf,'Enable','on');
   end   
   drawnow
   
   
case('setAlignMenuList')
   % if the alignIDlist menu exists, make its list
   cf = findobj('tag','alignIDlist');
   out = 0;
   if ~isempty(cf)
      set(cf,'Value',1);
      % make list of allcodes present which are align codes
      al = gdf(find(gdf(:,1) >= alignIDRange(1) & gdf(:,1) <= alignIDRange(2)),1);
      if isempty(al)
         return;
      end
      % only one of each type
      al = sort(al);
      il = [al(find(diff(al))); al(end)];
      alignIDlist = il;
      if ~isempty(il)
        strlist = [ ' ' int2str(il(1))]; 
	     for i = 2:length(il)
          strlist = [strlist ' | ' int2str(il(i))];
        end
     end  
     set(cf,'String',strlist);
     if exist('data')
        v = find(alignIDlist == data);
        if ~isempty(v)
          set(cf,'Value',v);
        end
     end
	end
	out = 1;   
   
   
case('setSpikeMenuList')
   % if the spikeIDlist menu exists, make its list
   cf = findobj('tag','xIDlist');
   out = 0;
   if ~isempty(cf)
      set(cf,'Value',1);
      % make list of all codes present which are spike codes
      al = gdf(find(gdf(:,1) >= spikeIDRange(1) & gdf(:,1) <= spikeIDRange(2)),1);
      if isempty(al)
         return;
      end
      % only one of each type
      al = sort(al);
      il = [al(find(diff(al))); al(end)];
      spikeIDlist = [il; al(end)];
      if ~isempty(il)
        strlist = [ ' ' int2str(il(1))]; 
	     for i = 2:length(il)
          strlist = [strlist ' | ' int2str(il(i))];
        end
      end  
		set(cf,'String',strlist);
      if exist('data')
         v = find(spikeIDlist == data(1));
         if ~isempty(v)
           set(cf,'Value',v);
         end
      end
      cf = findobj('tag','yIDlist');
      set(cf,'String',strlist);
      if exist('data')
         v = find(spikeIDlist == data(2));
         if ~isempty(v)
            set(cf,'Value',v);
         else
            set(cf,'Value',2);
         end   
      else
         set(cf,'Value',2);
      end   
	end
   out = 1;
   
case('setBinMenuList')
  cf = findobj('tag','binWidth');
  out = 0;
  if isempty(binRange)
     return
  end
  if ~isempty(cf)
     set(cf,'Value',1);
     strlist = [ ' ' num2str(binRange(1))]; 
     for i = 2:length(binRange)
       strlist = [strlist ' | ' num2str(binRange(i))];
     end
     set(cf,'String',strlist);
     set(cf,'Value',data);
  end
  out = 1;  
  
case('UpDateStart')   
   cf = findobj('tag','StartSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv*ticksperms < stopTick
         if sv >= startstopRange(1)
            startTick = sv*ticksperms;
            cf = findobj('tag','starttextval');
            set(cf,'String',int2str(sv));
         else
            sv = startstopRange(1);
            startTick = sv*ticksperms;
				set(cf,'Value',sv);
            cf = findobj('tag','starttextval');
            set(cf,'String',int2str(sv));
         end
         
      else  %trying to make start >= stop
         bw = findobj('tag','binWidth');
         v =get(bw,'Value');
         sv = sv-binRange(v);
         set(cf,'Value',sv);
         startTick = sv*ticksperms;
         cf = findobj('tag','starttextval');
         set(cf,'String',int2str(sv));
      end
   updateList(4) = 1;	% update start stop
   end   
   
   
case('UpDateStop')
   cf = findobj('tag','StopSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv*ticksperms > startTick
         if sv <= startstopRange(2)
            stopTick = sv*ticksperms;
            cf = findobj('tag','stoptextval');
            set(cf,'String',int2str(sv));
         else
            sv = startstopRange(2);
            stopTick = sv*ticksperms;
				set(cf,'Value',sv);
            cf = findobj('tag','stoptextval');
            set(cf,'String',int2str(sv));
         end
      else  %trying to make stop <= start
         bw = findobj('tag','binWidth');
         v =get(bw,'Value');
         sv = sv+binRange(v);
         set(cf,'Value',sv);
         stopTick = sv*ticksperms;
         cf = findobj('tag','stoptextval');
         set(cf,'String',int2str(sv));
      end
   updateList(4) = 1;	% update start stop
   end
   
   
case('setBinWidth')
   % read the bin width selected from the pull down menu
   % valid for bin values >= 0.01ms
   
   cf = findobj('tag','binWidth');
   if ~isempty(cf)
      v =get(cf,'Value');
      b = binRange(v);
      JPST('setBinWidth',b*ticksperms);
      quantum = b/((startstopRange(2) - startstopRange(1)));
      cf = findobj('tag','StartSlider');
      set(cf,'SliderStep',[quantum quantum*10]);
      v = get(cf,'Value');
      if mod(floor(v*100),floor(b*100))
         v = floor(v/b)*b;
         set(cf,'Value',v);
         JPSTGUI('UpDateStart');
      end   
      cf = findobj('tag','StopSlider');
      set(cf,'SliderStep',[quantum quantum*10]);
      v = get(cf,'Value');
      if mod(floor(v*100),floor(b*100))
         v = ceil(v/b)*b;
         set(cf,'Value',v);
         JPSTGUI('UpDateStop');
      end   
      updateList(5) = 1;	% update bin width
   
   end
   
case('UpDateScoopStart')   
   cf = findobj('tag','StartScoopSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv <= scoop(2)
         scoop(1) = sv;
         cf = findobj('tag','Scoopstarttextval');
         set(cf,'String',int2str(sv));
      else  %trying to make start > stop
         sv = scoop(2);
			set(cf,'Value',sv);
         scoop(1) = sv;
         cf = findobj('tag','Scoopstarttextval');
         set(cf,'String',int2str(sv));
      end
   end
   
case('UpDateScoopStop')   
   cf = findobj('tag','StopScoopSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv >= scoop(1)
         scoop(2) = sv;
         cf = findobj('tag','Scoopstoptextval');
         set(cf,'String',int2str(sv));
      else  %trying to make stop < start
         sv = scoop(1);
			set(cf,'Value',sv);
         scoop(2) = sv;
         cf = findobj('tag','Scoopstoptextval');
         set(cf,'String',int2str(sv));
      end
   end
   
   
case('UpDateDCStart')   
   cf = findobj('tag','StartDCSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv <= DCvals(2)
         DCvals(1) = sv;
         cf = findobj('tag','DCstarttextval');
         set(cf,'String',int2str(sv));
      else  %trying to make start > stop
         sv = DCvals(2);
			set(cf,'Value',sv);
         DCvals(1) = sv;
         cf = findobj('tag','DCstarttextval');
         set(cf,'String',int2str(sv));
      end
   end
   
case('UpDateDCStop')   
   cf = findobj('tag','StopDCSlider');
   if ~isempty(cf)
      sv =get(cf,'Value');
      if sv >= DCvals(1)
         DCvals(2) = sv;
         cf = findobj('tag','DCstoptextval');
         set(cf,'String',int2str(sv));
      else  %trying to make stop < start
         sv = DCvals(1);
			set(cf,'Value',sv);
         DCvals(2) = sv;
         cf = findobj('tag','DCstoptextval');
         set(cf,'String',int2str(sv));
      end
   end
   
case('setScoopSmoothing')
   % read the bin width selected from the pull down menu
   % valid for bin values >= 0.01ms
   
   cf = findobj('tag','ScoopSmoothing');
   if ~isempty(cf)
      v = get(cf,'Value')-1;
      if (v == 3)
         v = 4;
      end   
      SCsm = v;
   end
        
case('setDCSmoothing')
   % read the bin width selected from the pull down menu
   % valid for bin values >= 0.01ms
   
   cf = findobj('tag','DCSmoothing');
   if ~isempty(cf)
      v = get(cf,'Value')-1;
      if (v == 3)
         v = 4;
      end   
      DCvals(3) = v;
   end
   
case('setRasterDisplayTrials');
   rasterDisplayTrials = data(1);
   

   
case('applySettings')
  JPSTGUI('busy',1);
  cf = findobj('tag','xIDlist');
  if ~isempty(cf)
     t = get(cf,'Value');
     nxID = spikeIDlist(t);
     if nxID ~= xID
        updateList(1) = 1;	% update xID
        xID = nxID;
     end
     cf = findobj('tag','yIDlist');
     t = get(cf,'Value');
     nyID = spikeIDlist(t);
     if nyID ~= yID
        updateList(2) = 1;	% update xID
        yID = nyID;
     end
     cf = findobj('tag','alignIDlist');
     t = get(cf,'Value');
     nalignID = alignIDlist(t);
     if nalignID ~= alignID
        updateList(3) = 1;	% update xID
        alignID = nalignID;
     end
     if sum(updateList)
       cf = findobj('tag','JPSTMain');
       if ~isempty(cf)   
        figure(cf);
        if ~isempty(PosMatrix)  
        subplot('position',PosMatrix);
        axis off
        text(length(matrix)/2, length(matrix)/2, 'working...', 'HorizontalAlignment','center','VerticalAlignment','middle',...
         'FontSize',12,'FontWeight','bold');
        drawnow
        end
   
       end
      end
     % if any of the below calls are made the raw 
     % matrix will be toggled to recalculate,
     % so only make calls if values actually change
     if sum(updateList)
       if updateList(1) JPST('setXID',nxID); end;
       if updateList(2) JPST('setYID',nyID); end;
       if updateList(3) JPST('setAlignID',nalignID); end;
       if updateList(4) JPST('setTimeRange',[startTick stopTick]); end;
       if updateList(5) JPST('setBinWidth', binWidth); end;
       JPST(defaultCalculation);
       % update any errors
       cf = findobj('tag','binomialerrors');
       t = ['binomial errors: ' int2str(sum(xErrors) + sum(yErrors))];
       set(cf,'Label',t);
     end  
     JPSTGUI('display');
  end
  JPSTGUI('busy',0);
   
case('displayRaw');
      defaultCalculation = 'calcRaw';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','raw');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show raw')
      JPSTGUI('quickdisp')
   
   
   
case('displayCorrected');
      defaultCalculation = 'calcCorrected';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','corrected');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show corrected')
      JPSTGUI('quickdisp')
      
      
case('displayPSTprod');
      defaultCalculation = 'calcPSTprod';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','PSTprod');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show PSTprod')
      JPSTGUI('quickdisp')
      
      
case('displayNormalized');
      defaultCalculation = 'calcNormalized';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','normalized');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show normalized');
      JPSTGUI('quickdisp')
      
case('displayStationarity');
      defaultCalculation = 'calcStationarity';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','stationarity');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show stationarity');
      JPSTGUI('quickdisp')
      
case('displaySignificance');
      defaultCalculation = 'calcSignificance';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','significance');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','show significance');
      JPSTGUI('quickdisp')
      
 case ('dispPctExcessCoincidences')
      defaultCalculation = 'calcPctExcessCoincidences';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','calcPctExcessCoincidences');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
	   set(cf,'String','% excess coincidence');
      JPSTGUI('quickdisp');
      
 case('displayBinomialErrors');
      defaultCalculation = 'calcBinErr';
      JPSTGUI('dispmenuoff')
      cf = findobj('tag','binomialerrors');
      set(cf,'checked','on');
      cf = findobj('tag','dispWhat');
      set(cf,'String','show binomial errors');
      JPSTGUI('quickdisp')
      
      
case('dispmenuoff')
      cf = findobj('tag','raw');
      set(cf,'checked','off');
      cf = findobj('tag','corrected');
      set(cf,'checked','off');
      cf = findobj('tag','PSTprod');
      set(cf,'checked','off');
      cf = findobj('tag','normalized');
      set(cf,'checked','off');
      cf = findobj('tag','stationarity');
      set(cf,'checked','off');
      cf = findobj('tag','significance');
      set(cf,'checked','off');
      cf = findobj('tag','binomialerrors');
      set(cf,'checked','off');
      cf = findobj('tag','calcPctExcessCoincidences');
      set(cf,'checked','off');
      
      
case('quickdisp')   
   JPSTGUI('busy',1);
   
       cf = findobj('tag','JPSTMain');
       if ~isempty(cf)   
        figure(cf);
        if ~isempty(PosMatrix)  
        subplot('position',PosMatrix);
        axis off
        text(length(matrix)/2, length(matrix)/2, 'working...', 'HorizontalAlignment','center','VerticalAlignment','middle',...
         'FontSize',12,'FontWeight','bold');
        drawnow
        end
   
       end
   
   if isempty(xList)
      updateList = [1 1 1 1 1];
      JPSTGUI('applySettings');
   else
      if ~sum(updateList)
         JPST(defaultCalculation);
      end   
      JPSTGUI('applySettings');
      JPSTGUI('busy',1);
  		JPSTGUI('plotMatrix')
  		JPSTGUI('plotXHist')
  		JPSTGUI('plotYHist')
      JPSTGUI('plotRast')
   end
   JPSTGUI('busy',0);
   
   
case('defaultDisplay')
%subplot('position',[.0 .33 .125 .33]);	% yhist plot if raster
%subplot('position',[.125 .33 .125 .33]);	% yhist plot or raster plot
%subplot('position',[.25 .0 .25 .165]);	% xhist plot if raster
%subplot('position',[.25 .165 .25 .165]);	% xhist plot or raster plot
%subplot('position',[.25 .33 .25 .33]);	% matrix
%subplot('position',[.5 .33 .5 .66]);	% x corr and scoop plot
PosMatrix = [.25 .33 .25 .33];
PosXCorScoop = [.55 .33 .5 .66];
PosSpecial = [.05 .73 .4 .23];      
PosInfo	=	[.51 .05 .45 .27];

PosYRast = [];
PosXRast = [];
PosXHist = [.25 .168 .25 .159];
PosYHist = [.128 .33 .119 .33];
   
case('dcDisplay')
PosMatrix = [];
PosXRast = [];
PosXHist = [];
%PosXHist = [0.05 .05 .7 .30];
PosYRast = [];
PosYHist = [];
PosXCorScoop = [];
PosSpecial = [.05 .4 .7 .3];      
%PosSpecial = [.05 .6 .7 .3];      
PosInfo	=	[];
   
case('rasterDisplay');
PosMatrix = [.25 .33 .25 .33];
PosXRast = [.25 .168 .25 .159];
PosXHist = [.25 .003 .25 .159];
PosYRast = [.126 .33 .119 .33];
PosYHist = [.003 .33 .119 .33];
PosXCorScoop = [.55 .33 .5 .66];
PosSpecial = [.05 .73 .4 .23];      
PosInfo	=	[.51 .05 .45 .27];


case('batchDisplay')		% display while running from command line
								% in this case everything must already be calculated   
  cf =figure('Color',[0.8 0.8 0.8], ...
   'Name',FileName, ...
   'MenuBar','none', ...
   'NumberTitle','off', ...
   'Tag','JPSTMain',...
   'Position',[55 98 560 420]);

  %load('dm.mat');
  %colormap(dm);
  colormap(jet);
%  JPSTGUI('defaultDisplay')
  JPSTGUI('rasterDisplay')
  JPSTGUI('plotXHist')
  JPSTGUI('plotYHist')
  JPSTGUI('plotRast')
  JPSTGUI('plotMatrix')
  JPSTGUI('plotDCMatrix')
  JPSTGUI('plotXCorandScoop')
%  JPSTGUI('plotInfo');
  if exist('data')
  if strcmp(data,'print')
     drawnow   
     orient landscape
     print
     close(cf);
  end
  if strcmp(data,'save')
     drawnow
     % dosomething
     close(cf);
  end   
  end
   
case('display')
cf = findobj('tag','JPSTMain');
if isempty(cf)   
   return
end   
figure(cf);
if sum(updateList)
  JPSTGUI('plotMatrix')
  JPSTGUI('plotDCMatrix');
  JPSTGUI('plotXHist')
  JPSTGUI('plotYHist')
  JPSTGUI('plotRast')  
  JPSTGUI('plotXCorandScoop')
  %JPSTGUI('plotRast')
  updateList = [0 0 0 0 0];
else  % only draw things which can change without updating the raw matrix
  %recalc in case they have changed
  JPST('calcScoopHist');
  JPST('calcDCMatrix');
  JPSTGUI('plotDCMatrix')
  JPSTGUI('plotXCorandScoop')
end
JPSTGUI('plotInfo')

%JPSTGUI('plotXCorandScoop')



case('plotXHist')
%fc = [0.7 0.7 0.7];
fc = [0 0.5 0];
% plot xhisto
if ~isempty(PosXHist)
subplot('position',PosXHist);	% xhist plot or raster plot
if isempty(xHist) cla; axis off; return; end;   
xvals = 1:size(matrix,1);
txvals = sort([xvals+0.5, xvals-0.5]);
txvals = [txvals(1), txvals, txvals(end), txvals(1)];
thisto = zeros(1,2*length(xHist));
thisto(1:2:end) = xHist;
thisto(2:2:end) = xHist;
thisto = [0, thisto, 0, 0];
fill(txvals,-thisto,fc,'EdgeColor',fc);
axis tight
axis off
end

case('plotYHist')
%fc = [0.7 0.7 0.7];
fc = [0 0.5 0];
% plot yHisto
if ~isempty(PosYHist)
subplot('position',PosYHist);	% yhist plot or raster plot
if isempty(yHist) cla; axis off; return; end;   
xvals = 1:size(matrix,1);
txvals = sort([xvals+0.5, xvals-0.5]);
txvals = [txvals(1), txvals, txvals(end), txvals(1)];
thisto = zeros(1,2*length(yHist));
thisto(1:2:end) = yHist;
thisto(2:2:end) = yHist;
thisto = [0, thisto, 0, 0];
fill(-thisto, txvals,fc,'EdgeColor',fc);
axis tight
axis off
end

case('HighlightSpikes');
if ~isempty(data)   
  if ~isempty(PosXRast) & ~isempty(PosYRast)
     subplot('position',PosXRast)
     hold on
     for i = 1:size(data,1)
        xpos = data(i,1) - data(i,3);
        ypos = -data(i,4);
        plot(xpos,ypos,'.r');
     end
     hold off
     subplot('position',PosYRast)
     hold on
     for i = 1:size(data,1)
        ypos = data(i,2) - data(i,3);
        xpos = -data(i,4);
        plot(xpos,ypos,'.r');
     end
     hold off
  end
end


case('plotRast')
fc = [0.7 0.7 0.7];
noRasterTrials = rasterDisplayTrials;   
if isempty(xHist) cla; axis off; return; end;   
if ~isempty(PosXRast) & ~isempty(PosYRast)
   if noRasterTrials > length(alignList)
      noRasterTrials = length(alignList);
   end   
   xRaster = [];
   yRaster = [];
   for t = 1:noRasterTrials	% have to do a for loop
     start = alignList(t) + startTick -1;  % for this trial
     stop = alignList(t) + stopTick;
     xtRaster = xList(find( (xList > start) & (xList < stop) ) ) - start;
     xtRaster(:,2) = -t;
     
     xRaster =  [xRaster; xtRaster];   	% build xHisto
     ytRaster = yList(find( (yList > start) & (yList < stop) ) ) - start;
     ytRaster(:,2) = -t;
     yRaster =  [yRaster; ytRaster];   	% build xHisto
   end
   xRaster(find(~xRaster),:)= [];  % needed for some strange reason
   yRaster(find(~xRaster),:) = [];  % needed for some strange reason!????
   subplot('position',PosXRast);	% x raster plot
  % plot(xRaster(:,1),xRaster(:,2), '.k','color',fc,'MarkerSize',2)
   plot(xRaster(:,1),xRaster(:,2), '.k','MarkerSize',2)
   axis manual
   axis([1  stopTick-startTick -noRasterTrials-1 1]);
   axis off
   
   subplot('position',PosYRast);	% y raster plot
   %plot(yRaster(:,2),yRaster(:,1), '.k','color',fc,'MarkerSize',2)
   plot(yRaster(:,2),yRaster(:,1), '.k','MarkerSize',2)
   axis manual
   axis([-noRasterTrials-1 1 1  stopTick-startTick]);
   axis off

end
   

case('plotXCorandScoop')
%fc = [0.7 0.7 0.7];
fc = [0 0.5 0];
if ~isempty(PosXCorScoop)
subplot('position',PosXCorScoop);	% x corr plot
if isempty(scoopHist)
   cla
   axis([0 2 0 2]);
   text(1, 1, 'requested range invalid', 'HorizontalAlignment','center','VerticalAlignment','middle');
   axis off
else

%display the xcorr histo
xvals = xcorrHist(:,1)';
txvals = sort([xvals+0.5, xvals-0.5]);
txvals = -[txvals(1), txvals, txvals(end), txvals(1)];
thisto = zeros(1,2*length(xcorrHist(:,2)));
thisto(1:2:end-1) = xcorrHist(:,2);
thisto(2:2:end) = xcorrHist(:,2);
thisto = [0, thisto, 0, 0];
%while max(thisto)*length(alignList)/length(txvals) > 0.1*1.414		% scaling plot
m = max(abs(xcorrHist(:,2)));
   thisto =(thisto*0.1414)/m;
%   thisto =thisto/2;
%end
%while max(thisto)*length(alignList)/length(txvals) < 0.049*1.414		% scaling plot
%   thisto =thisto*2;
%end
offset = length(yHist) + 0.1*length(yHist);
h =plot(thisto*length(txvals)+offset*1.414,txvals,'k','color',fc);
rotate(h,[0, 90],45,[0 0 0]);
xtemp = get(h,'xdata');
ytemp = get(h,'ydata');
fill(xtemp,ytemp,fc,'EdgeColor',fc);
%pause(.1);
drawnow
%axis([1 length(txvals) 1 length(txvals)]);
axis manual
hold on
%display the scoop histo
xvals = 1:length(scoopHist);
txvals = sort([xvals+0.5, xvals-0.5]);
txvals = [txvals(1), txvals, txvals(end), txvals(1)];
thisto = zeros(1,2*length(scoopHist));
thisto(1:2:end-1) = scoopHist;
thisto(2:2:end) = scoopHist;
thisto = [0, thisto, 0, 0];
%if max(thisto)*length(alignList)/length(txvals) > 0.1*1.414		% scaling plot
m = max(scoopHist);
if m < abs(min(scoopHist))
   m = min(scoopHist);
end   
   thisto =(thisto*0.1414)/m;
%end
%if max(thisto)*length(alignList)/length(txvals) < 0.049*1.414		% scaling plot
%   thisto =thisto*;
%end
h =plot(txvals*1.414,thisto*length(txvals),'k','color',fc);
rotate(h,[0, 90],45,[0 0 0]);
xtemp = get(h,'xdata');
ytemp = get(h,'ydata');
fill(xtemp,ytemp,fc,'EdgeColor',fc);
%pause(.1);
drawnow
%axis manual
axis([0 length(txvals)-3 0 length(txvals)-3]);
axis off
hold off

end
end %if ~isempty(PosXCorScoop)


case('plotMatrix')
drawnow
if ~isempty(PosMatrix)
subplot('position',PosMatrix);	% matrix
axis([ 1 50 1 50]);
axis off

em = colormap;
scale = size(em,1);
%m = max(max(abs(matrix)));
me = sort(abs(matrix(:)));
m = me( floor(length(me)*0.95) );
if ~m m = 1; end;			% if all zeros
dMatrix = ceil((m+matrix)*scale/(2*m));	% colors will map from -max to max
dMatrix(find(dMatrix < 1)) = 1; 			% make any zeros a one
dMatrix(find(dMatrix  > scale)) = scale;	% make any above scale equal to scale

dMatrix(:,end+1) = 1;  % pcolor does not plot the last col or row
dMatrix(end+1,:) = scale;
drawnow
pcolor(dMatrix)
shading flat
%axis square
axis tight
axis off
JPSTGUI('OutlineScoop')
end %if ~isempty(PosMatrix)


case('plotDCMatrix')
if ~isempty(PosSpecial)
  subplot('position',PosSpecial);
  if isempty(DCMatrix)
     cla
     axis([0 2 0 2]);
     text(1, 1, 'requested range invalid', 'HorizontalAlignment','center','VerticalAlignment','middle');
     axis off
     return
  end
  %%%%%%%%%%%%%
  % old mapping
  %%%%%%%%%%%%%
%  em = colormap;
%  scale = size(em,1);
%%  m = max(max(abs(matrix)));
%  me = sort(abs(DCMatrix(:)));
%%  m = me( floor(length(me)*0.995) );
%  m = me( floor(length(me)*0.975) );
%%  m = me(end);
%  if ~m m = 1; end;			% if all zeros
%  dMatrix = ceil((m+DCMatrix)*scale/(2*m));	% colors will map from -max to max
%  dMatrix(find(dMatrix == 0)) = 1; 			% make any zeros a one
%  dMatrix(find(dMatrix  > scale)) = scale;	% make any above scale equal to scale
%  dMatrix(:,end+1) = 1;  % pcolor does not plot the last col or row
%  dMatrix(end+1,:) = scale;

  %%%%%%%%%%%%%%%%
  % new mapping
  %%%%%%%%%%%%%%%
  dMatrix = DCMatrix;
  m = max(max(dMatrix));
  mn = abs(min(min(dMatrix)));
  if mn > m
     m = mn;
  end   
  
  dMatrix(:,end+1) = -m;  % pcolor does not plot the last col or row
  dMatrix(end+1,:) = m;
  
  
  
  
  a = pcolor(dMatrix);
  colorbar
  set(a,'ButtonDownFcn','jRect start');
  shading flat
  if(DCvals(1) < 0 & DCvals(2) > 0)
     text(1,DCvals(2)+1.5,'0','HorizontalAlignment','right','VerticalAlignment','middle');
  end
  text(1,1.5,int2str(abs(DCvals(2))*binWidth/ticksperms),'HorizontalAlignment','right','VerticalAlignment','middle');
  text(1,size(dMatrix,1)-0.5,int2str(abs(DCvals(1))*binWidth/ticksperms),'HorizontalAlignment','right','VerticalAlignment','middle');
  if ~exist('data')
  text(size(dMatrix,2),1,int2str(stopTick/ticksperms),'HorizontalAlignment','center','VerticalAlignment','top');
  text(1,1,int2str((startTick+(max(abs(DCvals(1:2))))*binWidth)/ticksperms),'HorizontalAlignment','center','VerticalAlignment','top');
  if (startTick < 0 & stopTick > 0)
     text(1+abs(startTick/binWidth+(max(abs(DCvals(1:2))))),1,'0','HorizontalAlignment','center','VerticalAlignment','top');
  end   
  end
  if ~isempty(PosMatrix)
     axis tight
     axis off
     colorbar
 %    hold on
 %    a = rectangle;
 %    set(a,'position', [-1 -1 1 1], 'Tag','selectRect');
 %    hold off
  else   
    d = size(xHist,2) - size(dMatrix,2);
    l = size(dMatrix,2);
    h = size(dMatrix,1);
    axis([-d,l,0,h]);
    axis off
%    subplot('position',[.05 .85 .7 .15]);
%    plot(sum(DCMatrix));
    out = gca;    
%    axis off
  end
end
%JPSTGUI('plotFFTs');


case('OutlineScoop')
return   
hold on

% if crosses zero diagonal
if scoop(1) < 0 & scoop(2) > 0
   
else   
%if both positive
if scoop(1) >= 0
   xscp = scoop(2)+1:length(matrix)
   xscp = [sort([xscp xscp]) scoop(2)+1];
   yscp = scoop(2)-scoop(1)+1:length(matrix)-scoop(1);
   yscp = [1 sort([yscp yscp])];
   
   %xscp = [scoop(2)+1 scoop(2)+1 length(matrix) length(matrix) scoop(2)+1]
   %yscp = [1 scoop(2)-scoop(1)+1 length(matrix)-scoop(1) length(matrix)-scoop(2) 1]
   plot(xscp, yscp,'k');
end   
% if both negative
if scoop(2) <= 0
end
end
hold off
   
case('plotInfo')
if ~isempty(PosInfo)
   subplot('position',PosInfo);
   cla
   axis([0 12 0 12]);
   text(0,10,FileName);
   
%   if strcmp(normalizeMethod,'trials')
%    text(0,9,['xID: ' int2str(xID) '   spikes: ' int2str(round(sum(xHist)*length(alignList))) ...
%      			'   max: ' num2str(max(xHist)*1000/(binWidth/ticksperms)) 'Hz' ]);
%    text(0,8,['yID: ' int2str(yID) '   spikes: ' int2str(round(sum(yHist)*length(alignList))) ...
%      			'   max: ' num2str(max(yHist)*1000/(binWidth/ticksperms)) 'Hz' ]);

%if strcmp(normalizeMethod,'trials')
%    text(0,9,['xID: ' int2str(xID) '   spikes: ' int2str(round(sum(xHist))) ...
%      			'   max: ' num2str(max(xHist)*1000/(binWidth/ticksperms)) 'Hz' ]);
%    text(0,8,['yID: ' int2str(yID) '   spikes: ' int2str(round(sum(yHist))) ...
%      			'   max: ' num2str(max(yHist)*1000/(binWidth/ticksperms)) 'Hz' ]);
            
%   else
    text(0,9,['xID: ' int2str(xID) '   spikes: ' int2str(sum(xHist)) ...
      			'   max: ' num2str(max(xHist)*1000/((binWidth/ticksperms)*length(alignList))) 'Hz' ]);
    text(0,8,['yID: ' int2str(yID) '   spikes: ' int2str(sum(yHist)) ...
      			'   max: ' num2str(max(yHist)*1000/((binWidth/ticksperms)*length(alignList))) 'Hz' ]);
%   end
        
   
   text(0,7,['alignID: ' int2str(alignID) '   trials: ' int2str(length(alignList))] );
   text(0,6,['start: ' int2str(startTick/ticksperms)...
	            'ms   stop: ' num2str(stopTick/ticksperms)...
	            'ms   bin width: ' num2str(binWidth/ticksperms) 'ms']);
   switch(defaultCalculation)
   case('calcRaw')
     text(0,11,'raw JPST');
   case('calcCorrected')
     text(0,11,'corrected: raw JPST - PST cross product');
   case('calcPSTprod')
     text(0,11,'PST cross product');
   case('calcNormalized')
     text(0,11,'normalized: (raw JPST - PST cross product) / PSTSD cross product');
   case('calcSignificance')
     text(0,11,'significance: Palm et al 1988');
   case('calcBinErr')
     text(0,11,'binomial errors (>1 spike /bin /trial)');
   end
   
   if ~isempty(scoopHist)
   text(0,5,['scoop histogram: ' num2str(scoop(1)*binWidth/ticksperms) ' to ' num2str(scoop(2)*binWidth/ticksperms) 'ms'...
      '   max: ' num2str(max(scoopHist)) ...
      '   sum: ' num2str(sum(scoopHist))]     );
   end
   [maxc maxi] = max(xcorrHist);
   [minc mini] = min(xcorrHist);
   text(0,4,['cross correlation histogram:   max: ' num2str(maxc(2)) ...
      '   time: ' num2str(xcorrHist(maxi(2),1)*binWidth/ticksperms) 'ms']     );
   text(0,3,['       min: ' num2str(minc(2)) ...
      '   time: ' num2str(xcorrHist(mini(2),1)*binWidth/ticksperms) 'ms']     );
      
   if ~isempty(DCMatrix)
   text(0,2,['delayed correlation matrix: ' num2str(DCvals(1)*binWidth/ticksperms) ' to ' num2str(DCvals(2)*binWidth/ticksperms) 'ms']);
   text(0,1,['       max: ' num2str(max(max(DCMatrix))) ...
         '   sum: ' num2str(sum(sum(DCMatrix)))]     );
   end
   axis off
end   

case('plotFFTs');
   subplot('position',[.03 .053 .200 .110]);
   hold off
   JPSTFFT(xcorrHist(:,2));


case('DisplayWaves')
   if ~isempty(data)
      opened = InitGetCleanedWaves([DataPath FileName]);
      if isempty(opened) fprintf('\n'); return; end
      if ~isempty(find(opened == xID-20000)) | ~isempty(find(opened == yID-20000))

         h0 = figure('Color',[0.8 0.8 0.8], ...
         'Name','Selected Waves', ...
         'MenuBar','none', ...
         'Tag','selWaves');
         figure(h0);
      else
         gcwCloseFiles;
         return
      end
      if ~isempty(find(opened == xID-20000))
         subplot(1,2,1);
         hold on
         for i = 1:size(data,1)
            wavenumber = find(xList == data(i,1));
            waves = GetCleanedWaves(xID-20000, wavenumber);
				plot(waves);
         end
         title(['selected waves ID: ' int2str(xID)]);
      end
      
      if ~isempty(find(opened == yID-20000))
         subplot(1,2,2);
         hold on
         for i = 1:size(data,1)
            wavenumber = find(yList == data(i,2));
            waves = GetCleanedWaves(yID-20000, wavenumber);
				plot(waves);
         end
         title(['selected waves ID: ' int2str(yID)]);
      end
      gcwCloseFiles;
   end
   drawnow;
   fprintf('\n');
   
   
end	% main switch statement

   