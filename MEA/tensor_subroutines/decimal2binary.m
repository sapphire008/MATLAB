function bin = decimal2binary(num, nbits)
if nargin<2
    nbits = max([1,ceil(log2(max(num(:))+1))]);
else
    nbits = max([1,ceil(log2(max(num(:))+1)), nbits]);
end
bin = zeros(numel(num),nbits);
powofnbits = 2.^((0:nbits)-1);
% loop over all the input numbers
for n = 1:numel(num)
    p=nbits+1;
    dec = num(n);
    while dec>0
        if dec>=powofnbits(p)
            dec = dec - powofnbits(p);
            bin(n,nbits-p+2) = 1;
        end
        p = p - 1;
    end
end
end