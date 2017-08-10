function outTrace=benConv(inTrace, kernel)
% this does convolution and forces outTrace size to match inTrace
if isColumnVector(inTrace)
    inTrace=inTrace';
    flipped=1;
else
    flipped=0;
end
if isColumnVector(kernel)
    kernel=kernel';
end
prePad=kernel;
prePad(:)=inTrace(1);
postPad=[kernel kernel];
postPad(:)=inTrace(len(inTrace));
outTrace=conv([prePad inTrace postPad],kernel);
offset=round(1.5*len(kernel));
outTrace=outTrace(offset:offset+len(inTrace)-1);
% now clean up garbage still left at ends
offset=round(0.5*len(kernel));
offsetArray=1:offset;
outTrace(offsetArray)=outTrace(offset+1);
offsetArray=offsetArray+(len(outTrace)-offset);
outTrace(offsetArray)=outTrace(len(outTrace)-offset);
if flipped
  outTrace=outTrace';
end
end

function length=len(inString)
length=size(inString,2);
end
function answer=isColumnVector(inVector)
% this returns 1 if vector is a columns and 0 if rows
bb=size(inVector);
answer=(bb(1)>bb(2));
end