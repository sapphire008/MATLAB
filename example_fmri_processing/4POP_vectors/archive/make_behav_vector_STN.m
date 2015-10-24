function [output] = make_behav_vector_STN(data)

%first identify which cells are which
for n = 1:length(data),
    if(strcmp(data{n}.header,'Block')),             Block = n; end;
    if(strcmp(data{n}.header,'Trial')),             trial = n; end;
    if(strcmp(data{n}.header,'StimulusOnsetTime')), sonset = n; end;
    if(strcmp(data{n}.header,'CueOnsetTime')),      conset = n; end;
    if(strcmp(data{n}.header,'Cue1OnsetTime')),     conset = n; end;
    if(strcmp(data{n}.header,'Cue')),               cue = n; end;
    if(strcmp(data{n}.header,'StimulusACC')),       acc = n; end;
    if(strcmp(data{n}.header,'StimulusRT')),         rt = n; end;
    if(strcmp(data{n}.header,'DelayOnsetTime')),     donset = n; end;
end

% find the number of blocks
numblk = unique(data{Block}.col);

% produce the vectors for each Block
for n = 1:length(numblk),
    idx = find(data{Block}.col == numblk(n)); % find the index for current Block
    %normalize the CueOnsetTime
    CueOnset = (double(data{conset}.col(idx)) - double(data{conset}.col(idx(1))))/1000;  
    Cue = data{cue}.col(idx); % extract Cues for Block
    Acc = data{acc}.col(idx); % Acc for Block  
    RT  = data{rt}.col(idx);  % RT for Block
    red_idx = find(strcmp(Cue,'red')); % index Red Cues
    green_idx = find(strcmp(Cue,'green'));  % index Green Cues
    %%%%%% make no response vectors %%%%%%%%%
    rt_idx = find(~RT); % find index of RT == zero
    
    gnr_idx = intersect(green_idx, rt_idx);
    GreenCue_NoResp{n} = CueOnset(gnr_idx); % Green Cue No Response Onset Time
    
    rnr_idx = intersect(red_idx, rt_idx);
    RedCue_NoResp{n} = CueOnset(rnr_idx); % Red Cue No Response Onset Time
    
    Cue_NoResp{n} = CueOnset(union(rnr_idx,gnr_idx));  %%%%%%%%%%%%%%%%  combining the Green and Red No_Resp
    %Cue_NoResp{n} = union(RedCue_NoResp{n},GreenCue_NoResp{n})  %%  Will
    %be working too %% union will return sorted

    
    %%%%%%%%%%%%%%% make RT > 150 and ACC == 1  %%%%%%%%%%%%%%%%%%%%
    
    rt_idx = intersect(find(RT>150),find(Acc)); % find index of RT > 150 and ACC == 1
    
    gcorrect_idx = intersect(green_idx, rt_idx);
    GreenCue_Correct{n} = CueOnset(gcorrect_idx); % Green Cue No Response Onset Time
    
    rcorrect_idx = intersect(red_idx, rt_idx);
    RedCue_Correct{n} = CueOnset(rcorrect_idx); % Red Cue No Response Onset Time
    %%%%%% all other times are errors %%%%%%%%%%%%%%%%%%%%%%%
    
    CueError{n} = setxor(CueOnset,union(union(GreenCue_NoResp{n},RedCue_NoResp{n}),union(GreenCue_Correct{n},RedCue_Correct{n})));
                  %%%%%CueError = anything that is NOT (Correct or No_Resp)
    GreenProbe_Correct{n} = GreenCue_Correct{n} + 8; %%%%%% '+8' refers to the 8seconds delay between Cue and Probe
    RedProbe_Correct{n} = RedCue_Correct{n} + 8;
    %GreenDelay_Correct{n} = GreenCue_Correct{n} + 4; %%%%%% '+4' referes to the 4seconds delay between CUe and Delay
    RedDelay_Correct{n} = RedCue_Correct{n} + 4;
    %GreenProbe_NoResp{n} = GreenCue_NoResp{n} + 8;
    %RedProbe_NoResp{n} = RedCue_NoResp{n} + 8;
    Probe_NoResp{n} = Cue_NoResp{n} + 8;   %%%%%%%%%%line added for Probe_NoResp to replace GreenProbe/RedProbe_NoResp
    ProbeError{n} = CueError{n} + 8;
    
    
end

output = {{{'RedCue'},RedCue_Correct}...
   {{'GreenCue'},GreenCue_Correct}...
   %{{'Cue_Error'},CueError}...
   %{{'Cue_NoResp'},Cue_NoResp}...
   %{{'RedDelay'},RedDelay_Correct}...
   %{{'GreenDelay'},GreenDelay_Correct}...
   {{'RedProbe'},RedProbe_Correct}...
   {{'GreenProbe'},GreenProbe_Correct}...
   {{'Probe_Error'},ProbeError}...   
   {{'Probe_NoResp'},Probe_NoResp}};

%comments on the output
%    {{{'GreenCue_Correct'},GreenCue_Correct},...
%    {{'RedCue_Correct'},RedCue_Correct}...
%    %{{'GreenCue_NoResp'},GreenCue_NoResp}...
%    %{{'RedCue_NoResp'},RedCue_NoResp}...
%    {{'Cue_NoResp'},Cue_NoResp}...  %%%line added for Cue_NoResp to replace GreenCue/RedCue_NoResp
%    {{'CueError'},CueError}...
%    {{'GreenProbe_Correct'},GreenProbe_Correct},...
%    {{'RedProbe_Correct'},RedProbe_Correct}...
%    %{{'GreenProbe_NoResp'},GreenProbe_NoResp}...
%    %{{'RedProbe_NoResp'},RedProbe_NoResp}...
%    {{'Probe_NoResp'},Probe_NoResp}...   %%%line added for Probe_NoResp to replace GreenProbe/RedProbe_NoResp
%    %{{'ProbeError'},ProbeError}}
%
