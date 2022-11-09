function [C,D,E]=SMSL_ACD(X,H,par,opt)
if nargin < 3
    opt.mu = 1e-5;
    opt.muMax = 1e5;
    opt.rho = 1.1;
    opt.maxIter = 60;
    opt.Thre_Err = 1e-5;
end
views = size(X, 2);
%% parameter settings:
maxIter = opt.maxIter;
Thre_Err = opt.Thre_Err;
mu = opt.mu;
muMax = opt.muMax;
rho = opt.rho;


lambda1 = par.lambda1;
lambda2 = par.lambda2;
lambda3 = par.lambda3;

[L, N] = size(X{1});
H_N = size(H, 2);
%% Initialization
C = zeros(H_N, N);
J = zeros(H_N, N);
Y3 = zeros(H_N, N);
for v = 1: views
    D{v} = zeros(H_N, N);
    E{v} = zeros(L, N);
    W{v} = zeros(L, N);
    Y1{v} = zeros(L, N);
    Y2{v} = zeros(1, N);
    Y4{v} = zeros(L, N);
end

%% Start main loop
iter = 0;
one_vector = ones(H_N,1);
while iter < maxIter
    iter = iter + 1;
    %% update C
    
    temp1 = 2 * H' * H + 2 * one_vector * one_vector' + eye(H_N);
    temp2 = H'*(X{1}-H*D{1}-E{1}+Y1{1}/mu+X{2}-H*D{2}-E{2}+Y1{2}/mu)-one_vector*(one_vector'*D{1}+one_vector'*D{2}-2*ones(N,1)'+Y2{2}/mu+Y2{1}/mu)+(J-Y3/mu);
    C = inv(temp1) * temp2;
    clear temp1 temp2
    %J = J-diag(diag(J));
    
    %% update J
    temp = C + Y3/mu;
    [U,sigma,V] = svd(temp,'econ');
    sigma = diag(sigma);
    sigma = max(sigma - lambda1/mu,0) + min(sigma + lambda1/mu,0);
    J = U * diag(sigma) * V';
    
    %svp = length(find(sigma>lambda1/mu));
    %if svp>=1
    %    sigma = sigma(1:svp)-lambda1/mu;
    %else
    %    svp = 1;
    %    sigma = 0;
    %end
    %J = U(:,1:svp)*diag(sigma)*V(:,1:svp)';
    
    clear temp
    leq3 = C-J;
    Y3 = Y3 + mu*leq3;
    for v = 1:views
        if v == 1
            Dj = D{v+1};
        else
            Dj = D{v-1};
        end
        %% update D
        temp = lambda2 * abs(Dj);
        temp1 = lambda3 * eye(H_N) + mu * (H'*H+one_vector*one_vector');
        temp2 = mu*H'*(X{v}-H*C-E{v}+Y1{v}/mu)-mu*one_vector*(one_vector'*C-ones(N,1)'+Y2{v}/mu);
        D{v} = max(inv(temp1)*(temp2-temp),0);%+min(inv(temp1)*(temp2+temp),0);
        clear temp temp1 temp2 Dj
        %% update E
        E{v} = (X{v}-H*(C+D{v})+W{v}+(Y1{v}-Y4{v})/mu)/2;
        %E = max(0,temp - lambda/mu) + min(0,temp + lambda/mu);
        %% update W
        temp = E{v} + Y4{v}/mu;
        W{v} = solve_l1l2(temp, 1/mu);
        clear temp
        %E = max(0,temp - lambda/mu) + min(0,temp + lambda/mu);
        %% update Y1 Y2
        leq1 = X{v} - H * (C + D{v}) - E{v};
        leq2 = one_vector' * (C + D{v}) - ones(N, 1)';
        leq4 = E{v} - W{v};
        Y1{v} = Y1{v} + mu * leq1;
        Y2{v} = Y2{v} + mu * leq2;
        Y4{v} = Y4{v} + mu * leq4;
        stop(v)= max(max(max(max(abs(leq1))),max(max(abs(leq2)))),max(max(max(abs(leq3))),max(max(abs(leq4)))));
        clear leq1 leq2 leq4
    end
    clear leq3
    %% stop criteria
    stopC = max(stop);
    %if iter==1 || mod(iter,maxIter)==0 || stopC<Thre_Err
    disp(['iter = ' num2str(iter) ',mu = ' num2str(mu,'%2.1e') ...
        ',stopALM = ' num2str(stopC,'%2.3e')]);
    %end
    if stopC < Thre_Err
        break;
    else
        mu = min(muMax, mu * rho);
    end
end
end


function [E] = solve_l1l2(W, lambda)
n = size(W, 2);
E = W;
for i = 1: n
    E(:,i) = solve_l2(W(:,i), lambda);
end
end


function [x] = solve_l2(w,lambda)
% min lambda |x|_2 + |x-w|_2^2
nw = norm(w);
if nw > lambda
    x = (nw - lambda) * w/nw;
else
    x = zeros(length(w),1);
end
end
%} 