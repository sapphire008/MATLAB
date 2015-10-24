function output = make_vectors_RPOP(data)

%first identify which cells are which
for n = 1:length(data),
    if(strcmpi(data{n}.header,'Block')),              block = n; end;
    if(strcmpi(data{n}.header,'ProbeOnset')),         probeonset = n; end;
    %if(strcmpi(data{n}.header,'ProbeRT')),            probert = n; end;
    if(strcmpi(data{n}.header,'condition')),          type = n; end;
    if(strcmpi(data{n}.header,'ProbeAcc')),           probeacc = n; end;
    %if(strcmp(data{n}.header,'DelayOnset')),         delayonset; end;
    %if(strcmp(data{n}.header,'condition')),          type = n; end;
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
    
    % check for non numbers in ProbeACC
    tmp = find(isnan(ProbeAcc));
    %ProbeACC(isnan(ProbeACC)) = 0;
    if(tmp)
        ProbeAcc(tmp) = 0;
    end

    % no responses are marked as 1 
    %CueNR = data{cuert}.col(blkidx) < RTreject;  % CueOnset < RTreject 
    %ProbeNR = data{probert}.col(blkidx) < RTreject; %ProbeOnset < RTreject
    
    Green{n} = ProbeOnset(find( Type==1 & ProbeAcc  ))/1000; 
    Red{n} = ProbeOnset(find( Type==2 & ProbeAcc ))/1000;
    ExcludedProbes{n} = ProbeOnset(find(~ProbeAcc))/1000;    
    
end

% data is output in Name Data pairs to avoid confusion
output = {...
    {{'GreenProbe'},Green},...
    {{'RedProbe'},Red},...
    {{'ExcludedProbes'},ExcludedProbes},...
   };
end
        
