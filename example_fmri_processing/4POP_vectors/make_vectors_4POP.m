function [output] = make_vectors_4POP(data)

%first identify which cells are which
for n = 1:length(data),
    if(strcmp(data{n}.header,'Block')),             Block = n;  end;
    %if(strcmp(data{n}.header,'Trial')),             trial = n;  end;
    if(strcmp(data{n}.header,'ProbeOnsetTime')),    sonset = n; end;
    if(strcmp(data{n}.header,'CueOnsetTime')),      conset = n; end;
    if(strcmp(data{n}.header,'Color')),             cue = n;    end;
    if(strcmp(data{n}.header,'ProbeACC')),          acc = n;    end;
    if(strcmp(data{n}.header,'ProbeRT')),           rt = n;     end;
    if(strcmp(data{n}.header,'CueDelayOnsetTime')), donset = n; end;
    if(strcmp(data{n}.header,'ProbeFinishTime')),   pdonset = n; end;
    if(strcmp(data{n}.header,'FixationOnsetTime')), fonset = n; end;
    
end

% find the number of blocks
numblk = unique(data{Block}.col);
num = length(numblk);

% place holding
GreenCue_NoResp = cell(1,num);
GreenCueDelay_NoResp = cell(1,num);
GreenProbe_NoResp = cell(1,num);
GreenProbeDelay_NoResp = cell(1,num);
GreenFixation_NoResp = cell(1,num);
RedCue_NoResp = cell(1,num);
RedCueDelay_NoResp = cell(1,num);
RedProbe_NoResp = cell(1,num);
RedProbeDelay_NoResp = cell(1,num);
RedFixation_NoResp = cell(1,num);
Cue_NoResp = cell(1,num);

GreenCue_Correct = cell(1,num);
GreenCueDelay_Correct = cell(1,num);
GreenProbe_Correct = cell(1,num);
GreenProbeDelay_Correct = cell(1,num);
GreenFixation_Correct = cell(1,num);
RedCue_Correct = cell(1,num);
RedCueDelay_Correct = cell(1,num);
RedProbe_Correct = cell(1,num);
RedProbeDelay_Correct = cell(1,num);
RedFixation_Correct = cell(1,num);

GreenCue_Error = cell(1,num);
GreenCueDelay_Error = cell(1,num);
GreenProbe_Error = cell(1,num);
GreenProbeDelay_Error = cell(1,num);
GreenFixation_Error = cell(1,num);
RedCue_Error = cell(1,num);
RedCueDelay_Error = cell(1,num);
RedProbe_Error = cell(1,num);
RedProbeDelay_Error = cell(1,num);
RedFixation_Error = cell(1,num);

