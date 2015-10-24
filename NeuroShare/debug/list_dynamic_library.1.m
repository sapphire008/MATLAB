%% List dynamic library according to computer system
function dylib = list_dynamic_library()
switch computer
    case 'PCWIN'
        dylib = 'nsMCDLibrary.dll';
    case 'PCWIN64'
        dylib = 'nsMCDLibrary64.dll';
    case 'MACI'
        dylib = 'nsMCDLibrary.dylib';
    case 'MACI64'
        dylib = 'nsMCDLibrary.dylib';
    case 'GLNX86'
        dylib = 'nsMCDLibrary.so';
    case 'GLNX64'
        dylib = 'nsMCDLibrary.so';
end
end