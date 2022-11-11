function [B] = jlt(X, n)
N = size(X, 2);
A = (1/sqrt(n)) * randn(N, n);
B = X * A;
