function [A_relax, B_relax] = Relaxation(dt,T1,T2)

% T1 y T2 deben tener las mismas dimensiones    
if size(T1) ~= size(T2)
    return
end

if numel(T1) > 1
    A_relax = zeros([3 3 numel(T1)]);
    B_relax = zeros([3 1 numel(T1)]);
    for i=1:numel(T1)
        A_relax(:,:,i) = diag([exp(-dt/T2(i)), exp(-dt/T2(i)), exp(-dt/T1(i))]);
        B_relax(:,:,i) = [0; 0; 1-exp(-dt/T1(i))];
    end    
else
    A_relax = diag([exp(-dt/T2), exp(-dt/T2), exp(-dt/T1)]);
    B_relax = [0; 0; 1-exp(-dt/T1)];    
end
