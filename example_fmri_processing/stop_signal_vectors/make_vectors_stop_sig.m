function output = make_vectors_stop_sig(data)

%RTreject = 200;
%first identify which cells are which
for n = 1:length(data),
    if(strcmpi(data{n}.header,'Block'))              block = n; end;
    if(strcmpi(data{n}.header,'Cue_Onset'))           probeonset = n; end;
    if(strcmpi(data{n}.header,'ReactionTime'))           probert = n; end;
    if(strcmpi(data{n}.header,'trial_type'))     type = n; end;
    if(strcmpi(data{n}.header,'Accuracy'))            probeacc = n; end;
    %if(strcmp(data{n}.header,'DelayOnset'))     delayonset; end;
    %if(strcmp(data{n}.header,'condition'))           type = n; end;
end

Blk = unique(data{block}.col);  % find which blocks

for n = 1:length(Blk),
    blkidx = find(data{block}.col == Blk(n));  % locate data this block

    % normalize the OnsetTimes for this block
    ProbeOnset = data{probeonset}.col(blkidx);
    ProbeOnset = double((ProbeOnset - ProbeOnset(1)));

    % extract data index vectors
    Type = data{type}.col(blkidx); % extract Cues for block
   % Cue = data{cue}.col(blkidx); % extract Cues for block
    %CueAcc = data{cueacc}.col(blkidx); % Acc for block
    ProbeAcc = data{probeacc}.col(blkidx);
    
    % check for nan numbers in ProbeACC
    tmp = find(isnan(ProbeAcc));
    if(tmp),
        ProbeAcc(tmp) = 0;
    end

    % no responses are marked as 1 
    %CueNR = data{cuert}.col(blkidx) < RTreject;  % CueOnset < RTreject 
    %ProbeNR = data{probert}.col(blkidx) < RTreject; %ProbeOnset < RTreject
    
    GO{n} = ProbeOnset(find( Type==0 & ProbeAcc  )); 
    GO_ERROR{n}=ProbeOnset(find(Type==0 & ~ProbeAcc));
    
    StopInhibit{n} = ProbeOnset(find( Type==1 & ProbeAcc ));
    StopRespond{n}=ProbeOnset(find(Type==1 & ~ProbeAcc));
    
    GO_ONLY{n} = ProbeOnset(find(Type==2 & ProbeAcc));
    GO_ONLY_ERROR{n} = ProbeOnset(find(Type==2 & ~ProbeAcc));
    
    
end

% data is output in Name Data pairs to avoid confusion
output = {{{'GO'},GO}...
   {{'GO_ERROR'},GO_ERROR}...
   {{'StopInhibit'},StopInhibit}...
   {{'StopRespond'},StopRespond}...
   {{'GO_ONLY'},GO_ONLY}...
   {{'GO_ONLY_ERROR'},GO_ONLY_ERROR}};
        
