function importConstants(varargin)
for v = 1:length(varargin)
    switch lower(varargin{v})
        case 'tableau10'
            k = [0.1216    0.4314    0.7059;
                 1.0000    0.4980    0.0549;
                 0.1725    0.6275    0.1725;
                 0.8392    0.1529    0.1569;
                 0.5804    0.4039    0.7412;
                 0.5490    0.3373    0.2941;
                 0.8902    0.4667    0.7608;
                 0.4980    0.4980    0.4980;
                 0.7373    0.7412    0.1333;
                 0.0902    0.7451    0.8118];
        otherwise
            error('Unrecognized constant %s', varargin{v})
    end
    assignin('base', lower(varargin{v}), k);
end
end