function match = sift_matcher(desc1, loc1, desc2, loc2)
% Match algorithm
% Based on match.c in SIFT package.
funnyno = 1E8;
m=1;


for i=1:size(desc1, 1)
  keypoint = desc1(i, :);
  keylist = desc2;
  
  distq1 = funnyno;
  distq2 = funnyno;
  
  for j=1:size(keylist, 1)
      dist = sum((keypoint - keylist(j, :)).^2);      
      if (dist < distq1)
          distq2 = distq1;
          distq1 = dist;
          minkey = j;
      elseif (dist < distq2)
          distq2 = dist;
      end
  end
  
  if (10 * 10 * distq1 < 6 * 6 * distq2)
      a = loc1(i, :);
      b = loc2(minkey, :);
      match(m, 1:2) = a(1:2);
      match(m, 3:4) = b(1:2);
      match(m, 5) = distq1;  
      m = m + 1;
  end
end