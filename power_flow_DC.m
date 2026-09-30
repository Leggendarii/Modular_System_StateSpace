% clear all;
close all;
clc;

%% Libraries

addpath(genpath('../lib'));
addpath(genpath('data'));

%% Base values

Pbase = 100;

%% =====================================================================
%% AC1 POWER FLOW
%% =====================================================================

AC1.version = '2';
AC1.baseMVA = Pbase;

AC1.bus = [
%bus type Pd    Qd   Gs Bs area Vm Va baseKV zone Vmax Vmin
 1    1   -100 -20   0  0   1   1  0  220  1   1.1  0.9; % WF
 2    3      0   0   0  0   1   1  0  220  1   1.1  0.9; % MMC GFM
];

AC1.gen = [
% bus Pg  Qg Qmax Qmin Vg  mBase status Pmax Pmin Pc1 Pc2 ...
    2 100 0 300 -300 1.0 Pbase 1 110 0 ...
    0 0 0 0 0 0 0 0 0 0 0
];

AC1.branch = [
% f t  r     x    b    rateA rateB rateC ratio angle status angmin angmax
   1 2 0.01 0.10 0.02 250   250   250   0     0     1     -360   360
];

AC1.gencost = [
    2 0 0 3 0 0 0
];

results_AC1 = runpf(AC1);

%% Power transferred to DC side (pu)

P1 = abs(results_AC1.gen(1,2)/Pbase);

fprintf('\n')
fprintf('P1 from AC1 = %.6f pu\n',P1)

%% =====================================================================
%% DC POWER FLOW
%% =====================================================================

R1 = 0.02;
R2 = 0.03;
R3 = 0.025;

V2 = 1.0;

Pref = -0.8;
Kd   = 20;
Vref = 1.0;

x0 = [1;1;1];

fun = @(x) [

    P1/x(1) ...
    - (x(1)-x(3))/R1 ;

    (Pref-Kd*(x(2)-Vref))/x(2) ...
    - (x(2)-x(3))/R3 ;

    (x(3)-x(1))/R1 ...
    + (x(3)-V2)/R2 ...
    + (x(3)-x(2))/R3

];

options = optimoptions('fsolve',...
    'Display','iter',...
    'TolFun',1e-10,...
    'TolX',1e-10);

[x,fval] = fsolve(fun,x0,options);

%% DC voltages

V1 = x(1);
V3 = x(2);
V4 = x(3);

%% DC currents

I14 = (V1-V4)/R1;
I24 = (V2-V4)/R2;
I34 = (V3-V4)/R3;

%% DC powers

P1_calc = V1*I14;
P2_calc = V2*I24;
P3_calc = V3*I34;

fprintf('\n')
fprintf('=== DC POWER FLOW RESULTS ===\n\n')

fprintf('V1 = %.6f pu\n',V1)
fprintf('V2 = %.6f pu\n',V2)
fprintf('V3 = %.6f pu\n',V3)
fprintf('V4 = %.6f pu\n\n',V4)

fprintf('P1 = %.6f pu\n',P1_calc)
fprintf('P2 = %.6f pu\n',P2_calc)
fprintf('P3 = %.6f pu\n\n',P3_calc)

fprintf('Power balance = %.6e pu\n',...
    P1_calc + P2_calc + P3_calc)

%% =====================================================================
%% AC2 POWER FLOW
%% =====================================================================

AC2.version = '2';
AC2.baseMVA = Pbase;

AC2.bus = [
    1   3   0                0   0 0 1 1 0 400 1 1.1 0.9;
    2   1   (-P2_calc*Pbase) 20  0 0 1 1 0 400 1 1.1 0.9;
];

AC2.gen = [
    1 100 0 110 -110 1.0 Pbase 1 110 0 ...
    0 0 0 0 0 0 0 0 0 0 0
];

AC2.branch = [
    1 2 0.01 0.10 0.02 250 250 250 0 0 1 -360 360
];

AC2.gencost = [
    2 0 0 3 0 0 0
];

results_AC2 = runpf(AC2);

%% =====================================================================
%% AC3 POWER FLOW
%% =====================================================================

AC3.version = '2';
AC3.baseMVA = Pbase;

AC3.bus = [
    1   3   0                0   0 0 1 1 0 66 1 1.1 0.9;
    2   1   (-P3_calc*Pbase) 20  0 0 1 1 0 66 1 1.1 0.9;
];

AC3.gen = [
    1 100 0 300 -300 1.0 Pbase 1 300 0 ...
    0 0 0 0 0 0 0 0 0 0 0
];

AC3.branch = [
    1 2 0.01 0.10 0.02 250 250 250 0 0 1 -360 360
];

AC3.gencost = [
    2 0 0 3 0 0 0
];

results_AC3 = runpf(AC3);

%% =====================================================================
%% OPERATING POINTS
%% =====================================================================

iniz.AC1.V     = results_AC1.bus(:,8);
iniz.AC1.theta = deg2rad(results_AC1.bus(:,9));

iniz.AC2.V     = results_AC2.bus(:,8);
iniz.AC2.theta = deg2rad(results_AC2.bus(:,9));

iniz.AC3.V     = results_AC3.bus(:,8);
iniz.AC3.theta = deg2rad(results_AC3.bus(:,9));

iniz.DC.V1 = V1;
iniz.DC.V2 = V2;
iniz.DC.V3 = V3;
iniz.DC.V4 = V4;

iniz.DC.P1 = P1_calc;
iniz.DC.P2 = P2_calc;
iniz.DC.P3 = P3_calc;

disp('All power flows completed')
