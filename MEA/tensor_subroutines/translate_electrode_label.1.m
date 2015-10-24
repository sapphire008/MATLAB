function elec = translate_electrode_label(elec, MAP, channelnames)
% Translate between electrode label and coordinate system
% elec: list of electrodes, either coordinates (to be translated to labels)
%       or labels (to be translated into coordinates)
% MAP: list of coordinates
% channlenames: list of labels
%
% MAP must have the same number of rows as the number of elements in
% channelnames.
% Sanity check
if isempty(channelnames) || isempty(MAP)
    error('channelnames and/or MAP cannot be empty when doing label-coordinate translation');
end
% Translation
if ischar(elec) || iscellstr(elec)
    elec = cellstr(elec);
    elec = MAP(cellfun(@(x) find(ismember(channelnames,char(x)),1), elec),:);
elseif isnumeric(elec)
    [~,IA,~] = intersect(MAP,elec,'rows','stable');
    elec = channelnames(IA);
    if numel(elec)==1, elec = char(elec); end
else
    error('Invalid input');
end
end