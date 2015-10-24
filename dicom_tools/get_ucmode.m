function slice_order = get_ucmode(fname)
% for Siemens Scanner only inspecting slice order
if ~exist('fname', 'var')
    fname = 'image_1.dcm';
end
if ~exist(fname, 'file')
    error('file %s does not exist', fname);
end
info = dicominfo(fname);
str = info.Private_0029_1020;
xstr = char(str');
n = findstr(xstr, 'sSliceArray.ucMode');
[t, r] = strtok(xstr(n:n+100), '=');
ucmode = strtok(strtok(r, '='));
switch(ucmode)
    case '0x1'
        slice_order = [fname ': Ascending'];%1:1:25
    case '0x2'
        slice_order = [fname ': Descending'];%25:-1:1
    case '0x4'
        slice_order =[fname ': Interleaved'];%[1:2:25,2:2:25]
    otherwise
        slice_order =[fname ': Order undetermined'];
end
%disp(slice_order);
        
end