% produce the vectors for each Block
for n = 1:length(numblk)
    idx = find(data{Block}.col == numblk(n)); % find the index for current Block
    %normalize the OnsetTime
    CueOnset = (double(data{conset}.col(idx)) - double(data{conset}.col(idx(1))))/1000;
    CueDelayOnset = CueOnset + 4.5;
    ProbeOnset = (double(data{sonset}.col(idx)) - double(data{conset}.col(idx(1))))/1000;
    ProbeDelayOnset = (double(data{pdonset}.col(idx)) - double(data{conset}.col(idx(1))))/1000;
    FixationOnset = (double(data{fonset}.col(idx)) - double(data{conset}.col(idx(1))))/1000;
    Cue = data{cue}.col(idx); % extract Cues for Block
    Acc = data{acc}.col(idx); % Acc for Block  
    RT  = data{rt}.col(idx);  % RT for Block
    % separating into conditions
    red_idx = find(strcmpi(Cue,'red')); % index Red Cues
    green_idx = find(strcmpi(Cue,'green'));  % index Green Cues
    %%%%%% make no response vectors %%%%%%%%%
    rt_idx = find(~RT); % find index of RT == zero

    gnr_idx = intersect(green_idx, rt_idx);
    GreenCue_NoResp{n} = CueOnset(gnr_idx); % Green Cue No Response Onset Time
    GreenCueDelay_NoResp{n} = CueDelayOnset(gnr_idx); % Green Cue Delay No Response Onset Time
    GreenProbe_NoResp{n} = ProbeOnset(gnr_idx); % Green Cue Probe No Response Onset Time
    GreenProbeDelay_NoResp{n} = ProbeDelayOnset(gnr_idx);% Green Probe Delay No Response Onset Time
    GreenFixation_NoResp{n} = FixationOnset(gnr_idx);% Green Cue Fixation No Response Onset Time
        
    rnr_idx = intersect(red_idx, rt_idx);
    RedCue_NoResp{n} = CueOnset(rnr_idx); % Red Cue No Response Onset Time
    RedCueDelay_NoResp{n} = CueDelayOnset(rnr_idx); % Red Cue Delay No Response Onset Time
    RedProbe_NoResp{n} = ProbeOnset(rnr_idx); % Red Cue Probe No Response Onset Time
    RedProbeDelay_NoResp{n} = ProbeDelayOnset(rnr_idx);% Red Probe Delay No Response Onset Time
    RedFixation_NoResp{n} = FixationOnset(rnr_idx);% Red Cue Fixation No Response Onset Time
    
    %Cue_NoResp{n} = CueOnset(union(rnr_idx,gnr_idx));  %%%%%%%%%%%%%%%%  combining the Green and Red No_Resp

    %%%%%%%%%%%%%%% make Correct vectors RT > 150 and ACC == 1  %%%%%%%%%%%%%%%%%%%% 
    rt_idx = intersect(find(RT>150),find(Acc)); % find index of RT > 150 and ACC == 1
    
    gcorrect_idx = intersect(green_idx, rt_idx);
    GreenCue_Correct{n} = CueOnset(gcorrect_idx); % Green Cue Correct Onset Time
    GreenCueDelay_Correct{n} = CueDelayOnset(gcorrect_idx); % Green Cue Delay Correct Onset Time
    GreenProbe_Correct{n} = ProbeOnset(gcorrect_idx); % Green Cue Probe Correct Onset Time
    GreenProbeDelay_Correct{n} = ProbeDelayOnset(gcorrect_idx); % Green Cue Probe Delay Correct Onset Time
    GreenFixation_Correct{n} = FixationOnset(gcorrect_idx);% Green Cue Fixation Correct Onset Time
    
    rcorrect_idx = intersect(red_idx, rt_idx);
    RedCue_Correct{n} = CueOnset(rcorrect_idx); % Red Cue Correct Onset Time
    RedCueDelay_Correct{n} = CueDelayOnset(rcorrect_idx); % Red Cue Delay Correct Onset Time
    RedProbe_Correct{n} = ProbeOnset(rcorrect_idx); % Red Cue Probe Correct Onset Time
    RedProbeDelay_Correct{n} = ProbeDelayOnset(rcorrect_idx); % Red Cue Probe Delay Correct Onset Time
    RedFixation_Correct{n} = FixationOnset(rcorrect_idx);% Red Cue Fixation Correct Onset Time
    
    clear rt_idx gnr_idx rnr_idx gcorrect_idx rcorrect_idx ;
    %%%%%% all other times are errors %%%%%%%%%%%%%%%%%%%%%%%
    err_idx = find((RT>0) & (~Acc));%responded, but wrong
    
    gerr_idx = intersect(err_idx,green_idx);
    GreenCue_Error{n} = CueOnset(gerr_idx); % Green Cue Error Onset Time
    GreenCueDelay_Error{n} = CueDelayOnset(gerr_idx); % Green Cue Delay Error Onset Time
    GreenProbe_Error{n} = ProbeOnset(gerr_idx); % Green Cue Probe Error Onset Time
    GreenProbeDelay_Error{n} = ProbeDelayOnset(gerr_idx); % Green Cue Probe Delay Error Onset Time
    GreenFixation_Error{n} = FixationOnset(gerr_idx);% Green Cue Fixation Error Onset Time
    
    rerr_idx = intersect(err_idx,green_idx);
    RedCue_Error{n} = CueOnset(rerr_idx); % Red Cue Error Onset Time
    RedCueDelay_Error{n} = CueDelayOnset(rerr_idx); % Green Cue Delay Error Onset Time
    RedProbe_Error{n} = ProbeOnset(rerr_idx); % Green Cue Probe Error Onset Time
    RedProbeDelay_Error{n} = ProbeDelayOnset(rerr_idx); % Red Cue Probe Delay Error Onset Time
    RedFixation_Error{n} = FixationOnset(rerr_idx);% Red Cue Fixation Error Onset Time
    
    
%     CueError{n} = setxor(CueOnset,union(union(GreenCue_NoResp{n},RedCue_NoResp{n}),union(GreenCue_Correct{n},RedCue_Correct{n})));
%                   %%%%%CueError = anything that is NOT (Correct or No_Resp)
%     GreenProbe_Correct{n} = GreenCue_Correct{n} + 8; %%%%%% '+8' refers to the 8seconds delay between Cue and Probe
%     RedProbe_Correct{n} = RedCue_Correct{n} + 8;
%     %GreenDelay_Correct{n} = GreenCue_Correct{n} + 4; %%%%%% '+4' referes to the 4seconds delay between CUe and Delay
%     RedDelay_Correct{n} = RedCue_Correct{n} + 4;
%     %GreenProbe_NoResp{n} = GreenCue_NoResp{n} + 8;
%     %RedProbe_NoResp{n} = RedCue_NoResp{n} + 8;
%     Probe_NoResp{n} = Cue_NoResp{n} + 8;   %%%%%%%%%%line added for Probe_NoResp to replace GreenProbe/RedProbe_NoResp
%     ProbeError{n} = CueError{n} + 8;
    
    
end

output = {...
   {{'RedCue'},RedCue_Correct}...
   {{'GreenCue'},GreenCue_Correct}...%{{'Cue_Error'},CueError}...%{{'Cue_NoResp'},Cue_NoResp}...
   {{'RedDelay'},RedCueDelay_Correct}...
   {{'GreenDelay'},GreenCueDelay_Correct}...
   {{'RedProbe'},RedProbe_Correct}...
   {{'GreenProbe'},GreenProbe_Correct}...%{{'Probe_Error'},ProbeError}... %{{'Probe_NoResp'},Probe_NoResp}...
   };

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
