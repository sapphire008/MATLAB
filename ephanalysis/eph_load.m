function zData = eph_load(cellname, base_dir, fancy)
% Wrapper function for loadEPisodeFile, assuming the data structure we
% have.
% zData = eph_load(cellname, base_dir='~', fancy=false);
if nargin<2 || isempty(base_dir), base_dir = 'D:/Data/Traces';end
%if nargin<3 || isempty(infoOnly), infoOnly=false; end
if nargin<3 || isempty(fancy), fancy=false; end

if iscellstr(cellname) && length(cellname) == 2
    cellname = [cellname{1}, '.', cellname{2}];
end

cellpath = fullfile(base_dir, eph_cellpath(cellname));
zData = loadEpisodeFile(cellpath);
if fancy
    info = loadEpisodeFileFancy(cellpath, true);
    zData.protocol = orderfields(info);
end
end
