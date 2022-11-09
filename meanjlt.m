function H = meanjlt(X, n_H, n)
H = zeros(size(X,1),n_H);
for i = 1: n
    H = H + jlt(X,n_H);
end
H = H/n;