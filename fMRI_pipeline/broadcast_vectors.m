function [V_out,L_multiple]= broadcast_vectors(V,L)
% broadcast vector V to length L
L_multiple = mod(L,length(V))==0;
V_out = [V,V(1:min(L-length(V),length(V)))];
if length(V_out)<L
    [V_out,L_multiple] = broadcast_vectors(V_out,L);
end
end