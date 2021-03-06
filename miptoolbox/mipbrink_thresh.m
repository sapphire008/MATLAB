% This function returns the optimal threshold value using the
% two-dimensional Shannon entropy method. 
%
function newmaxgray = mipbrink_thresh(I, numgray);
[nrow, ncol] = size(I);
%
% Compute the averaged image I3 using a 3-by-3 sliding window
% This is accomplished using colfilt command. This command works
% for 'tif' image only. For other format images like jpeg, this
% the command colfilt has to be appropriaely modified. 
%
I3 = uint8(floor(colfilt(I,[3 3],'sliding','mean')));
%
% Compute the co-occurence matrix.
%
I  = double(I) + 1;
I3 = double(I3) + 1;
for k = 1:numgray
	for l = 1:numgray
		N(k,l) = 0;
	end
end
for i = 1:nrow
	for j = 1:ncol
		m = I(i,j);
		n = I3(i,j);
		N(m,n) = N(m,n) + 1;
	end
end
%
%  Computation of two-dimensional cumulative sum.
%  The cumsum command of the matlab has been used
%  appropriately for this purpose.
%
P = N/sum(sum(N));
Pcumsum = cumsum(cumsum(P),2);
for i = 1:numgray
	for j = 1:numgray
		if Pcumsum(i,j) == 0 | Pcumsum(i,j) == 1
			Pcumsum1(i,j) = 50000;
		else
			Pcumsum1(i,j) = Pcumsum(i,j);
		end
	end
end
%
%  Computation of AAa matrix.
%
Pcumsumal = Pcumsum1;
Pal = P;
PalcumsumA = cumsum(cumsum(Pal),2);
norPalcumsumA = PalcumsumA./Pcumsumal;
AAa = norPalcumsumA;
%
%  Computation of BBb matrix. 
%
Pnew = fliplr(flipud(Pal));
PalcumsumB = cumsum(cumsum(Pnew),2);
I4 = PalcumsumB;
I4(numgray, :) = [];
I4(:, numgray) = [];
I5 = fliplr(flipud(I4));
u = zeros(numgray-1, 1);
v = zeros(1, numgray);
I6 = [I5 u];
I7 = [I6; v];
norPalcumsumB = I7./abs((1 - Pcumsum1)); 
BBb = norPalcumsumB;
%
%   Replace the zero or undefined entries of matrices
%  AAa and BBb by one so that log(1) will be 0.
%
for i = 1:numgray
	for j = 1:numgray
		if BBb(i,j) < 0.000001
			BBb(i,j) = 1;
		end
		if AAa(i,j) < 0.000001
			AAa(i,j) = 1;
		end
	end
end
%
%  Compute object, background and total entropies 
%  in the sense of Shannon. Then compute the optimal 
%  threshold.
%
Entb = - AAa.*log(AAa);
Entw = - BBb.*log(BBb);
TotalEnt = Entb + Entw;
%
%  Maximize the total entropy to calculate the optimal
%  threshold value and then threshold the image in BW.
%
[maximum, rowindex] = max(TotalEnt);
[maximax, colindex] = max(maximum);
maxgray = rowindex(colindex);
newmaxgray = maxgray - 1;
newmaxgray;
