function result = JPSTBatchExample(FN);
%function result = JPSTBatchExample(FN);
% returns a 1 if successful 0 otherwise
% this example file runs the JPST in batch mode
% pass the complete path and file name of the gdf file you
% wish to analyze
% this example script will calculate the normalized JPST for
% 1ms bins from 50ms before to 50ms after the id code 1 for
% the spikepair 21-22
%
% edit this file to perform the analysis you desire
% edit the list of align IDs to those you wish to examine your file
% exit the list of spike IDs to those you want to examine
% all pairs of all spike IDs under all align IDs will be calculated
% the normalized matrix will be saved to disk
% and the display figure will be saved to disk.
% see the header comments of the file JPST.m for other commands
% you can also use non-grapical calls from JPSTGUI, but these
% have not been documented at the top of that file (yet!)

global gdf

% enter the desired IDs below
alignIDlist = [1];
spikeIDlist = [21 22];

% load the data file
JPST('setGDF',[FN]);

if ~isempty(gdf)	% if its loaded
  
  	 % set verbose mode off
     JPST('setVerbose',0);
     
     % set normalization to normalize by number of trials
     JPST('setNormalizeMethod',1);
     
     % set number of ticks per ms to 25
     JPST('setGDFTicks',25);
     
     % set the time range to be analyzed to +/- 50ms
     JPST('setTimeRange',[-50*25 50*25]);
     
     % set the bin width to 1ms (25 ticks) - number of ticks per ms
     JPST('setBinWidth',25);
     
     % set the scoop to +/- 10ms
     JPST('setScoop',[-10 10]);
     
     % set the delayed correlation display to +/- 10ms with smoothing of 1
     JPST('setDC',[-10 10 1]);
     
     % show up to the first 1000 trials (all of 'em)
     JPSTGUI('setRasterDisplayTrials',1000);
     
     % all set up so loop through the align IDs and spike IDs to get
     % all possible combos
     
     % for each align
     for a = 1:length(alignIDlist)
       JPST('setAlignID',alignIDlist(a));
       fprintf('Setting align to %d.\n',alignIDlist(a));
       
       % for each spike pair
       for sx = 1:length(spikeIDlist)-1
         JPST('setXID',spikeIDlist(sx));
         fprintf('Setting x ID to %d.\n',spikeIDlist(sx));
         
         for sy = sx+1:length(spikeIDlist)
           JPST('setYID',spikeIDlist(sy));
	         fprintf('Setting y ID to %d.\n',spikeIDlist(sy));
           
           % run the normalized calcuation
           % this actually runs the analysis
           JPST('calcNormalized');
           
           % get the JPSTmatrix
           m = JPST('getMatrix');
           
           % save the JPST matrix created by this calculation
           savename  = [FN 'a' int2str(alignIDlist(a)) 'x' int2str(spikeIDlist(sx)) 'y' int2str(spikeIDlist(sy))];
           fprintf('saving %s.mat\n',savename);
           save([savename '.mat'], 'm');
           
					 % show what we've just calculated           
           JPST('display'); 		% draw all the plots
           JPSTGUI('plotInfo');	% write the informative text on the figure 
           
           % save the figure we've just displayed
           fprintf('saving %s.fig\n',savename);
           saveas(gcf, [savename '.fig']);
			     close(gcf);
           
         end	% each y ID
       end	% each x ID
     end	% each align  
     
     % finished with this one
     fprintf('success\n');
     result = 1;
  else
     fprintf('Can not open or empty file: %s\n',FN);
     result = 0;
  end
