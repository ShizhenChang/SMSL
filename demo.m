%This is a demo for SMSL_ACD
close all; clear all;clc 
addpath(genpath('./'));
load('D1F12H1_D1F12H2.mat');%load dataset
p = size(D1F12H1);
X1 = reshape(D1F12H1, p(1) * p(2), p(3)); X1 = X1';
X2 = reshape(D1F12H2, p(1) * p(2), p(3)); X2 = X2';
gt = reshape(GT, 1, p(1) * p(2));
%X1 = hyperNormalize(X1);%Normalize images
%X2 = hyperNormalize(X2);
X{1} = X1;
X{2} = X2;
n_H = 500;
H = meanjlt([X1,X2],n_H,10); %calculate sketched dictionary after 10 times' repeat

%setting parameters
lambda1 = 10;
lambda2 = 10;
lambda3 = 10;
par.lambda1 = lambda1;
par.lambda2 = lambda2;
par.lambda3 = lambda3;
disp(['lambda1 = ' num2str(lambda1 ) ',lambd2 = ' num2str(lambda2) ...
    ',lambda3 = ' num2str(lambda3)]);
clear X1 X2 lambda1 lambda2 lambda3

%stopping criteria
opt.mu = 1e-5;
opt.muMax = 1e5;
opt.rho = 1.1;
opt.maxIter = 60;
opt.Thre_Err = 1e-5;
[C, D, E] = SMSL_ACD(X, H, par, opt);

%Calculate the roc curve
str = ['SMSL_D1F12H1_D1F12H2',num2str(par.lambda1),'_',num2str(par.lambda2),'_',num2str(par.lambda3)];
r_SMSL = sqrt(sum((H * D{1}-H * D{2}).^2, 1)) + sqrt(sum((E{1} - E{2}).^2, 1));
Roc=roc_i(r_SMSL,gt,849);