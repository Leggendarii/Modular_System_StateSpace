function results = powerflow(param)

%% Base quantities

Zb = param.Z_base;

%% RL sections

R1 = param.R_vsc2/Zb;
X1 = param.omega_b*param.L_vsc2/Zb;

R2 = param.R_grid/Zb;
X2 = param.omega_b*param.L_grid/Zb;

%% PI section

Rpi = param.R_line/Zb;
Xpi = param.omega_b*param.L_line/Zb;

% MATPOWER branch charging is total B
Bpi = param.omega_b*param.C_line*Zb;

%% PI shunt halves

B1 = Bpi/2;
B2 = Bpi/2;

%% Power produced
Pset = param.Pset;
Qset = param.Qset;
Type = param.Type;

%% MATPOWER case

AC1.version = '2';
AC1.baseMVA = param.P_base/1e6;

%% Power produced
Pgen = Pset*param.P_base/1e6;
Qgen = Qset*param.P_base/1e6;

%% Bus data
if strcmpi(Type,'PV')

    AC1.bus = [
    %bus type Pd Qd Gs Bs area Vm Va baseKV zone Vmax Vmin
     1    2    0  0  0   0    1  1  0  param.V_base/1e3  1  1.1  0.9;
     2    1    0  0  0   B1   1  1  0  param.V_base/1e3  1  1.1  0.9;
     3    1    0  0  0   B2   1  1  0  param.V_base/1e3  1  1.1  0.9;
     4    3    0  0  0   0    1  1  0  param.V_base/1e3  1  1.1  0.9;
    ];

    AC1.gen = [
    %bus Pg   Qg Qmax Qmin Vg  mBase status Pmax Pmin
     1   Pgen 0  100 -100 1.0 AC1.baseMVA 1 Pgen 0;
     4   0    0  999 -999 1.0 AC1.baseMVA 1 999 -999;
    ];

elseif strcmpi(Type,'PQ')

    AC1.bus = [
    %bus type Pd      Qd      Gs Bs area Vm Va baseKV zone Vmax Vmin
     1    1   -Pgen   -Qgen   0  0   1  1  0  param.V_base/1e3 1 1.1 0.9;
     2    1    0       0      0  B1  1  1  0  param.V_base/1e3 1 1.1 0.9;
     3    1    0       0      0  B2  1  1  0  param.V_base/1e3 1 1.1 0.9;
     4    3    0       0      0  0   1  1  0  param.V_base/1e3 1 1.1 0.9;
    ];

    AC1.gen = [
    % solo slack
     4   0   0  999 -999 1.0 AC1.baseMVA 1 999 -999;
    ];

else
    error('Type must be ''PV'' or ''PQ''');
end

%% Branch data

AC1.branch = [
%fbus tbus  R      X      B      rateA rateB rateC ratio angle status angmin angmax
 1    2    R1     X1      0      250   250   250   0     0      1    -360   360;
 2    3    Rpi    Xpi    Bpi     250   250   250   0     0      1    -360   360;
 3    4    R2     X2      0      250   250   250   0     0      1    -360   360;
];

%% Dummy costs

if strcmpi(Type,'PV')

    AC1.gencost = [
        2 0 0 3 0 0 0;
        2 0 0 3 0 0 0;
    ];

else

    AC1.gencost = [
        2 0 0 3 0 0 0;
    ];

end

%% Power flow

results = runpf(AC1);

end