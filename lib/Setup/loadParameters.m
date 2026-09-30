function P = loadParameters(csv_file_name)

parameter = readtable(csv_file_name);
getPar = @(name) parameter.Value(strcmp(parameter.Name,name));

%% Wind produced
P.Pset = 0.5;
P.Qset = 0;
P.Type = 'PV';

%% Grid values
P.Grid_SCR = getPar('SCR');
P.Grid_XR  = getPar('XR');

%% Nominal parameters
P.Ts      = getPar('Ts') * 1e-6;
P.f_base  = getPar('f_base');
P.V_base  = getPar('V_base') * 1e3;
P.P_base  = getPar('P_base') * 1e6;

%% Converter parameters
P.L_vsc   = getPar('L_vsc');
P.C_filt  = getPar('C_filt');
P.R_vsc   = getPar('R_vsc');
P.R_filt  = getPar('R_filt');
P.R_grid  = getPar('R_grid');
P.L_grid  = getPar('L_grid');

%% Control gains
P.kp_outer_V_pu = getPar('Kp_outer_V');
P.ki_outer_V_pu = getPar('Ki_outer_V');

P.kp_outer_P_pu = getPar('Kp_outer_P');
P.ki_outer_P_pu = getPar('Ki_outer_P');

P.kp_inner_d_pu = getPar('Kp_inner_d');
P.ki_inner_d_pu = getPar('Ki_inner_d');

P.kp_inner_q_pu = getPar('Kp_inner_q');
P.ki_inner_q_pu = getPar('Ki_inner_q');

P.kp_pll = getPar('Kp_pll');
P.ki_pll = getPar('Ki_pll');

P.T1 = getPar('T1');
P.T2 = getPar('T2');

%% DC parameters
[P.C_dc, P.V_dc] = DC_Cap(P.V_base, P.P_base);

P.t_charge = 0.5;
P.I_charge = P.C_dc * P.V_dc / P.t_charge;

%% Grid equivalent
[P.L_grid, P.R_grid] = thevenin( ...
    P.Grid_SCR,...
    P.Grid_XR,...
    P.V_base,...
    P.P_base,...
    P.f_base);

%% Additional values (pi section and extra filter VSC)
P.R_line = 2e-4; % Ohm
P.L_line = 8e-6; % H
P.C_line = 2e-9; % F

P.R_vsc2 = 0.55;
P.L_vsc2 = 0.0350141;

%% Base quantities
P.omega_b = 2*pi*P.f_base;
P.Z_base  = P.V_base^2/P.P_base;
P.L_base  = P.Z_base/P.omega_b;
P.C_base  = 1/(P.Z_base*P.omega_b);
end
