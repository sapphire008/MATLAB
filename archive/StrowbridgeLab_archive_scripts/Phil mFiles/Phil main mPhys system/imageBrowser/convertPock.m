function outData = convertPock(inData)
% converts percentages from 0-100 to pockel cell voltage commands from 0-1V
% and also compensates from the nonlinear response of the pockel cell
if sum(inData < 0)
    error('Pockel cell drive can not be negative');
end
outData = (51.0088 - 19.83726 .* reallog((-1.09451 + inData / 100) ./ (-0.09641 - inData ./ 100))) ./ 100;