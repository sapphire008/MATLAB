function new_run_name=IEX_runNumMod(run_name,num_length_wanted)

run_name=lower(run_name);%convert all strings to lower case
if length(run_name)>10
    run_name=run_name(1:10);
end
region.LIST={'v1','mfg'};%two brain regions of interest
%Determine which brain region the run name contains
region.IND=~cellfun(@isempty,regexpi(run_name,region.LIST));
region.NAME=cell2mat(region.LIST(region.IND));
%remove the brain region and examine the rest of the string
run_name_withoutRegion=strrep(run_name,char(region.NAME),'');
%find index of trial number
trialNum.IND=regexp(run_name_withoutRegion,'\d');

if length(trialNum.IND)<num_length_wanted
    trialNum.newNum=[repmat('0',1,...
        num_length_wanted-length(trialNum.IND)) ...
        run_name_withoutRegion(trialNum.IND)] ;
else
    trialNum.newNum=run_name_withoutRegion(trialNum.IND);
end



new_run_name=['run' trialNum.newNum '_' region.NAME];
end